use strict;
use warnings;

use Test::More tests => 3;

{
    package BaseTest;
    use Class::C3;
    sub new { bless {} => shift }

    package OverloadingTest;
    use Class::C3;
    BEGIN { our @ISA = ('BaseTest'); }
    use overload '+'  => sub { die "called plus operator in OT" },
                 fallback => 0;

    package InheritingFromOverloadedTest;
    BEGIN { our @ISA = ('OverloadingTest'); }
    use Class::C3;
    use overload '+'  => sub { die "called plus operator in IFOT" },
                 fallback => 1;

    package IFOTX;
    use Class::C3;
    BEGIN { our @ISA = ('OverloadingTest'); }

    package IFIFOT;
    use Class::C3;
    BEGIN { our @ISA = ('InheritingFromOverloadedTest'); }

    package Foo;
    use Class::C3;
    BEGIN { our @ISA = ('BaseTest'); }
    use overload '+'  => sub { die "called plus operator in Foo" },
                 fallback => 1;

    package Bar;
    use Class::C3;
    BEGIN { our @ISA = ('Foo'); }
    use overload '+'  => sub { die "called plus operator in Bar" },
                 fallback => 0;

    package Baz;
    use Class::C3;
    BEGIN { our @ISA = ('Bar'); }
}

Class::C3::initialize();

my $x = IFOTX->new();
eval { $x += 1 };
like($@, qr/no method found,/);

my $y = IFIFOT->new();
eval { $y += 1 };
like($@, qr/called plus operator in IFOT/);

my $z = Baz->new();
eval { $z += 1 };
like($@, qr/no method found,/);

