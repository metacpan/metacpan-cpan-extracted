package TestApp2;

use strict;
use warnings;

use Catalyst::Runtime 5.80;

use parent qw/Catalyst/;
use Catalyst;

__PACKAGE__->config(
   name => 'TestApp2',
   root => 'different_root',
   'View::CSS' => {
      stash_variable => 'frew',
   }
);

# Start the application
__PACKAGE__->setup();

1;
