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

sub text {
  my ($self, $app) = @_;
  return q[{$status_code} {$title}:{$message}]."\n";
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

sub http_default {
  my ($self, $c, $code, %args) = @_;
  my $text = $self->render_template($c, \%args);

  $c->response->body($text);
  $c->response->content_type('text/plain');
  $c->response->status($code);
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

The follow field arguments are passed to this template:

=over 4

=item lang

Defaults to "en_US".  This is the language code of the error response.

=item message

This is a text message of the error condition

=item status_code

This is the HTTP Status code of the error

=item title

The official HTTP Status error title (Not Found, Not Authorized, etc.)

=item uri

The URI that generated the error.  Be careful displaying this in your template since if its not
properly escaped you can open yourself to HTML injection / Javascript injection attackes.

=back

In addition any other arguments passed in ->dispatch_error / ->detach_error.

=head2 text

Should return a string suitable for L<Text::Template> and is used to generate
a plain text error response.   This is used if there's no file at C<$APPHOME/root/http_errors_text.tmpl>

=head1 CONFIGURATION

This View exposes the following configuration options

=head2 template_engine_args

Args that are used to start the L<Text::Template> template engin

=head2 template_name

Name of the files under $APPHOME/root that is used to render an error view.
Default is C<http_errors_text.tmpl>.   If this this file doesn't exist we 
instead use the return of L</text> method for the template string.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
