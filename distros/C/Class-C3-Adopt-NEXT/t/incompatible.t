use strict;
use warnings;
use Test::More tests => 3;

use Class::C3::Adopt::NEXT;

{
    package X;

    package Y;

    package XY;
    our @ISA = qw/X Y/;

    package YX;
    our @ISA = qw/Y X/;

    package Z;
    our @ISA = qw/XY YX/;

    sub foo { shift->NEXT::foo(@_) }
}

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

is(scalar @warnings, 0, 'no warnings yet');

Z->foo;
Z->foo;

is(scalar @warnings, 1, 'got a warning',);
like($warnings[0], qr/inconsistent hierarchy .* merg(?:e|ing)/i, 'inconsistent c3 hierarchy');
