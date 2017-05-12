#!perl -T

use Test::More qw/no_plan/;

package TestIt;
use base 'Class::Accessor::Contextual';
TestIt->mk_accessors(qw/animals soundmap/);

package main;

my $obj = TestIt->new();
$obj->animals([qw/pig horse cow/]);

my @got = $obj->animals;

is_deeply \@got, [qw/pig horse cow/], "got array";

my $got = join ' ',$obj->animals;

is $got, "pig horse cow", "got joined array";

$obj->soundmap({ pig => "oink", cow => "moo" });
my %got = $obj->soundmap;

is_deeply \%got, { pig => "oink", cow => "moo" }, "got hash";


1;


