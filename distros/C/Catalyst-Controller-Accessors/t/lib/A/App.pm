package A::App;

use Moose;

has stash => (
   is      => 'rw',
   default => sub { +{} },
);

1;
