use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok( 'Acme::Greeting' );
}

my $greeting = Acme::Greeting->new( language => 'zh_tw' );
ok defined $greeting;

my $hello = Acme::Greeting->new( language => 'zh_tw' );
ok defined $hello;

isnt($greeting, $hello);

