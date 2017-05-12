#!/usr/bin/perl

use warnings;
use strict;

use t::Utils;
my $T;

{
    package t::Class;
}

{
    package t::Base;

    our @ISA = qw/t::Class/;

    use Class::DOES qw/Some::Role Some::Other::Role/;
}

{
    package t::OtherBase;

    use Class::DOES "Third::Role";
}

{
    package t::SI;

    our @ISA = qw/t::Base/;
}

{
    package t::MI;

    our @ISA = qw/t::Base t::OtherBase/;
}

{
    package t::Diamond;

    our @ISA = qw/t::SI t::MI/;
}

my %obj = map +($_ => bless [], $_),
    qw/t::Base t::OtherBase t::SI t::MI t::Diamond/;

BEGIN { $T += 5 * 2 }

for (keys %obj) {
    ok eval { $_->can("DOES") },        "$_ can DOES";
    ok eval { $obj{$_}->can("DOES") },  "$_ object can DOES";
}

BEGIN { $T += 5 * 4 }

for ("t::Base", $obj{"t::Base"}, "t::SI", $obj{"t::SI"}) {
    does_ok $_, "t::Base";
    does_ok $_, "t::Class";
    does_ok $_, "UNIVERSAL";
    does_ok $_, "Some::Role";
    does_ok $_, "Some::Other::Role";
}

BEGIN { $T += 2 }

does_ok "t::SI", "t::SI";
does_ok $obj{"t::SI"}, "t::SI";

BEGIN { $T += 8 * 4 }

for ("t::MI", $obj{"t::MI"}, "t::Diamond", $obj{"t::Diamond"}) {
    does_ok $_, "t::MI";
    does_ok $_, "t::Base";
    does_ok $_, "t::Class";
    does_ok $_, "t::OtherBase";
    does_ok $_, "UNIVERSAL";
    does_ok $_, "Some::Role";
    does_ok $_, "Some::Other::Role";
    does_ok $_, "Third::Role";
}

BEGIN { $T += 2 }

{
    package t::Use;
    use Class::DOES qw/Foo::Bar/;
}

{
    package t::Hash;
    use Class::DOES;
    our %DOES = ( "Foo::Bar" => 2.56 );
}

is $t::Use::DOES{"Foo::Bar"}, 1,        "importing sets \%DOES";
does_ok "t::Hash", "Foo::Bar", 2.56,    "setting \%DOES implements role";

BEGIN { plan tests => $T }
