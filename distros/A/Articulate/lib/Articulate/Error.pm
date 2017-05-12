package Articulate::Error;
use strict;
use warnings;

=head1 NAME

Articulate::Error - represent an error or exception in processing a
request

=cut

use Module::Load;
use overload '""' =>
  sub { my $self = shift; $self->http_code() . ' ' . $self->simple_message };

use Exporter::Declare;
default_exports qw(throw_error);

=head1 FUNCTIONS

=head3 throw_error

  throw_error 'Forbidden';
  throw_error NotFound => "I don't want to alarm you, but it seems to be missiong";

This creates an error of the type provided and throws it immediately.
These are things like C<Articulate::Error::Forbidden>.

=cut

sub throw_error {
  new_error(@_)->throw;
}

sub new_error {
  my ( $type, $message ) = @_;
  my $class = __PACKAGE__ . ( $type ? '::' . $type : '' );
  $class->new( { ( $message ? ( simple_message => $message ) : () ) } );
}

use Moo;
with 'Throwable';
with 'StackTrace::Auto';

=head1 METHODS

=head3 new

An ordinary Moo constructor.

=head3 throw

Implements the C<Throwable> role - basically C<< die
__PACKAGE__->new(@_) >>.

=head1 ATTRIBUTES

=head3 simple_message

Be kind and let the user know what happened, in summary. Default is 'An
unknown error has occurred'.

That said, do consider whether this is the right place to put
potentially sensitive diagnostic information.

=head3 http_code

The equivalent status code.

Defaults to 500, always an integer.

=head3 caller

Tries to take a sensible guess at where in your code this was actually
thrown from. This may vary, don't rely on it!

=cut

has simple_message => (
  is      => 'rw',
  default => sub { 'An unknown error has occurred' },
);

has http_code => (
  is      => 'rw',
  default => sub { 500 },
  coerce  => sub { 0 + shift }
);

has caller => (
  is      => 'rw',
  default => sub {
    ( [ caller(0) ]->[0] =~ m/Throwable/ )
      ? [ 'hmm', caller(2) ]
      : [ caller(1) ];
  }
);

# This needs to go at the end, because of Class::XSAccessor stuff

Module::Load::load( __PACKAGE__ . '::' . $_ ) for qw(
  BadRequest
  Forbidden
  Internal
  NotFound
  Unauthorised
  AlreadyExists
);

1;
