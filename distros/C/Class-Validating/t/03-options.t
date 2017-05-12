#!perl
# $Id: 03-options.t 2 2005-01-04 22:00:06Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 9);
BEGIN { use_ok("Class::Validating") }

package Parent;
use Class::Validating;
__PACKAGE__->set_pv_spec(foo => [1]);
__PACKAGE__->set_pv_spec(bar => { arg1 => { type => Params::Validate::HASHREF() }});
sub foo { shift->validate_args(\@_, { called => "fooie" }) }
sub bar { shift->validate_args(\@_, { called => "barie" }) }

package Child;
our @ISA = ('Parent');
__PACKAGE__->set_pv_spec(foo => [{type => Params::Validate::HASHREF()}]);
__PACKAGE__->set_pv_spec(bar => { arg1 => {type => Params::Validate::HASHREF()},
    arg2 => {type => Params::Validate::ARRAYREF() }});

package main;

eval{Parent->foo(1)};
ok(!$@, "Correct usage (validate_pos)");
eval{Parent->foo(1,2)};
ok($@ =~ /fooie/, "Incorrect usage (validate_pos)");

eval{Parent->bar(arg1 => {})};
ok(!$@, "Correct usage (validate)");
eval{Parent->bar(arg1 => [])};
ok($@ =~ /barie/, "Incorrect usage (validate)");

eval{Child->foo({})};
ok(!$@, "Correct usage (overriden spec, validate_pos)");
eval{Child->foo(1)};
ok($@ =~ /fooie/, "Incorrect usage (overriden spec, validate_pos)");

eval{Child->bar(arg1 => {}, arg2 => [])};
ok(!$@, "Correct usage (validate)");
eval{Child->bar(arg1 => [])};
ok($@ =~ /barie/, "Incorrect usage (validate)");

