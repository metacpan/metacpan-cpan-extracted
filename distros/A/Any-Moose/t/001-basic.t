use strict;
use warnings;
use Test::More 0.88;

do {
    package Point;
    no warnings 'deprecated';
    use Any::Moose;

    has ['x', 'y'] => (
        is  => 'rw',
        isa => 'Int',
    );

    sub BUILDARGS {
        my ($class, $x, $y) = @_;
        return { x => $x, y => $y };
    }
};

my $origin = Point->new(0, 0);
is($origin->x, 0);
is($origin->y, 0);

my $aa = Point->new(1, 1);
is($aa->x, 1);
is($aa->y, 1);

$aa->x(-1);

is($aa->x, -1);
is($aa->y, 1);

done_testing;

