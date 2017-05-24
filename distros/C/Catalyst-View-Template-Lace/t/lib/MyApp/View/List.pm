package  MyApp::View::List;

use Moo;
extends 'Catalyst::View::Template::Lace';
with 'Catalyst::View::Template::Lace::Role::URI',
  'Catalyst::View::Template::Lace::Role::ArgsFromStash',
  'Template::Lace::Model::AutoTemplate';

has [qw/form items copywrite/] => (is=>'ro', required=>1);

sub process_dom {
  my ($self, $dom) = @_;
  $dom->ol('#todos', $self->items);
}

1;
