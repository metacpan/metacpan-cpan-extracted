use strict;
use warnings;
use Test::Fatal;
use Test::More 0.88;
use lib 't/lib';
use Test::Class::Load 'load_class';

my @bad = qw(
    Foo:Bar
    123
    Foo::..::..::tmp::bad.pl
    ::..::tmp::bad
    ''tmp
    'tmp
);

for my $name (@bad) {
    like(
        exception { load_class($name) },
        qr/^\Q`$name' is not a module name/,
        "invalid module name - $name"
    );
}

done_testing;
