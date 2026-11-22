use strict;
use warnings;
use feature 'state';

package TrafficLight;

use subs 'to_string';

use Class::Enumeration::Builder (
  { counter => sub { state $i = 0; my $r = $i; $i += 2; $r } },
  GREEN  => { action => 'go' },
  ORANGE => { action => 'slow down' },
  RED    => { action => 'stop' }
);

sub to_string {
  my ( $self ) = @_;

  $self->action . ' if ' . $self->name
}

1
