#!perl
use strict;
use warnings;
use Test::More tests => 12;

use Array::PseudoScalar;

my $subclass      = Array::PseudoScalar->subclass(';');
my $schizophrenic = $subclass->new(qw/this is a pseudoscalar/);
my $schizo_num    = $subclass->new(qw/123/);

is("$subclass", 'Array::PseudoScalar::;', "subclass name");

is(scalar(@$schizophrenic), 4, "array size");
is($schizophrenic->[1], "is", "array member");

is(length($schizophrenic), 22, "string length");
ok($schizophrenic =~ /pseudo/, "regex match");
ok($schizophrenic."foo" =~ /pseudo.*foo/, "string concat");

splice @$schizophrenic, 3, 0, "nice";
ok($schizophrenic =~ /nice;pseudo/, "splice()");

$schizophrenic =~ s/this/that/;
is($schizophrenic, "that;is;a;nice;pseudoscalar", "regex subst");
eval{print @$schizophrenic};
ok($@, "no longer an array");

ok($schizo_num == 123, "num comparison");

my $subclass_again = Array::PseudoScalar->subclass(';');
is ($subclass_again, $subclass, "reused subclass");

my $other_subclass = Array::PseudoScalar->subclass('_');
my $foobar         = $other_subclass->new(qw/foo bar/);
is ($foobar, "foo_bar", "other subclass");

