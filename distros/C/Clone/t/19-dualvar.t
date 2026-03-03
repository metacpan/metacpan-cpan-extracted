use strict;
use warnings;
use Test::More;
use Clone qw(clone);

BEGIN {
    eval { require Scalar::Util; Scalar::Util->import(qw(dualvar)); 1 }
        or plan skip_all => "Scalar::Util required for dualvar tests";
}

# --- Basic dualvar cloning ---
{
    my $d = dualvar(42, "forty-two");
    my $c = clone(\$d);

    is($$c + 0,  42,          "dualvar: numeric value preserved");
    is("$$c",    "forty-two", "dualvar: string value preserved");
}

# --- Dualvar in hash ---
{
    my %h = (
        errno => dualvar(2, "No such file or directory"),
        ok    => dualvar(0, "success"),
    );
    my $c = clone(\%h);

    is($c->{errno} + 0,  2,                              "dualvar in hash: numeric");
    is("$c->{errno}",    "No such file or directory",     "dualvar in hash: string");
    is($c->{ok} + 0,     0,                              "dualvar zero: numeric");
    is("$c->{ok}",       "success",                       "dualvar zero: string");
}

# --- Dualvar in array ---
{
    my @a = (dualvar(1, "one"), dualvar(2, "two"));
    my $c = clone(\@a);

    is($c->[0] + 0, 1,     "dualvar in array [0]: numeric");
    is("$c->[0]",   "one", "dualvar in array [0]: string");
    is($c->[1] + 0, 2,     "dualvar in array [1]: numeric");
    is("$c->[1]",   "two", "dualvar in array [1]: string");
}

# --- Dualvar independence ---
{
    my $d = dualvar(10, "ten");
    my $ref = \$d;
    my $c = clone($ref);

    # Mutate clone
    $$c = dualvar(20, "twenty");
    is($$ref + 0,  10,    "original dualvar unchanged after clone mutation");
    is("$$ref",    "ten", "original dualvar string unchanged");
}

# --- Blessed dualvar ---
{
    package DualClass;
    sub new {
        my ($class, $num, $str) = @_;
        my $dv = Scalar::Util::dualvar($num, $str);
        bless \$dv, $class;
    }

    package main;
    my $obj = DualClass->new(99, "ninety-nine");
    my $c   = clone($obj);

    isa_ok($c, "DualClass", "blessed dualvar: class preserved");
    is($$c + 0, 99,            "blessed dualvar: numeric preserved");
    is("$$c",   "ninety-nine", "blessed dualvar: string preserved");
    isnt($c, $obj,             "blessed dualvar: distinct object");
}

# --- NV (float) dualvar ---
{
    my $d = dualvar(3.14, "pi");
    my $c = clone(\$d);

    cmp_ok(abs($$c - 3.14), '<', 0.001, "float dualvar: numeric preserved");
    is("$$c", "pi",                      "float dualvar: string preserved");
}

# --- Large integer dualvar ---
{
    my $d = dualvar(2**32, "big");
    my $c = clone(\$d);

    is($$c + 0, 2**32, "large int dualvar: numeric preserved");
    is("$$c",   "big", "large int dualvar: string preserved");
}

# --- Edge: dualvar with empty string ---
{
    my $d = dualvar(0, "");
    my $c = clone(\$d);

    is($$c + 0, 0,  "dualvar(0, ''): numeric preserved");
    is("$$c",   "", "dualvar(0, ''): empty string preserved");
}

done_testing;
