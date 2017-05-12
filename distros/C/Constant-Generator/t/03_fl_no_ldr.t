#!perl

use strict;
use Test::More tests => 10;

BEGIN{
    use_ok('Constant::Generator');
}

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg17', [qw/const35 const36/], {
	    fl_exp  => 1,
	    fl_decl => 1,
	    fl_rev  => 1,
	    fl_no_load => 0,
	    fl_no_ldr  => 1,
	});
	ok(exists $INC{'TestPkg17.pm'}, '1_0 !fl_no_load but fl_no_ldr is set; awt. for $INC{$mod_fn} for successfull `use\'ing w/o loader');
    }

    BEGIN{
	ok((eval("ok(CONST35 == 1, \"test1\");"),$@=~/Bareword/oi), '1_1 fl_no_ldr');
    }
    use TestPkg17;
}
ok(CONST35 == 1, '2_1 fl_no_ldr');
ok(CONST36 == 2, '2_2 fl_no_ldr');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg18', [qw/const37 const38/], {
	    fl_exp => 1,
	    fl_decl => 1,
	    fl_rev => 1,
	    fl_no_load => 0,
	    fl_no_ldr  => 1,
	});
	ok(exists $INC{'TestPkg18.pm'}, '3_0 !fl_no_load but fl_no_ldr is set; awt. for $INC{$mod_fn} for successfull `use\'ing w/o loader');
    }

    BEGIN{
	ok((eval("ok(CONST37 == 1, \"test1\");"),$@=~/Bareword/oi), '3_1 fl_no_ldr');
	delete $INC{'TestPkg18.pm'};
    }
    ok((eval('use TestPkg18;') == undef and $@=~/Can\'t\s+locate/oi), '3_2 use not ok'); # Test::More isn't export `use_not_ok' directive :(
}
ok((eval("ok(CONST37 == 1, \"3_3 subtest\");"),$@=~/Bareword/oi), '3_3 no export constants');
ok(${TestPkg18::CONSTS}{CONST38} == 2, '3_3 but defined in pkg');
