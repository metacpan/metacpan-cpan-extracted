package TestApp2;

use strict;
use Catalyst;

our $VERSION = '0.01';
use FindBin;

TestApp2->config( name => 'TestApp2', root => "$FindBin::Bin/lib/TestApp2/root",
  error_handler => {
    handlers => {
            '404' => { template => 'error/404', },
    },
    expose_stash => [qw/key1 key2 key3/],
  }
);

TestApp2->setup;

1;
