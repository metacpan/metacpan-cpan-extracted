package Catalyst::View::Errors::Text;

use Moose;
use Text::Template;
use CatalystX::Utils::ContentNegotiation;
use CatalystX::Utils::ErrorMessages;

extends 'Catalyst::View';
with 'Catalyst::Component::ApplicationAttribute';

has template_engine_args => (
  is=>'ro',
  required=>1,
  lazy=>1,
  default=> sub {
    my $self = shift;
    my $template = $self->_application->config->{root}->file($self->template_name); 
    my $source = -e $template ? $template->slurp : $self->text($self->_application);
    return +{TYPE => 'STRING', SOURCE => $source};
  },
);

has template_name => (is=>'ro', required=>1, default=>'http_errors_text.tmpl');
has default_language => (is=>'ro', required=>1, default=>'en_US');

sub text {
  my ($self, $app) = @_;
  return q[{$code} {$title}:{$message}]."\n";
}

has template_engine => (
  is => 'ro',
  required => 1,
  init_arg => undef,
  lazy => 1,
  default => sub {
    my %args = %{shift->template_engine_args};
    my $engine = Text::Template->new(%args);
    $engine->compile;
    return $engine;
  }
);

has cn => (
  is => 'ro',
  init_arg => undef,
  required => 1, 
  default => sub { CatalystX::Utils::ContentNegotiation::content_negotiator },
);

sub http_default {
  my ($self, $c, $code, %args) = @_;
  my $lang = $self->get_language($c);
  my $message_info = $self->finalize_message_info($c, $code, $lang, %args);

  my $text = $self->render_template($c, $message_info);
 
  $c->response->body($text);
  $c->response->content_type('text/plain');
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
    %$message_info,
    lang => $lang,
    %args,
  };
}

sub get_message_info {
  my ($self, $c, $lang, $code) = @_;
  return my $message_info_hash = CatalystX::Utils::ErrorMessages::get_message_info($lang, $code);
}

sub render_template {
  my ($self, $c, $message_info) = @_;
  return my $text = $self->template_engine->fill_in(HASH => $message_info);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::View::Errors::Text - Standard HTTP Errors Responses in Plain Text.

=head1 SYNOPSIS

    package MyApp::View::Text;

    use Moose;
    extends 'Catalyst::View::Errors::Text';

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

View class for generating error responses.  If you want a lot of customizations you can subclass
this in your application, or just use your own view.

=head1 METHODS

This view exposes the follow methods for public use or for a programmer to override
to change function.

=head2 text

Should return a string suitable for L<Text::Template> and is used to generate
a plain text error response.   This is used if there's no file at C<$APPHOME/root/http_errors_text.tmpl>

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

=head1 CONFIGURATION

This View exposes the following configuration options

=head2 template_engine_args

Args that are used to start the L<Text::Template> template engin

=head2 template_name

Name of the files under $APPHOME/root that is used to render an error view.
Default is C<http_errors_text.tmpl>.   If this this file doesn't exist we 
instead use the return of L</text> method for the template string.

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
