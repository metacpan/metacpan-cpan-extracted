package Test::Data::Riak;
{
  $Test::Data::Riak::VERSION = '2.0';
}

use strict;
use warnings;

use AnyEvent;
use Try::Tiny;
use Test::More;
use Digest::MD5 qw/md5_hex/;

use Sub::Exporter;

use Data::Riak;
use Data::Riak::HTTP;
use Data::Riak::Async;
use Data::Riak::Async::HTTP;
use namespace::clean;

sub _env_key {
    my ($key, $https) = @_;
    sprintf 'TEST_DATA_RIAK_HTTP%s_%s', ($https ? 'S' : ''), $key;
}

my %defaults = (
    host     => '127.0.0.1',
    port     => 8098,
    timeout  => 15,
    protocol => 'http',
);

for my $opt (keys %defaults) {
    my $code = sub {
        my ($https) = @_;
        my $env_key = _env_key uc $opt, $https;
        exists $ENV{$env_key} ? $ENV{$env_key} : $defaults{$opt}
    };

    no strict 'refs';
    *{"_default_${opt}"} = $code;
}

sub _build_transport_args {
    my ($args) = @_;

    my $protocol = exists $args->{protocol}
        ? $args->{protocol} : _default_protocol();

    my $https = $protocol eq 'https';

    return {
        protocol => $protocol,
        timeout  => (exists $args->{timeout}
                         ? $args->{timeout} : _default_timeout($https)),
        host     => (exists $args->{host}
                         ? $args->{host} : _default_host($https)),
        port     => (exists $args->{port}
                         ? $args->{port} : _default_port($https)),
    };
}

sub _build_transport {
    my $args = _build_transport_args(@_);
    ($args,
     Data::Riak->new({
         transport => Data::Riak::HTTP->new($args),
     }),
     Data::Riak::Async->new({
         transport => Data::Riak::Async::HTTP->new($args),
     }),
    );
}

sub _build_riak_transport_args {
    my ($class, $name, $args, $col) = @_;
    sub { $col->{transport_args} };
}

sub _build_riak_transport {
    my ($class, $name, $args, $col) = @_;
    sub { $col->{transport} };
}

sub _build_async_riak_transport {
    my ($class, $name, $args, $col) = @_;
    sub { $col->{async_transport} };
}

sub _build_skip_unless_riak {
    my ($class, $name, $args, $col) = @_;
    sub { skip_unless_riak($col->{transport}, @_) };
}

sub _build_skip_unless_leveldb_backend {
    my ($class, $name, $args, $col) = @_;
    sub { skip_unless_leveldb_backend($col->{transport}, @_) };
}

sub _build_remove_test_bucket {
    my ($class, $name, $args, $col) = @_;
    sub { remove_test_bucket($col->{async_transport}, @_) };
}

my $import = Sub::Exporter::build_exporter({
    exports    => [
        riak_transport_args         => \&_build_riak_transport_args,
        riak_transport              => \&_build_riak_transport,
        async_riak_transport        => \&_build_async_riak_transport,
        remove_test_bucket          => \&_build_remove_test_bucket,
        create_test_bucket_name     => sub { \&create_test_bucket_name },
        skip_unless_riak            => \&_build_skip_unless_riak,
        skip_unless_leveldb_backend => \&_build_skip_unless_leveldb_backend,
    ],
    groups     => {
        default => [qw(riak_transport async_riak_transport riak_transport_args
                       remove_test_bucket create_test_bucket_name
                       skip_unless_riak skip_unless_leveldb_backend)],
    },
    collectors => [qw(transport async_transport transport_args)],
    into_level => 1,
});

sub import {
    my ($class, @args) = @_;

    my ($transport_args, $transport, $async_transport) =
        _build_transport(ref $args[0] eq 'HASH' ? shift @args : {});

    $import->(
        $class,
        transport       => $transport,
        async_transport => $async_transport,
        transport_args  => $transport_args,
        @args ? @args : '-default',
    );
}

sub create_test_bucket_name {
	my $prefix = shift || 'data-riak-test';
    return sprintf '%s-%s-%s', $prefix, $$, md5_hex(scalar localtime);
}

sub skip_unless_riak {
    my ($transport) = @_;

    my $up = $transport->ping;
    unless($up) {
        plan skip_all => 'Riak did not answer, skipping tests'
    };
    return $up;
}

sub skip_unless_leveldb_backend {
    my ($transport) = @_;

    my $status = try {
        $transport->status;
    }
    catch {
        warn $_;
        plan skip_all => "Failed to identify the Riak node's storage backend";
    };

    plan skip_all => 'This test requires the leveldb Riak storage backend'
        unless $status->{storage_backend} eq 'riak_kv_eleveldb_backend';
    return;
}

sub remove_test_bucket {
    my $async_transport = shift;
    my @buckets = map {
        $_->isa('Data::Riak::Async::Bucket')
            ? $_ : Data::Riak::Async::Bucket->new({
                riak => $async_transport,
                name => $_->name,
            });
    } @_;

    my @cvs = map { AE::cv } @buckets;

    diag 'Removing test bucket so sleeping for a moment to allow riak to eventually be consistent ...'
        if $ENV{HARNESS_IS_VERBOSE};

    for my $i (0 .. $#buckets) {
        _remove_test_bucket_async(
            $buckets[$i],
            sub { $cvs[$i]->send },
            sub { $cvs[$i]->croak(@_) },
        );
    }

    for my $cv (@cvs) {
        try {
            $cv->recv;
        } catch {
            isa_ok $_, 'Data::Riak::Exception';
        };
    }
}


sub _remove_test_bucket_async {
    my ($bucket, $cb, $error_cb) = @_;

    my ($remove_all_and_wait, $t);
    $remove_all_and_wait = sub {
        $bucket->remove_all({
            error_cb => $error_cb,
            cb       => sub {
                $t = AE::timer 1, 0, sub {
                    $bucket->list_keys({
                        error_cb => $error_cb,
                        cb       => sub {
                            my ($keys) = @_;

                            if ($keys && @{ $keys }) {
                                $remove_all_and_wait->();
                                return;
                            }

                            $cb->();
                        },
                    });
                },
            },
        });
    };

    $remove_all_and_wait->();
}

__END__

=pod

=head1 NAME

Test::Data::Riak

=head1 VERSION

version 2.0

=head1 AUTHORS

=over 4

=item *

Andrew Nelson <anelson at cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
