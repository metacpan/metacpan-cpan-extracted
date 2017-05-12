package TestApp3;

use strict;
use Catalyst qw(-Debug);

our $VERSION = '0.01';
use FindBin;

TestApp3->config( name => 'TestApp', root => "$FindBin::Bin/lib/TestApp3/root", );

TestApp3->setup;

1;
