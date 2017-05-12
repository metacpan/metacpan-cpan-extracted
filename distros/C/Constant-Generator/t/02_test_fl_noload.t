#!perl

use strict;
use Test::More tests => 11;

BEGIN{
    use_ok('Constant::Generator');
}

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg16', [qw/const33 const34/], {
	    fl_exp => 1,
	    fl_decl => 1,
	    fl_rev => 1,
	    fl_no_load => 1
	});
	ok(ref(${TestPkg16::CONSTS}) == undef, '1 fl_no_load');
	ok(ref(${TestPkg16::STSNOC}) == undef, '2 fl_no_load');
	ok($INC{'TestPkg16.pm'} == undef, '3 fl_no_load');
	ok(($INC[0]->('TestPkg16.pm')->(),$_)=~/package\s+TestPkg16/o, '5 fl_no_load');
    }

    use_ok('TestPkg16');
}

ok((keys %{TestPkg16::CONSTS}) == 2, '1 fl_no_load test loader');
ok((keys %{TestPkg16::STSNOC}) == 2, '2 fl_no_load test loader');
ok((ref $INC{'TestPkg16.pm'} eq 'CODE') || ($INC{'TestPkg16.pm'}=~m[ /loader/0x[0-9A-Fa-f]+/TestPkg16\.pm ]ox), '3 fl_no_load test loader');
ok(CONST34 == 2, '4 fl_no_load; test loader');
ok((keys %{TestPkg16::STSNOC}) == 2, '5 fl_no_load; test loader');
