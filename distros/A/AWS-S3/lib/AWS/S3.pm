
package AWS::S3;

use Moose;
use Carp 'confess';
use LWP::UserAgent::Determined;
use HTTP::Response;
use HTTP::Request::Common;
use IO::Socket::INET;
use Class::Load 'load_class';

use AWS::S3::ResponseParser;
use AWS::S3::Owner;
use AWS::S3::Bucket;

our $VERSION = '0.15';

has [qw/access_key_id secret_access_key/] => ( is => 'ro', isa => 'Str' );

has 'secure' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => 0
);

has 'endpoint' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 's3.amazonaws.com' },
);

has 'ua' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    default => sub { LWP::UserAgent::Determined->new }
);

sub request {
    my ( $s, $type, %args ) = @_;

    my $class = "AWS::S3::Request::$type";
    load_class( $class );
    return $class->new( %args, s3 => $s, type => $type );
}    # end request()

sub owner {
    my $s = shift;

    my $type     = 'ListAllMyBuckets';
    my $request  = $s->request( $type );
    my $response = $request->request();
    my $xpc      = $response->xpc;
    return AWS::S3::Owner->new(
        id           => $xpc->findvalue( '//s3:Owner/s3:ID' ),
        display_name => $xpc->findvalue( '//s3:Owner/s3:DisplayName' ),
    );
}    # end owner()

sub buckets {
    my ( $s ) = @_;

    my $type     = 'ListAllMyBuckets';
    my $request  = $s->request( $type );
    my $response = $request->request();

    my $xpc     = $response->xpc;
    my @buckets = ();
    foreach my $node ( $xpc->findnodes( './/s3:Bucket' ) ) {
        push @buckets,
          AWS::S3::Bucket->new(
            name          => $xpc->findvalue( './/s3:Name',         $node ),
            creation_date => $xpc->findvalue( './/s3:CreationDate', $node ),
            s3            => $s,
          );
    }    # end foreach()

    return @buckets;
}    # end buckets()

sub bucket {
    my ( $s, $name ) = @_;

    my ( $bucket ) = grep { $_->name eq $name } $s->buckets
      or return;
    $bucket;
}    # end bucket()

sub add_bucket {
    my ( $s, %args ) = @_;

    my $type     = 'CreateBucket';
    my $request  = $s->request( $type, bucket => $args{name}, location => $args{location} );
    my $response = $request->request();

    if ( my $msg = $response->friendly_error() ) {
        die $msg;
    }    # end if()

    return $s->bucket( $args{name} );
}    # end add_bucket()

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

AWS::S3 - Lightweight interface to Amazon S3 (Simple Storage Service)

=for html
<a href='https://travis-ci.org/leejo/AWS-S3?branch=master'><img src='https://travis-ci.org/leejo/AWS-S3.svg?branch=master' /></a>
<a href='https://coveralls.io/r/leejo/AWS-S3?branch=master'><img src='https://coveralls.io/repos/leejo/AWS-S3/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

  use AWS::S3;

  my $s3 = AWS::S3->new(
    access_key_id     => 'E654SAKIASDD64ERAF0O',
    secret_access_key => 'LgTZ25nCD+9LiCV6ujofudY1D6e2vfK0R4GLsI4H',
  );

  # Add a bucket:
  my $bucket = $s3->add_bucket(
    name    => 'foo-bucket',
  );

  # Set the acl:
  $bucket->acl( 'private' );

  # Add a file:
  my $new_file = $bucket->add_file(
    key       => 'foo/bar.txt',
    contents  => \'This is the contents of the file',
  );

  # You can also set the contents with a coderef:
  # Coderef should eturn a reference, not the actual string of content:
  $new_file = $bucket->add_file(
    key       => 'foo/bar.txt',
    contents  => sub { return \"This is the contents" }
  );

  # Get the file:
  my $same_file = $bucket->file( 'foo/bar.txt' );

  # Get the contents:
  my $scalar_ref = $same_file->contents;
  print $$scalar_ref;

  # Update the contents with a scalar ref:
  $same_file->contents( \"New file contents" );

  # Update the contents with a code ref:
  $same_file->contents( sub { return \"New file contents" } );

  # Delete the file:
  $same_file->delete();

  # Iterate through lots of files:
  my $iterator = $bucket->files(
    page_size   => 100,
    page_number => 1,
  );
  while( my @files = $iterator->next_page )
  {
    warn "Page number: ", $iterator->page_number, "\n";
    foreach my $file ( @files )
    {
      warn "\tFilename (key): ", $file->key, "\n";
      warn "\tSize: ", $file->size, "\n";
      warn "\tETag: ", $file->etag, "\n";
      warn "\tContents: ", ${ $file->contents }, "\n";
    }# end foreach()
  }# end while()

  # You can't delete a bucket until it's empty.
  # Empty a bucket like this:
  while( my @files = $iterator->next_page )
  {
    map { $_->delete } @files;

    # Return to page 1:
    $iterator->page_number( 1 );
  }# end while()

  # Now you can delete the bucket:
  $bucket->delete();

