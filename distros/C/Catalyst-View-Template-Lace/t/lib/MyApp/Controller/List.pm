package MyApp::Controller::List;

use warnings;
use strict;
use base 'Catalyst::Controller';

sub display :Path('') Args(0) {
  my ($self, $c) = @_;
  $c->stash->{copywrite} = 2015;
  $c->view('List',
    form => {
      fif => {
        item => 'milk',
      },
      errors => {
        item => ['too short', 'too similar it existing item'],
      }
    },
    items => [
      'Buy Milk',
      'Walk Dog',
    ],
  )->http_ok;
}

1;
