########################################################################
# Simple immutable credentials object — used when caller passes
# raw key/secret/token rather than a credentials object
########################################################################
package Amazon::S3::Lite::Credentials;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '1.2.2';

sub new {
  my ( $class, %args ) = @_;

  croak 'aws_access_key_id is required'
    if !$args{aws_access_key_id};

  croak 'aws_secret_access_key is required'
    if !$args{aws_secret_access_key};

  return bless {
    aws_access_key_id     => $args{aws_access_key_id},
    aws_secret_access_key => $args{aws_secret_access_key},
    token                 => $args{token},
  }, $class;
}

sub aws_access_key_id     { return $_[0]->{aws_access_key_id} }
sub aws_secret_access_key { return $_[0]->{aws_secret_access_key} }
sub token                 { return $_[0]->{token} }
sub session_token         { return $_[0]->{token} }

1;
