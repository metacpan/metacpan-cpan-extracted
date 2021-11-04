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

has cn => (
  is => 'ro',
  init_arg => undef,
  required => 1, 
  default => sub { CatalystX::Utils::ContentNegotiation::content_negotiator },
);

has default_language => (is=>'ro', required=>1, default=>'en_US');

sub http_default {
  my ($self, $c, $code, %args) = @_;
  my $lang = $self->get_language($c);
  my $message_info = $self->finalize_message_info($c, $code, $lang, %args);

  my $json = $self->render_json($c, $message_info);
 
  $c->response->body($json);
  $c->response->content_type('application/json');
  $c->response->status($code);
}

sub get_language {
  my ($self, $c) = @_;
  if(my $lang = $c->request->header('Accept-Language')) {
    return $self->cn->choose_language([$self->available_languages($c)], $lang) || $self->default_language;
  }
  return $self->default_language;
}

sub available_languages {
  my ($self, $c) = @_;
  return my @lang_tags = CatalystX::Utils::ErrorMessages::available_languages;
}

sub finalize_message_info {
  my ($self, $c, $code, $lang, %args) = @_;
  my $message_info = $self->get_message_info($c, $lang, $code);
  return +{
    info => {
      lang => $lang, 
      uri => delete($args{uri}), 
      %{$args{info}||+{} },
    },
    errors => [
      {
        status => delete($args{code}),
        title => $message_info->{title},
        description => $message_info->{message},
      },
      @{$args{errors}||[] },
    ],
  };
}

sub get_message_info {
  my ($self, $c, $lang, $code) = @_;
  return my $message_info_hash = CatalystX::Utils::ErrorMessages::get_message_info($lang, $code);
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

=head2 available_languages

An array of the languages available for serving error responses.   By default we use
L<CatalystX::Utils::ErrorMessages> but if you have your own list of translations you can override
this.

=head2 get_message_info

Return error message info by code and language.  By default we use
L<CatalystX::Utils::ErrorMessages> but if you have your own list of translations you can override
this.

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
             "description" : "The requested resource could not be found but may be available again in the future.",
             "status" : 404
          }
       ]
    }

When dispatching an error you can add to the C<info> and C<errors> keys by passing information
via the arguments to C<$c->dispatch_error>.   For example:

    $c->dispatch_error(400 =>
      info => { error_count = 2 },
      errors => [
        {
          field => 'name',
          message => 'too short',
        },
      errors => [
        {
          field => 'age',
          message => 'too young',
        },
      ],
    );

Will result in:

    {
       "info" : {
          "lang" : "en_US",
          "uri" : "http://localhost:5000/"
       },
       "errors" : [
          {
             "title" : "Resource not found",
             "description" : "The requested resource could not be found but may be available again in the future.",
             "status" : 404
          },
          {
             "field" : "name",
             "message" : "too short",
          },
          {
             "field" : "age",
             "message" : "too old",
          }
       ]
    }

If you want a different error setup you'll need to override this method to do as you wish.    

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
