package MyApp::Controller::Snips;

use Moose;
use MooseX::MethodAttributes;
extends 'Catalyst::Controller';

sub display :Path('') {
  my ($self, $c) = @_;
  $c->response->body(qq[
    <html>
      <body>
        <h1>Hello World</h1>
        <div>Stuff...</div>
      </body>
    </html>
  ]);
}

__PACKAGE__->meta->make_immutable;
