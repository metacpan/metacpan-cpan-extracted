package AnyEvent::SparkBot::SharedRole;

=head1 NAME

AnyEvent::SparkBot::SharedRole - Shared methods for SparkBot

=head1 SYNOPSIS

  use Modern::Perl;
  use Moo;
  BEGIN { with 'AnyEvent::SparkBot::SharedRole' }

=head1 DESCRIPTION

Shared functions used between different sparkbot classes.

=cut

use Modern::Perl;
use Moo::Role;
use HTTP::Headers;
use Digest::MD5 qw(md5_base64);
use MooX::Types::MooseLike::Base qw(:all);
use UUID::Tiny ':std';
use namespace::clean;

has token=>(
  required=>1,
  is=>'ro',
  isa=>Str,
);

=head1 Constructor Arguments added

The following arguments are required when creating a new instance of a class that uses this role:

  token: This is the cisco authentication token for your app

=head1 Role methods

=over 4

=item * my $uuid=$self->uuidv4() 

Returns the next uuid.v4 ( md5 sum base64 encoded, due to limitations of cisco spark )

=cut

sub uuidv4 {
  return md5_base64(create_uuid(UUID_V4));
}

=item * my $headers=$self->default_headers()

Returns an HTTP::Headers Object that contains the default header values

=cut

sub default_headers  {
  my ($self)=@_;
  my $h=new HTTP::Headers;
  $h->header(Authorization=>'Bearer ' .$self->token);
  $h->header('Content-Type', 'application/json; charset=UTF-8');
  $h->header(Accept=>'application/json');
  return $h;
}

=back

=head1 AUTHOR

Michael Shipper <AKALINUX@CPAN.ORG>

=cut

1;
