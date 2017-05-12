#!perl -T

use Test::More tests => 7; 
use Acme::Meow;

{
    my $kitty = Acme::Meow->new();
    is( ref $kitty, 'Acme::Meow', '->new gave us a kitty' );

    ok( ref $kitty->can('pet'), 'you can pet the kitty' );
    ok( ref $kitty->can('feed'), 'you can feed the kitty' );

    ok( ref $kitty->can('is_sleeping'), 'you check if the kitty is_sleeping' );
    ok( ref $kitty->can('_kitty_status'), '_kitty_status' );

}
{
    ok( ref __PACKAGE__->can('milk'), 'milk was exported' );
    ok( ref __PACKAGE__->can('nip'), 'nip was exported' );
}
