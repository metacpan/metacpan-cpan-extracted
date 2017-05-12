#!/usr/bin/perl

=head1 NAME

00_base.t - Test functionality of autorole.

=cut

use strict;
use warnings;
use Test::More tests => 52;

{
    package Foo;
    sub foo { 'foo' }
    sub bar { 'bar' }
    sub baz { 'baz' }
    $INC{'Foo.pm'} = 'internal load';
}

###----------------------------------------------------------------###
# test compile options

my $use = "use AutoRole 'FooPackageThatDoesNotExist'";
ok(!eval "package A0; $use; 1", "A0 - $use - can't compile time load non-existant package");

$use = "use AutoRole Foo => qr{^z}";
ok(!eval "package A00; $use; 1", "A00 - $use - can't with no methods");

$use = "use AutoRole Foo => 'bar'; use AutoRole Foo => 'bar'";
ok(!eval "package A000; $use; 1", "A000 - $use - can't load conflicting method names");

$use = "use AutoRole 'Foo'";
ok(eval "package A1; $use; 1", "A1 Loaded - $use") || diag "$@";
ok(defined(&A1::foo) && defined(&A1::bar) && defined(&A1::baz), "A1 Loaded correct subs");

$use = "use AutoRole Foo => '*'";
ok(eval "package A2; $use; 1", "A2 Loaded - $use") || diag "$@";
ok(defined(&A2::foo) && defined(&A2::bar) && defined(&A2::baz), "A2 Loaded correct subs");

$use = "use AutoRole Foo => qr{.}";
ok(eval "package A3; $use; 1", "A3 Loaded - $use") || diag "$@";
ok(defined(&A3::foo) && defined(&A3::bar) && defined(&A3::baz), "A3 Loaded correct subs");

$use = "use AutoRole Foo => 'compile'";
ok(eval "package A4; $use; 1", "A4 Loaded - $use") || diag "$@";
ok(defined(&A4::foo) && defined(&A4::bar) && defined(&A4::baz), "A4 Loaded correct subs");

$use = "use AutoRole Foo => 'compile' => '*'";
ok(eval "package A5; $use; 1", "A5 Loaded - $use") || diag "$@";
ok(defined(&A5::foo) && defined(&A5::bar) && defined(&A5::baz), "A5 Loaded correct subs");

$use = "use AutoRole Foo => {'*' => 1}";
ok(eval "package A6; $use; 1", "A6 Loaded - $use") || diag "$@";
ok(defined(&A6::foo) && defined(&A6::bar) && defined(&A6::baz), "A6 Loaded correct subs");

$use = "use AutoRole Foo => {'*' => qr{.}}";
ok(eval "package A7; $use; 1", "A7 Loaded - $use") || diag "$@";
ok(defined(&A7::foo) && defined(&A7::bar) && defined(&A7::baz), "A7 Loaded correct subs");

$use = "use AutoRole Foo => qr{^b}";
ok(eval "package A8; $use; 1", "A8 Loaded - $use") || diag "$@";
ok(!defined(&A8::foo) && defined(&A8::bar) && defined(&A8::baz), "A8 Loaded correct subs");

$use = "use AutoRole Foo => qr{^(?!f)}";
ok(eval "package A9; $use; 1", "A9 Loaded - $use") || diag "$@";
ok(!defined(&A9::foo) && defined(&A9::bar) && defined(&A9::baz), "A9 Loaded correct subs");

$use = "use AutoRole Foo => qr{^b} => qr{^f}";
ok(eval "package A10; $use; 1", "A10 Loaded - $use") || diag "$@";
ok(defined(&A10::foo) && defined(&A10::bar) && defined(&A10::baz), "A10 Loaded correct subs");

$use = "use AutoRole Foo => {'*' => [qr{^b}, qr{^f}]}";
ok(eval "package A11; $use; 1", "A11 Loaded - $use") || diag "$@";
ok(defined(&A11::foo) && defined(&A11::bar) && defined(&A11::baz), "A11 Loaded correct subs");

$use = "use AutoRole Foo => {bar => 'BAR', '*' => 1}";
ok(eval "package A12; $use; 1", "A12 Loaded - $use") || diag "$@";
ok(defined(&A12::foo) && !defined(&A12::bar) && defined(&A12::BAR) && defined(&A12::baz), "A12 Loaded correct subs");

$use = "use AutoRole Foo => 'autorequire' => 'foo'";
ok(eval "package A13; $use; 1", "A13 Loaded - $use") || diag "$@";
ok(defined(&A13::foo) && !defined(&A13::bar) && !defined(&A13::baz), "A13 Loaded correct subs");
is(\&A13::foo, \&Foo::foo, "A13 - correctly used compile since module was already loaded");

###----------------------------------------------------------------###
# test autorequire options

$use = "use AutoRole BarPackageThatDoesNotExist => 'autorequire' => 'bar'";
ok(eval "package B0; $use; 1", "B0 Loaded - but doesn't reference real module") || diag "$@";
ok(defined(&B0::bar), "B0 Loaded correct subs");
ok(! eval { B0::bar(); 1 } && $@, "B0 - died at runtime because method wasn't found");

$use = "use AutoRole Bar => 'autorequire' => 'bar'";
ok(eval "package B1; $use; 1", "B1 Loaded - $use") || diag "$@";
ok(defined(&B1::bar), "B1 Loaded correct subs");

$use = "use AutoRole Bar => 'bar'";
ok(eval "package B2; $use; 1", "B2 Loaded - $use") || diag "$@";
ok(defined(&B2::bar), "B2 Loaded correct subs");

$use = "use AutoRole Bar => ['bar', 'foo']";
ok(eval "package B3; $use; 1", "B3 Loaded - $use") || diag "$@";
ok(defined(&B3::foo) && defined(&B3::bar), "B3 Loaded correct subs");

$use = "use AutoRole Bar => {bar => 1, foo => 1}";
ok(eval "package B4; $use; 1", "B4 Loaded - $use") || diag "$@";
ok(defined(&B4::foo) && defined(&B4::bar), "B4 Loaded correct subs");

$use = "use AutoRole Bar => {bar => ['bar', 'foo']}";
ok(eval "package B5; $use; 1", "B5 Loaded - $use") || diag "$@";
ok(defined(&B5::foo) && defined(&B5::bar), "B5 Loaded correct subs");

$use = "use AutoRole Bar => {bar => ['bar', 'foo']}";
ok(eval "package B6; $use; 1", "B6 Loaded - $use") || diag "$@";
ok(defined(&B6::foo) && defined(&B6::bar), "B6 Loaded correct subs");

###----------------------------------------------------------------###
# test autoload options

$use = "use AutoRole BazPackageThatDoesNotExist => 'autoload' => 'bar'";
ok(eval "package C0; $use; 1", "C0 Loaded - but doesn't reference real module") || diag "$@";
ok(!defined(&C0::bar), "C0 Loaded correct subs");
ok(! eval { C0::bar(); 1 } && $@, "C0 - died at runtime because method wasn't found");

{
    local $INC{'Test/More.pm'};
    $use = "use AutoRole 'Test::More' => 'autoload' => 'ok'";
    ok(eval "package C1; $use; 1", "C1 Loaded - $use") || diag "$@";
    ok(!defined(&C1::ok), "C1 Loaded correct subs");
    eval { C1::ok(1, "C1 - ok") } || ok(0, "C1 - was not ok $@");
    is(\&C1::ok, \&Test::More::ok, "C1 - Autoload correctly moved file into place");
}
