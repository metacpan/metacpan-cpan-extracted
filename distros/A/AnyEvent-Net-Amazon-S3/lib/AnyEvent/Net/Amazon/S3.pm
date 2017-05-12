package AnyEvent::Net::Amazon::S3;

# ABSTRACT: Use the Amazon S3 - Simple Storage Service
our $VERSION = 'v0.04.0.80'; # VERSION

use strict;
use warnings;

use Carp;
use Module::AnyEvent::Helper;
use AnyEvent;

sub list_bucket_all_async {
    my ( $self, $conf ) = @_;
    $conf ||= {};
    my $bucket = $conf->{bucket};
    croak 'must specify bucket' unless $bucket;

    my $cv = AE::cv;
    Module::AnyEvent::Helper::bind_scalar($cv, $self->list_bucket_async($conf), sub {

        my $response = shift->recv;
        return $response unless $response->{is_truncated};
        my $all = $response;

        my $iter; $iter = sub {
            my $next_marker = $response->{next_marker}
                || $response->{keys}->[-1]->{key};
            $conf->{marker} = $next_marker;
            $conf->{bucket} = $bucket;
            Module::AnyEvent::Helper::bind_scalar($cv, $self->list_bucket_async($conf), sub {
                $response       = shift->recv;
                push @{ $all->{keys} }, @{ $response->{keys} };
                if($response->{is_truncated}) {
                    $iter->();
                } else {
                    delete $all->{is_truncated};
                    delete $all->{next_marker};
                    return $all;
                }
            });
        };
        $iter->();
    });
    return $cv;
}

use Module::AnyEvent::Helper::Filter -as => __PACKAGE__, -target => 'Net::Amazon::S3',
        -transformer => 'Net::Amazon::S3',
        -remove_func => [qw(list_bucket_all)],
        -translate_func => [qw(buckets add_bucket delete_bucket list_bucket add_key get_key head_key delete_key _send_request _do_http _send_request_expect_nothing _send_request_expect_nothing_probed)],
        -replace_func => [qw(request)]
;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Net::Amazon::S3 - Use the Amazon S3 - Simple Storage Service

=head1 VERSION

version v0.04.0.80

=head1 SYNOPSIS

  # Can be used as same as Net::Amazon::S3
  use AnyEvent::Net::Amazon::S3;
  my $aws_access_key_id     = 'fill me in';
  my $aws_secret_access_key = 'fill me in too';

  my $s3 = AnyEvent::Net::Amazon::S3->new(
      {   aws_access_key_id     => $aws_access_key_id,
          aws_secret_access_key => $aws_secret_access_key,
          retry                 => 1,
      }
  );

  # a bucket is a globally-unique directory
  # list all buckets that i own
  my $response = $s3->buckets;
  foreach my $bucket ( @{ $response->{buckets} } ) {
      print "You have a bucket: " . $bucket->bucket . "\n";
  }

  # create a new bucket
  my $bucketname = 'acmes_photo_backups';
  my $bucket = $s3->add_bucket( { bucket => $bucketname } )
      or die $s3->err . ": " . $s3->errstr;

  # or use an existing bucket
  $bucket = $s3->bucket($bucketname);

  # store a file in the bucket
  $bucket->add_key_filename( '1.JPG', 'DSC06256.JPG',
      { content_type => 'image/jpeg', },
  ) or die $s3->err . ": " . $s3->errstr;

  # store a value in the bucket
  $bucket->add_key( 'reminder.txt', 'this is where my photos are backed up' )
      or die $s3->err . ": " . $s3->errstr;

  # list files in the bucket
  $response = $bucket->list_all
      or die $s3->err . ": " . $s3->errstr;
  foreach my $key ( @{ $response->{keys} } ) {
      my $key_name = $key->{key};
      my $key_size = $key->{size};
      print "Bucket contains key '$key_name' of size $key_size\n";
  }

  # fetch file from the bucket
  $response = $bucket->get_key_filename( '1.JPG', 'GET', 'backup.jpg' )
      or die $s3->err . ": " . $s3->errstr;

  # fetch value from the bucket
  $response = $bucket->get_key('reminder.txt')
      or die $s3->err . ": " . $s3->errstr;
  print "reminder.txt:\n";
  print "  content length: " . $response->{content_length} . "\n";
  print "    content type: " . $response->{content_type} . "\n";
  print "            etag: " . $response->{content_type} . "\n";
  print "         content: " . $response->{value} . "\n";

  # delete keys
  $bucket->delete_key('reminder.txt') or die $s3->err . ": " . $s3->errstr;
  $bucket->delete_key('1.JPG')        or die $s3->err . ": " . $s3->errstr;

  # and finally delete the bucket
  $bucket->delete_bucket or die $s3->err . ": " . $s3->errstr;

=head1 DESCRIPTION

This module provides the same interface as L<Net::Amazon::S3>.
In addition, some asynchronous methods returning AnyEvent condition variable are added.

Note: This is the legacy interface, please check out
L<AnyEvent::Net::Amazon::S3::Client> instead.

=for test_synopsis no warnings;

=head1 METHODS

All L<Net::Amazon::S3> methods are available.
In addition, there are the following asynchronous methods.
Arguments of the methods are identical as original but return value becomes L<AnyEvent> condition variable.
You can get actual return value by calling C<shift-E<gt>recv()>.

=over 4

=item buckets_async

=item add_bucket_async

=item delete_bucket_async

=item list_bucket_async

=item list_bucket_all_async

=item add_key_async

=item get_key_async

=item head_key_async

=item delete_key_async

=back

=for Pod::Coverage BUILD
bucket

=head1 TESTING

The following description is extracted from L<Net::Amazon::S3>.
They are all applicable to this module.

Testing S3 is a tricky thing. Amazon wants to charge you a bit of
money each time you use their service. And yes, testing counts as using.
Because of this, the application's test suite skips anything approaching
a real test unless you set these three environment variables:

=over 4

=item AMAZON_S3_EXPENSIVE_TESTS

Doesn't matter what you set it to. Just has to be set

=item AWS_ACCESS_KEY_ID

Your AWS access key

=item AWS_ACCESS_KEY_SECRET

Your AWS sekkr1t passkey. Be forewarned that setting this environment variable
on a shared system might leak that information to another user. Be careful.

=back

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent::Net::Amazon::S3::Bucket>

=item *

L<Net::Amazaon::S3> - Based on it as original.

=item *

L<Module::AnyEvent::Helper> - Used by this module. There are some description for needs of _async methods.

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
