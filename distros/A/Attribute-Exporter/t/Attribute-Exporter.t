#!/usr/bin/perl 

use strict;
no strict 'refs';
no warnings;

use FindBin;
use lib "$FindBin::Bin/.";
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../lib";

use Test::Simple tests => 23;

reload_module();

# first set of tests get the default exports
ok(defined(*{'t::test1'}{CODE}), 't::test1 is defined');
ok(defined(*{'main::test1'}{CODE}), 'main::test1 is defined');
ok(*{'::test1'}{CODE} == *{'t::test1'}{CODE}, 't exported test1 to main');
ok(!defined(*{'main::test2'}{CODE}), 'main::test2 is not defined');

# second set of tests specifies the imports
reload_module('test2');
ok(defined(*{'t::test2'}{CODE}), 't::test2 is defined');
ok(defined(*{'main::test2'}{CODE}), 'main::test2 is defined');
ok(*{'::test2'}{CODE} == *{'t::test2'}{CODE}, 't exported test2 to main');

# test scalar export
reload_module('$test5');
ok($main::test5 eq 'test5', 'scalar import ok');

# test tag export
reload_module(':test10_tag');
ok(defined(*{'t::test10'}{CODE}), 't::test10 is defined');
ok(defined(*{'main::test10'}{CODE}), 'main::test10 is defined');
ok(*{'::test10'}{CODE} == *{'t::test10'}{CODE}, 't exported test10 to main');
ok(test10() eq 'test10', 'test10 result OK');

$Attribute::Exporter::use_indirection = 1;

# test scalar export
reload_module('$test5');
ok($main::test5 eq 'test5', 'scalar indirection ok');
t->redefine('SCALAR', 'test5', 'test6');
ok($main::test5 eq 'test6', 'scalar indirection ok');

# third set of tests does the right thing if an exported symbol is redefined
reload_module(':DEFAULT', 'test4');
ok(t::test3() eq 'test3', 't::test3 produces string test3');
ok(test1() eq 'test1', 'test1 produces string test1');
t->redefine('CODE', 'test1', 'test3');
ok(t::test1() eq 'test3', 't::test1() produces string test3');
ok(test1() eq 'test3', 'main::test1() produces string test3');

# we require that indirect exports retain the ability to be passed arguments,
# don't laugh, my first version couldn't do this.
ok(test4('test4') eq 'test4', 'indirect accepts arguments');

# regex exports
reload_module('$test7');
ok(defined($main::test7), 'can export a regex');
ok('bar foo bar' =~ m/$main::test7/, 'exported regex is usable');

$Attribute::Exporter::use_indirection = 0;

# constant exports
reload_module();
ok(test8() eq 'test8', 'imported constant test8() == "test8"');
ok(test9() eq 'test9', 'imported constant test9() == "test9"');

sub reload_module {
    delete $INC{'t.pm'};
    require 't.pm';
    t->import(@_);
}
