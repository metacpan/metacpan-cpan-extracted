#!perl

use warnings;
use strict;

use Test::More;

use Acme::Test::LogicalEquivalence qw(is_logically_equivalent);

note "Let's see if the universe still makes sense...";

note 'Identity laws';
is_logically_equivalent 1,
    sub { $a && 1 },
    sub { $a };
is_logically_equivalent 1,
    sub { $a || 0 },
    sub { $a };

note 'Domination laws';
is_logically_equivalent 1,
    sub { $a || 1 },
    sub { 1 };
is_logically_equivalent 1,
    sub { $a && 0 },
    sub { 0 };

note 'Idempotent laws';
is_logically_equivalent 1,
    sub { $a && $a },
    sub { $a };
is_logically_equivalent 1,
    sub { $a || $a },
    sub { $a };

note 'Double negation law';
is_logically_equivalent 1,
    sub { !!$a },
    sub { $a };

note 'Commutative laws';
is_logically_equivalent 2,
    sub { $a || $b },
    sub { $b || $a };
is_logically_equivalent 2,
    sub { $a && $b },
    sub { $b && $a };

note 'Associative laws';
is_logically_equivalent 3,
    sub { ($_[0] || $_[1]) || $_[2] },
    sub { $_[0] || ($_[1] || $_[2]) };
is_logically_equivalent 3,
    sub { ($_[0] && $_[1]) && $_[2] },
    sub { $_[0] && ($_[1] && $_[2]) };

note 'Distributive laws';
is_logically_equivalent 3,
    sub { $_[0] || ($_[1] && $_[2]) },
    sub { ($_[0] || $_[1]) && ($_[0] || $_[2]) };
is_logically_equivalent 3,
    sub { $_[0] && ($_[1] || $_[2]) },
    sub { ($_[0] && $_[1]) || ($_[0] && $_[2]) };

note 'De Morgan\'s laws';
is_logically_equivalent 2,
    sub { !($a && $b) },
    sub { !$a || !$b };
is_logically_equivalent 2,
    sub { !($a || $b) },
    sub { !$a && !$b };

note 'Absorption laws';
is_logically_equivalent 2,
    sub { $a || ($a && $b) },
    sub { $a };
is_logically_equivalent 2,
    sub { $a && ($a || $b) },
    sub { $a };

note 'Negation laws';
is_logically_equivalent 1,
    sub { $a || !$a },
    sub { 1 };
is_logically_equivalent 1,
    sub { $a && !$a },
    sub { 0 };

done_testing;

