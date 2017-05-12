{
    package Acme::Teddy;
    sub talk{ 'Yabba dabba do!' };
}
package main;
use Acme::Teddy;
use Test::More tests => 1;
my $bear    = Acme::Teddy->new();
my $talk    = $bear->talk();
is( $talk,      'Yabba dabba do!',  'teddy-oo-talk'    );

