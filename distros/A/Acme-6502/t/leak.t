use strict;
use warnings;

use Test::More;
use Acme::6502;
use Acme::6502::Tube;

eval { require Test::LeakTrace; };

plan skip_all => "Test::LeakTrace require for this test" if $@;

Test::LeakTrace::no_leaks_ok( sub {
    my $cpu = Acme::6502->new;
} );

Test::LeakTrace::no_leaks_ok( sub {
    my $cpu = Acme::6502::Tube->new;
} );

done_testing;