=head1 DESCRIPTION

AWS::S3 attempts to provide an alternate interface to the Amazon S3 Simple Storage Service.

B<NOTE:> Until AWS::S3 gets to version 1.000 it will not implement the full S3 interface.

B<Disclaimer:> Several portions of AWS::S3 have been adopted from L<Net::Amazon::S3>.

B<NOTE:> AWS::S3 is NOT a drop-in replacement for L<Net::Amazon::S3>.

B<TODO:> CloudFront integration.

=head1 CONSTRUCTOR

Call C<new()> with the following parameters.

=head2 access_key_id

Required.  String.

Provided by Amazon, this is your access key id.

=head2 secret_access_key

Required.  String.

Provided by Amazon, this is your secret access key.

=head2 secure

Optional.  Boolean.

Default is C<0>

=head2 endpoint

Optional.  String.

Default is C<s3.amazonaws.com>

=head2 ua

Optional.  Should be an instance of L<LWP::UserAgent> or a subclass of it.

Defaults to creating a new instance of L<LWP::UserAgent::Determined>

=head1 PUBLIC PROPERTIES

=head2 access_key_id

String.  Read-only

=head2 secret_access_key

String.  Read-only.

=head2 secure

Boolean.  Read-only.

=head2 endpoint

String.  Read-only.

=head2 ua

L<LWP::UserAgent> object.  Read-only.

=head2 owner

L<AWS::S3::Owner> object.  Read-only.

=head1 PUBLIC METHODS

=head2 buckets

Returns an array of L<AWS::S3::Bucket> objects.

=head2 bucket( $name )

Returns the L<AWS::S3::Bucket> object matching C<$name> if found.

Returns nothing otherwise.

=head2 add_bucket( name => $name, location => 'us-west-1' )

Attempts to create a new bucket with the name provided. The location parameter is optional
and, as per the AWS docs, will default to "us-east-1".

On success, returns the new L<AWS::S3::Bucket>

On failure, dies with the error message.

See L<AWS::S3::Bucket> for details on how to use buckets (and access their files).

=head1 SEE ALSO

L<The Amazon S3 API Documentation|http://docs.amazonwebservices.com/AmazonS3/latest/API/>

L<AWS::S3::Bucket>

L<AWS::S3::File>

L<AWS::S3::FileIterator>

L<AWS::S3::Owner>

=head1 AUTHOR

Originally John Drago C<jdrago_999@yahoo.com>, currently maintained by Lee Johnson (LEEJO) C<leejo@cpan.org>
with contributions from Evan Carroll, Robin Clarke, Ulrich Kautz, simbabque, Dave Rolsky

=head1 LICENSE

This software is Free software and may be used and redistributed under the same
terms as any version of perl itself.

Copyright John Drago 2011 all rights reserved.

=cut

