#!/usr/bin/perl

use warnings;
use strict;

use t::Utils;
use Class::DOES;

my $T;

my @warns;
$SIG{__WARN__} = sub { push @warns, $_[0] };

my $PKG = "TestAAAA";

sub doimport {
    my $warn = shift;
    my $args = join ",", map qq{"\Q$_\E"}, @_;
    my $B = Test::More->builder;

    $warn = $warn ? "" : "no warnings 'Class::DOES';";

    @warns = ();
    eval qq{
        package t::$PKG;
        $warn;
        Class::DOES->import($args);
    };
}

sub inherit {
    no strict "refs";
    @{"t\::$PKG\::ISA"} = @_;
}

sub got_warns {
    my ($warns, $name) = @_;
    my $B = Test::More->builder;
    $B->is_num(scalar @warns, $warns, $name)
        or $B->diag(join "\n", @warns);
}

BEGIN { $T += 2 }

doimport 1;
got_warns 0,                            "empty import doesn't warn";

doimport 1, "Foo::Bar";
got_warns 0,                            "correct import doesn't warn";

BEGIN { $T += 7 }

$PKG++;
doimport 1;
{
    no strict "refs";
    ${"t::$PKG\::DOES"}{"Foo::Bar"} = 0;
}
does_ok "t::$PKG", "Foo::Bar", 1,       "false value in \%DOES replaced";
got_warns 1,                            "...with warning";
like $warns[0], qr/\$t::$PKG\::DOES\{Foo::Bar\} is false/,
                                        "...correctly";

@warns = ();
{
    no warnings "Class::DOES";
    "t::$PKG"->DOES("Foo::Bar");
}
got_warns 0,                            "warning can be disabled";

{
    package t::False;
    # shut up with your 'used only once'
    no warnings;
    our %DOES = ("Foo::Bar" => 0);
}

$PKG++;
inherit "t::False";
doimport 1;
does_ok "t::$PKG", "Foo::Bar", 1,       "false value in inherited \%DOES";
got_warns 1,                            "...with warning";
like $warns[0], qr/\$t::False::DOES\{Foo::Bar\}/,
                                        "...correctly";

BEGIN { $T += 3 }

{
    package t::Does;
    sub DOES { 1 }
}

$PKG++;
inherit "t::Does";
doimport 1;
got_warns 1,                            "bad ->DOES warns";
like $warns[0], qr/t::$PKG.*incompatible ->DOES/,
                                        "...correctly";

$PKG++;
inherit "t::Does";
doimport 0;
got_warns 0,                            "warning can be disabled";

BEGIN { $T += 1 }

{
    package t::MyDoes;
    use Class::DOES;
}

$PKG++;
inherit "t::MyDoes";
doimport 1;
got_warns 0,                            "my ->DOES doesn't warn";

BEGIN { $T += 3 }

{
    package t::Isa;
    sub isa { 1 }
}

$PKG++;
inherit "t::Isa";
doimport 1;
got_warns 1,                            "bad ->isa warns";
like $warns[0], qr/t::$PKG doesn't use \@ISA/,
                                        "...correctly";

$PKG++;
inherit "t::Isa";
doimport 0;
got_warns 0,                            "warning can be disabled";

BEGIN { plan tests => $T }
