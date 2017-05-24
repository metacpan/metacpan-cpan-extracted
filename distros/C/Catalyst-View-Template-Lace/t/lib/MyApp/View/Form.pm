package  MyApp::View::Form;

use Moo;
extends 'Catalyst::View::Template::Lace';

has [qw/id fif errors content/] => (is=>'ro', required=>0);

sub process_dom {
  my ($self, $dom) = @_;
  $dom->at('form')
    ->attr(id=>$self->id)
    ->content($self->content);      
}

sub template {
  my $class = shift;
  return q[<form></form>];
}

1;
