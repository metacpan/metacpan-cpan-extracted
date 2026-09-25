#!/usr/bin/env perl

use strict;
use warnings;

use English qw(-no_match_vars);
use JSON qw(encode_json decode_json);
use Test::More;

use Amazon::S3::Lite::Lock;

########################################################################
# Test doubles
########################################################################
{
  package Local::Logger;

  sub new { return bless {}, shift }
  sub trace { return }
  sub debug { return }
  sub info  { return }
  sub warn  { return }
  sub error { return }
}

{
  package Local::S3;

  sub new {
    my ( $class, %args ) = @_;

    return bless {
      last_status => q{},
      logger      => Local::Logger->new,
      puts        => [],
      deletes     => [],
      put_queue   => $args{put_queue}  || [],
      head_queue  => $args{head_queue} || [],
      get_queue   => $args{get_queue}  || [],
    }, $class;
  }

  sub logger      { return $_[0]->{logger} }
  sub last_status { return $_[0]->{last_status} }
  sub puts        { return $_[0]->{puts} }
  sub deletes     { return $_[0]->{deletes} }

  sub put_object {
    my ( $self, $bucket, $key, $body, %options ) = @_;

    push @{ $self->{puts} }, {
      bucket  => $bucket,
      key     => $key,
      body    => $body,
      options => { %options },
    };

    my $response = shift @{ $self->{put_queue} };
    die "unexpected put_object call\n"
      if !$response;

    $self->{last_status} = $response->{status};

    die( $response->{error} // "put_object failed\n" )
      if $response->{status} !~ /\A2/;

    return $response->{etag};
  }

  sub head_object {
    my ( $self, $bucket, $key ) = @_;

    my $response = shift @{ $self->{head_queue} };
    die "unexpected head_object call\n"
      if !$response;

    $self->{last_status} = $response->{status};

    die( $response->{error} // "head_object failed\n" )
      if $response->{status} !~ /\A2/ && $response->{status} != 404;

    return
      if $response->{status} == 404;

    return $response->{meta};
  }

  sub get_object {
    my ( $self, $bucket, $key ) = @_;

    my $response = shift @{ $self->{get_queue} };
    die "unexpected get_object call\n"
      if !$response;

    $self->{last_status} = $response->{status};

    die( $response->{error} // "get_object failed\n" )
      if $response->{status} !~ /\A2/;

    return $response->{object};
  }

  sub delete_object {
    my ( $self, $bucket, $key, %options ) = @_;

    push @{ $self->{deletes} }, {
      bucket  => $bucket,
      key     => $key,
      options => { %options },
    };

    $self->{last_status} = 204;

    return 1;
  }
}

########################################################################
subtest 'acquire new lock returns guard and release is conditional' => sub {
########################################################################
  my $s3 = Local::S3->new(
    put_queue => [ { status => 200, etag => 'etag-create' } ],
  );

  my $lock = Amazon::S3::Lite::Lock->new(
    s3     => $s3,
    bucket => 'bucket',
    key    => 'locks/test.lock',
    ttl    => 120,
    owner  => 'test-owner',
  );

  my $guard = eval { return $lock->acquire };

  is $EVAL_ERROR, q{}, 'acquire does not throw';
  isa_ok $guard, 'Amazon::S3::Lite::Lock::Guard';

  is $s3->puts->[0]{options}{headers}{'If-None-Match'}, q{*}, 'create uses If-None-Match';

  my $data = decode_json( $s3->puts->[0]{body} );
  is $data->{owner}, 'test-owner', 'lock body records owner';
  ok $data->{expires} > time, 'lock body records future expiry';

  $guard->release;

  is scalar @{ $s3->deletes }, 1, 'release deletes lock once';
  is $s3->deletes->[0]{options}{headers}{'If-Match'}, '"etag-create"', 'release uses acquired etag';

  $guard->release;
  is scalar @{ $s3->deletes }, 1, 'second release is a no-op';
};

########################################################################
subtest 'fresh lock is not stolen' => sub {
########################################################################
  my $s3 = Local::S3->new(
    put_queue  => [ { status => 412, error => "precondition failed\n" } ],
    head_queue => [ { status => 200, meta => { etag => 'etag-current' } } ],
    get_queue  => [ { status => 200, object => { content => encode_json( { owner => 'other', expires => time + 60 } ) } } ],
  );

  my $lock = Amazon::S3::Lite::Lock->new(
    s3     => $s3,
    bucket => 'bucket',
    key    => 'locks/test.lock',
    wait   => 0,
  );

  my $guard = $lock->acquire;

  ok !defined $guard, 'fresh lock is not acquired';
  is scalar @{ $s3->puts }, 1, 'no steal PUT attempted';
};

########################################################################
subtest 'stale lock is stolen with If-Match' => sub {
########################################################################
  my $s3 = Local::S3->new(
    put_queue => [
      { status => 412, error => "precondition failed\n" },
      { status => 200, etag => 'etag-stolen' },
    ],
    head_queue => [ { status => 200, meta => { etag => 'etag-stale' } } ],
    get_queue  => [ { status => 200, object => { content => encode_json( { owner => 'dead-owner', expires => time - 60 } ) } } ],
  );

  my $lock = Amazon::S3::Lite::Lock->new(
    s3     => $s3,
    bucket => 'bucket',
    key    => 'locks/test.lock',
    owner  => 'new-owner',
    wait   => 0,
  );

  my $guard = $lock->acquire;

  isa_ok $guard, 'Amazon::S3::Lite::Lock::Guard';
  is scalar @{ $s3->puts }, 2, 'create followed by steal PUT';
  is $s3->puts->[1]{options}{headers}{'If-Match'}, '"etag-stale"', 'stale steal is conditional on observed etag';

  my $data = decode_json( $s3->puts->[1]{body} );
  is $data->{owner}, 'new-owner', 'stolen lock records new owner';

  $guard->release;
};

########################################################################
subtest 'lock vanishing during stale check is retried immediately' => sub {
########################################################################
  my $s3 = Local::S3->new(
    put_queue => [
      { status => 412, error => "precondition failed\n" },
      { status => 200, etag => 'etag-retry' },
    ],
    head_queue => [ { status => 404 } ],
  );

  my $lock = Amazon::S3::Lite::Lock->new(
    s3     => $s3,
    bucket => 'bucket',
    key    => 'locks/test.lock',
    wait   => 0,
  );

  my $guard = $lock->acquire;

  isa_ok $guard, 'Amazon::S3::Lite::Lock::Guard', 'vanished lock is retried even in no-wait mode';
  is scalar @{ $s3->puts }, 2, 'create retried after vanished lock';

  $guard->release if $guard;
};

done_testing;
