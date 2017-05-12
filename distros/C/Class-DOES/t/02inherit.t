#!/usr/bin/perl

use warnings;
use strict;

use t::Utils;
my $T;

{
    package t::Base;
    use Class::DOES "Role::A";
}

{
    package t::Left;
    our @ISA = "t::Base";
    use Class::DOES "Role::B";
}

{
    package t::Right;
    our @ISA = "t::Base";
    use Class::DOES "Role::C";
}

{
    package t::Diamond;
    our @ISA = qw/t::Left t::Right/;
    use Class::DOES "Role::D";
}

my $obj = bless [], "t::Diamond";

BEGIN { $T += 9 * 2 }

for ("t::Diamond", $obj) {
    does_ok $_, "t::Diamond";
    does_ok $_, "t::Right";
    does_ok $_, "t::Left";
    does_ok $_, "t::Base";
    does_ok $_, "UNIVERSAL";

    does_ok $_, "Role::A";
    does_ok $_, "Role::B";
    does_ok $_, "Role::C";
    does_ok $_, "Role::D";
}

{
    package t::NR::Base;
}

{
    package t::NR::Left;
    our @ISA = "t::NR::Base";
}

{
    package t::NR::Right;
    our @ISA = "t::NR::Base";
    use Class::DOES "Role::E";
}

{
    package t::NR::Diamond;
    our @ISA = qw/t::NR::Left t::NR::Right/;
}

my $nr = bless [], "t::NR::Diamond";

BEGIN { $T += 6 * 2 }

for ("t::NR::Diamond", $nr) {
    does_ok $_, "t::NR::Diamond";
    does_ok $_, "t::NR::Left";
    does_ok $_, "t::NR::Right";
    does_ok $_, "t::NR::Base";
    does_ok $_, "UNIVERSAL";

    does_ok $_, "Role::E";
}

BEGIN { plan tests => $T }
