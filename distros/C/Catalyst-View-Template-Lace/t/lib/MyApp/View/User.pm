package  MyApp::View::User;

use Moo;
use Template::Lace::Utils 'mk_component';
extends 'Catalyst::View::Template::Lace';
with 'Catalyst::View::Template::Lace::Role::ArgsFromStash',
  'Template::Lace::Model::AutoTemplate',
  'Catalyst::View::Template::Lace::Role::URI';

has [qw/age name motto/] => (is=>'ro', required=>1);

sub template {q[
  <html>
    <head>
      <title>User Info</title>
    </head>
    <body>
      <dl id='user'>
        <dt><a>Name</a></dt>
        <dd id='name'>NAME</dd>
        <dt>Age</dt>
        <dd id='age'>AGE</dd>
        <dt>Motto</dt>
        <dd id='motto'>MOTTO</dd>
      </dl>
      <catalyst-subrequest action='/snips/display' at='body' />
    </body>
  </html>
]}

sub process_dom {
  my ($self, $dom) = @_;
  $dom->dl('#user', +{
   age=>$self->age,
   name=>$self->name,
   motto=>$self->motto});

  $dom->at('a')
    ->href($self->uri('display'));
}

__PACKAGE__->config(
  component_handlers => {
    tag => {
      anchor => mk_component {
        return "<a href='$_{href}'>$_{content}</a>"
      },
    }
  }
);
