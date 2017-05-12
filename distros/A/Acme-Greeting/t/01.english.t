use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok( 'Acme::Greeting' );
}

my $greeting = Acme::Greeting->new();
ok defined $greeting;

my $hello = Acme::Greeting->new();
ok defined $hello;

isnt($greeting, $hello);

