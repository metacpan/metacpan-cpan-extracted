package Bot::ChatBots::Whatever::Something;

use Moo;

has app => (
   is => 'rw',
   lazy => 1,
   predicate => 1,
);

has foo => (
   is => 'rw',
   lazy => 1,
   predicate => 1,
);


1;
