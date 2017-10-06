package  MyApp::View::Item;

use Moo;

extends 'Catalyst::View::Template::Lace';

has name => (is=>'ro', required=>1);
has number => (is=>'ro', required=>1);

sub process_dom {
  my ($self, $dom) = @_;
  $dom->for('p', $self);
}

sub template {
  my $class = shift;
  return q[
    <p>Hi there
      <span class='name'>NAME</span>!
      You are number
      <span class='number'>Number</span></p>
  ];
}

1;
