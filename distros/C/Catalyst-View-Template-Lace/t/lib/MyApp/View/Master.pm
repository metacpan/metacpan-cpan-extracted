package  MyApp::View::Master;

use Moo;
extends 'Catalyst::View::Template::Lace';
with 'Template::Lace::ModelRole';

has title => (is=>'ro', required=>1);
has css => (is=>'ro', required=>1);
has meta => (is=>'ro', required=>1);
has body => (is=>'ro', required=>1);

# This can be called either once at setup time or
# dynamically per request.

sub on_component_add {
  my ($self, $dom) = @_;
  $dom->title($self->title)
    ->head(sub { $_->append_content($self->css->join) })
    ->head(sub { $_->prepend_content($self->meta->join) })
    ->body(sub { $_->at('h1')->append($self->body) });
}

sub process_dom {
  my ($self, $dom) = @_;
  $dom->title($self->title)
    ->head(sub { $_->append_content($self->css->join) })
    ->head(sub { $_->prepend_content($self->meta->join) })
    ->body(sub { $_->at('h1')->append($self->body) });
}

sub template {
  my $class = shift;
  return q[
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta content="width=device-width, initial-scale=1" name="viewport" />
        <title>Page Title</title>
        <link href="/static/base.css" rel="stylesheet" />
        <link href="/static/index.css" rel="stylesheet"/ >
      </head>
      <body id="body">
        <h1>Intro</h1>
      </body>
    </html>        
  ];
}

1;
