use strict;
use Test::More;
use Test::LeakTrace;

use_ok 'Acme::Pointer';

my $a = {
    a => 20,
    b => [1, 2]
};
my $b = [1 .. 10];
my $c = sub { 1 };
my $d = \"Hello";

for my $ref ($a, $b, $c, $d) {
    my $t = ref $ref;
    my $addr = "$ref";

    my $deref;
    no_leaks_ok {
        $deref = deref($addr);
    } "Detected memory leak via deref with $t";

    is_deeply($deref, $ref);

    my $p;
    no_leaks_ok {
        if ($addr =~ /[A-Z]+\((.*)\)/) {
            $p = pointer($1);
        }
    } "Detected memory leak via pointer with $t";

    is_deeply($p, $ref);
}


done_testing;

