package Catalyst::View::Errors::JSON;

use Moose;
use JSON::MaybeXS;
use CatalystX::Utils::ContentNegotiation;
use CatalystX::Utils::ErrorMessages;

extends 'Catalyst::View';

has extra_encoder_args => (is=>'ro', required=>1, default => sub { +{} });

has encoder => (
  is => 'ro',
  init_arg => undef,
  required => 1,
  lazy => 1,
  default => sub { JSON::MaybeXS->new(utf8=>1, %{shift->extra_encoder_args}) },
);

sub http_default {
  my ($self, $c, $code, %args) = @_;
  my $message_info = $self->finalize_message_info($c, $code, %args);
  my $json = $self->render_json($c, $message_info);
 
  $c->response->body($json);
  $c->response->content_type('application/json');
  $c->response->status($code);
}

sub finalize_message_info {
  my ($self, $c, $code, %args) = @_;
  return +{
    info => {
      lang => delete($args{status_code}), 
      uri => delete($args{uri}), 
    },
    error => [
      {
        status_code => $code,
        title => delete($args{title}),
        message => delete($args{message}),
      },
    ],
  };
}


sub render_json {
  my ($self, $c, $message_info) = @_;
  return $self->encoder->encode($message_info);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::View::Errors::JSON - Standard HTTP Errors Responses in JSON

=head1 SYNOPSIS

    package MyApp::View::JSON;

    use Moose;
    extends 'Catalyst::View::Errors::JSON';

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Used to generate a JSON error response in standard way.

=head1 METHODS

This view exposes the follow methods for public use or for a programmer to override
to change function.

=head2 finalize_message_info

Finalizes the hash of data that is sent to the template handler to make the body of the error
response.  You can override if you want to change or add to this data.

By default you get an error message that looks like this:

    {
       "info" : {
          "lang" : "en_US",
          "uri" : "http://localhost:5000/"
       },
       "errors" : [
          {
             "title" : "Resource not found",
             "messge" : "The requested resource could not be found but may be available again in the future.",
             "status_code" : 404
          }
       ]
    }

If you're passing extra template args you'll need to override this method to handle things as you
wish.

=head1 CONFIGURATION

This View exposes the following configuration options

=head2 extra_encoder_args

Extra args used to initialize the L<JSON::MaybeXS> object.

=head2 default_language

When doing content negotiation if there's no language preferred by the client
use this language.   Default is C<en_US>.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
