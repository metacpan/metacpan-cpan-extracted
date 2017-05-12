{
    package Acme::Teddy;
    sub chewtoy{ 'Squeek!' };
    our $yogi   = 'bear';
}
package main;
use Acme::Teddy qw( chewtoy $yogi );
use Test::More tests => 2;
is( chewtoy(),  'Squeek!',          'teddy-squeek'  );
is( $yogi,      'bear',             'teddy-bear'    );

# Thanks to [james2vegas] of PerlMonks for improvements in this test.
