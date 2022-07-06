package Catalyst::View::Errors::HTML;

use Moose;
use Text::Template;

extends 'Catalyst::View';
with 'Catalyst::Component::ApplicationAttribute';

has template_engine_args => (
  is=>'ro',
  required=>1,
  lazy=>1,
  default=> sub {
    my $self = shift;
    my $template = $self->_application->config->{root}->file($self->template_name); 
    my $source = -e $template ? $template->slurp : $self->html($self->_application);
    return +{TYPE => 'STRING', SOURCE => $source};
  },
);

has template_name => (is=>'ro', required=>1, default=>'http_errors_html.tmpl');

sub html {
  my ($self, $app) = @_;
  return q[
<!DOCTYPE html>
<html lang="{$lang}">
<head>
    <meta charset="utf-8" /><meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="icon" href="data:,"> <!-- Stop favicon for now -->
    <title>{$title}</title>
</head>
<body>
    <div class="cover"><h1>{$status_code}: {$title}</h1><p class="lead">{$message}</p></div>
</body>
</html>
  ];
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
  my $html = $self->render_template($c, \%args);

  $c->response->body($html);
  $c->response->content_type('text/html');
  $c->response->status($code);
}

sub render_template {
  my ($self, $c, $message_info) = @_;
  return my $html = $self->template_engine->fill_in(HASH => $message_info);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::View::Errors::HTML - Standard HTTP Errors Responses in HTML

=head1 SYNOPSIS

    package MyApp::View::HTML;

    use Moose;
    extends 'Catalyst::View::Errors::HTML';

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

View class for generating error responses.  If you want a lot of customizations you can subclass
this in your application, or just use your own view.  You can customize this by adding a template
at C<$APPHOME/root/http_errors_html.tmpl> (using L<Text::Template> as the templating system)

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

=head1 METHODS

This view exposes the follow methods for public use or for a programmer to override
to change function.

=head2 html

Should return a string suitable for L<Text::Template> and is used to generate
an HTML error response.   This is used if there's no file at C<$APPHOME/root/http_errors_html.tmpl>

=head1 CONFIGURATION

This View exposes the following configuration options

=head2 template_engine_args

Args that are used to start the L<Text::Template> template engin

=head2 template_name

Name of the files under $APPHOME/root that is used to render an error view.
Default is C<http_errors_html.tmpl>.   If this this file doesn't exist we 
instead use the return of L</html> method for the template string.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
