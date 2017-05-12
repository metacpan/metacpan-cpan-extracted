use strict;
use warnings;

use Test::More;
plan tests => 3;

my $app = q|
    package TestApp;
    use Dancer2;


    BEGIN {

                
        set plugins => {
            FlashNote => {
                queue   => 'single',
                dequeue => 'when_used',
                whatever => 'it is',
                foo => 'bar',
            },
        };
    }
    

    
    use Dancer2::Plugin::FlashNote;
|;

eval $app;

my $ret = $@;

ok( $ret, 'app with extra arguments should fail' );

like( $ret, qr/invalid configuration keys.*$_/, "'$_' included in error" )
  for qw( whatever foo );
