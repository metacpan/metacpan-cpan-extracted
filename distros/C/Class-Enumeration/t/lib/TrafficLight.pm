use strict;
use warnings;

package TrafficLight;

use subs 'to_string';

use Class::Enumeration::Builder (
  GREEN  => { action => 'go' },
  ORANGE => { action => 'slow down' },
  RED    => { action => 'stop' }
);

sub to_string {
  my ( $self ) = @_;

  $self->action . ' if ' . $self->name
}

1
