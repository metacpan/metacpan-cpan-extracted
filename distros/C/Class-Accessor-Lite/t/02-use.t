package L;

use strict;
use warnings;
use Class::Accessor::Lite (
    new => 1,
    rw  => [ qw(foo bar baz) ],
    ro  => [ qw(tokuhirom) ],
    wo  => [ qw(yappo) ],
);

use Test::More tests => 6;

my $l = L->new(
    bar       => 1,
    tokuhirom => 2,
);
is ref($l), 'L';
ok ! defined $l->foo;
is $l->bar, 1;
is $l->tokuhirom, 2;
$l->bar(3);
is $l->bar, 3;
$l->yappo(4);
is $l->{yappo}, 4;
