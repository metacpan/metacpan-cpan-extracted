use Test::More qw(no_plan);

use strict;
use warnings;

use Attribute::Generator;

sub foo:Generator {
    my($i) = @_;
    while(1) {
        if(my $sent = yield $i++) {
            $i = $sent;
        }
    }
}

my $foo = foo(0);

is($foo->next, 0);
is($foo->next, 1);
is($foo->next, 2);
is($foo->next, 3);
is($foo->next, 4);
$foo->send(8);
is($foo->next, 8);
is($foo->next, 9);
is($foo->next, 10);
$foo->send(1);
is($foo->next, 1);
is($foo->next, 2);
