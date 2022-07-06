package CatalystX::Utils::DoesHttpException;

use Moose::Role;
use Carp;

with 'Catalyst::Exception::Interface';

has '_status_code' => (is=>'ro', init_arg=>'status_code', predicate=>'has_status_code');
has '_error' => (is=>'ro', init_arg=>'error', predicate=>'has_error');
has '_message' => (is=>'ro', init_arg=>'message', predicate=>'has_message');
has '_additional_headers' => (is=>'ro', init_arg=>'additional_headers', predicate=>'has_additional_headers');

sub status_code {
  my $self = shift;
  return $self->has_status_code ? $self->_status_code : 500;
}

sub error {
  my $self = shift;
  return $self->has_error ? $self->_error : 'The system has generated unspecifed errors.';
}

sub message {
  my $self = shift;
  return $self->_message if $self->has_message;
  return undef;
}

sub additional_headers {
  my $self = shift;
  return $self->_additional_headers if $self->has_additional_headers;
  return [];
}

sub as_http_response {
  my $self = shift;
  my $message = $self->message;
  my %template_args = ();

  $template_args{message} = $message if $message;
  $template_args{error} = $self->error;

  return $self->status_code, $self->additional_headers, \%template_args;
}

# The following are required by 'Catalyst::Exception::Interface'.

sub as_string {
    my ($self) = @_;
    return $self->error;
}

sub throw {
    my $class = shift;
    my (%args) = @_;
    my $error = $class->new(%args);
    local $Carp::CarpLevel = 1;
    croak $error;
}
 
sub rethrow {
    my ($self) = @_;
    croak $self;
}

1;

=head1 NAME

CatalystX::Utils::DoesHttpException - An exception role

=head1 SYNOPSIS

  package MyApp::Exception::NoCoffee;

  use Moose;
  extends 'CatalystX::Utils::DoesHttpException';

  sub status_code { 418 }
  sub error { 'Coffee not allowed' }
  sub additional_headers { [ 'X-Error-Code' => '200101' ] }

=head1 DESCRIPTION

A L<Moose::Role> that does two things: 1) Create an exception object that L<Catalyst>
knows how to handle and 2) Tag that exception object with HTTP meta data so that L<CatalystX::Errors>
knows how to properly create a response to the client.

Sometimes you need to throw exceptions from classes that are external to L<Catalyst> (for
example L<DBIx::Class>).  These are exceptions which are meant to be truely exceptional situations
for which no validation code or other business logic could catch (for example a sudden glitch in 
the database) and for which we just need to display a meaningful error response to the user.  In
the past most of these errors would fall into the generic '500 Server Error' bucket but this
approach lets you throw errors that are tagged with HTTP response information which allows you
to return a customized response that L<CatalystX::Errors> knows how to handle.

There are 4 fields related to the HTTP response and you can set each in one of two ways, either as
an init argument passed to ->new or as a custom subroutine in your consuming class.  If you are
makeing custom expection objects it is likely you will be just overriding the methods but both
approaches are allowed:

=over

=item status_code

This is the HTTP status code.  Defaults to 500 if not provided.  Should be a 4xx or 5xx HTTP status
error code.

=item error

This is a string which is the text version of the error.  This is not seen by the client but instead
goes to whatever you have handling the L<Catalyst> error log ($c->log->error($err)).  Default is text
'The system has generated unspecifed errors.'.

=item additional_headers

This is an arrayref of key / value pairs which are extra HTTP headers that wil be sent to the client.
Some HTTP error codes have required HTTP headers (like 401 Unauthorized should return a WWW-Authenticate
header that tells the client how to authenticate).  Otherwise an optional field which just returns an
empty arrayref.

=item message

This is optional.  This is the message that gets sent to the client as part of the response.  If you
don't set this field then L<CatalystX::Errors> will use whatever the standard text of the error message
is for the C<status_code> you set via L<CatalystX::Utils::ErrorMessages>.  You can override if you prefer
to control the error message yourself (or just write a custom view).

Remember if you choose to write a custom message you need to take care to properly scrub / HTML escape
any data that is coming from the client before using it in the response, else you are opening a HTML /
Javascript injection attack in your system.

=back

=head1 EXAMPLE

A more detailed example:

    package Catalyst::ActionRole::Verbs::Utils::MethodNotAllowed;
     
    use Moose;
    use namespace::clean -except => 'meta';
      
    with 'CatalystX::Utils::DoesHttpException';
    
    has resource => (is=>'ro', required=>1);
    has allowed_methods => (is=>'ro', isa=>'ArrayRef[Str]', required=>1);
    has attempted_method => (is=>'ro', isa=>'Str', required=>1);

    sub status { 405 }
    sub error { "invalid method '@{[ $_[0]->attempted_method ]}' }
    sub message {
      "HTTP Method '@{[ $_[0]->attempted_method ]}' not permitted for resource '@{[ $_[0]->resource ]}'." .
      "Can only be: @{[ join ', ', @{$_[0]->allowed_methods||[]} ]}";
    );
     
    __PACKAGE__->meta->make_immutable;

In this case the user would get a 405 error and the error will go to the error logs for tracking while the
more detailed 'message' would return to the user.  Please note that you should scrub the values of 'allowed_methods'
since that's coming from the client and could be used as a type of HTML / Javascript injection attack.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
