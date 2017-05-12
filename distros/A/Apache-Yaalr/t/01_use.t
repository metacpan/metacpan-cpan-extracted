
use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok('Apache::Yaalr') };

for my $class ( qw[Apache::Yaalr] ) {
    local $^W;   # turn on warnings (or off if they were already on)
    use_ok( $class );
}

# see if we can create an object
my $a = Apache::Yaalr->new;
ok( defined $a, "New object created." );
ok( $a->isa( 'Apache::Yaalr' ), "Right kind of object.");

can_ok($a, 'os' );
can_ok($a, 'apache2_conf');
