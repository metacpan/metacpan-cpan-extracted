#!perl

use strict;
use Test::More tests => 12;

BEGIN{
    use_ok('Constant::Generator');
}

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg19', [qw/const39 const40/], {
	    fl_exp => 1,
	    fl_decl => 1,
	    fl_rev => 1,
	    fl_no_load => 0,
	    fl_no_ldr  => 1,
	    fl_no_inc_stub => 1,
	});
	ok(!defined $INC{'TestPkg19.pm'}, '1 fl_no_inc_stub (no fl_no_load but both fl_no_ldr and fl_no_inc_stub set)');
	ok(ref $INC[0] ne 'CODE', '2 fl_no_inc_stub');
	ok((eval('use TestPkg19;') == undef and $@=~/Can\'t\s+locate/oi), '2 fl_no_inc_stub; can\'t load');
    }
    ok((eval("ok(CONST40 == 1, \"3_3 subtest\");"),$@=~/Bareword/oi), '3_3 no export constants');
    ok(${TestPkg19::CONSTS}{CONST40} == 2, '3_3 but defined in pkg');
}

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg20', [qw/const41 const42/], {
	    fl_exp => 1,
	    fl_decl => 1,
	    fl_rev => 1,
	    fl_no_load => 1,
	    fl_no_ldr  => 1,
	});
	ok(!defined $INC{'TestPkg20.pm'}, '1 only src (set fl_no_load and fl_no_ldr and fl_no_inc_stub)');
	ok(ref $INC[0] ne 'CODE', '2 only src');
    }
    ok((eval('use TestPkg20;') == undef and $@=~/Can\'t\s+locate/oi), '2 no way to load src');
}
ok((eval("ok(CONST42 == 1, \"3 subtest\");"),$@=~/Bareword/oi), '3 no export constants');
ok(!defined ${TestPkg20::CONSTS}->{CONST42}, '4 and not defined in pkg');
ok((${Constant::Generator::GEN}{'TestPkg20.pm'}=~/package\s+TestPkg20/oi), '5 source defined here');
