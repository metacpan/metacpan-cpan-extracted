#!perl

use strict;
use Test::More tests => 40;

BEGIN{
    use_ok('Constant::Generator');
}

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg1', [qw/const1 const2/]);
    }
    use TestPkg1;
}

ok(TestPkg1::CONST1 == 1, '1 base gen w/o exports');
ok(TestPkg1::CONST2 == 2, '2 base gen w/o exports');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg2', [qw/const3 const4/], {fl_exp => 1});
    }
    use TestPkg2;
}
ok(CONST3 == 1, '1 export');
ok(CONST4 == 2, '2 export');

BEGIN{
    BEGIN{
	Constant::Generator::generate('TestPkg3', [qw/const5 const6/], {fl_exp_ok => 1});

    }
    use TestPkg3;
}
ok(eval("ok(CONST5 == 1, '1_1 export test');") == undef, '1_1 export_ok');
ok(eval("ok(CONST6 == 2, '1_2 export test');") == undef, '1_2 export_ok');

BEGIN{
    BEGIN{
	Constant::Generator::generate('TestPkg4', [qw/const7 const8 const9 const10/], {fl_exp_ok => 1});
    }
    use TestPkg4 qw'CONST8 CONST10';
}
ok(eval("ok(CONST7 == 1, '2_1 export test');") == undef, '2_1 export_ok');
ok(CONST8 == 2, '2_2 export_ok');
ok(eval("ok(CONST9 == 2, '2_3 export test');") == undef, '2_3 export_ok');
ok(CONST10 == 4, '2_4 export_ok');

BEGIN{
    BEGIN{
	Constant::Generator::gen('JohnLennon', [qw/make_love not_war/], {
	    fl_exp => 1,
	    prfx => 'KEYWORD_',
	});
    }
    use JohnLennon;
}
ok(KEYWORD_MAKE_LOVE == 1, 'John');
ok(KEYWORD_NOT_WAR == 2, 'Lennon');

BEGIN{
    BEGIN{
	Constant::Generator::gen('Int0Test', [qw/int0_0 int0_1 int0_2/], {
	    int0 => -1,
	    fl_exp => 1,
	    prfx => 'CONST_',
	});
    }
    use Int0Test;
}

ok(CONST_INT0_0 == -1, 'int0_0');
ok(CONST_INT0_1 == 0, 'int0_1');
ok(CONST_INT0_2 == 1, 'int0_2');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg5', [qw/const11 const12/], {
	    fl_exp => 1,
	    sub => sub{($_[0]<<2)}
	});
    }
    use TestPkg5;
}
ok(CONST11 == 4, '1 sub');
ok(CONST12 == 8, '2 sub');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg6', [qw/const13 const14/], {
	    fl_exp => 1,
	    sub => sub{($_[0]<<2).'_A'},
	});
    }
    use TestPkg6;
}
ok(CONST13 eq '4_A', '1 sub bareword test');
ok(CONST14 eq '8_A', '2 sub bareword test');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg7', [qw/const15 const16/], {
	    fl_exp => 1,
	    sub => sub{'B_'.($_[0]<<2).'_A'}
	});
    }
    use TestPkg7;
}
ok(CONST15 eq 'B_4_A', '3 sub bareword test');
ok(CONST16 eq 'B_8_A', '4 sub bareword test');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg8', [qw/const17 const18/], {
	    fl_exp => 1,
	    sub => sub{'9_'.($_[0]<<2).'_A'}
	});
    }
    use TestPkg8;
}
ok(CONST17 eq '9_4_A', '5 sub bareword test');
ok(CONST18 eq '9_8_A', '6 sub bareword test');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg9', [qw/const19 const20/], {
	    fl_exp => 1,
	    sub => sub{'5_000_'.($_[0]<<7).'_000'} # due to warns under $] < 5.007003; commit/928753ea20dfcc4327533c22eecccbc215e82fee
	});
    }
    use TestPkg9;
}
ok(CONST19 eq '5000128000', '7 sub v-string test');
ok(CONST20 eq '5000256000', '8 sub v-string test');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg10', [qw/const21 const22/], {
	    fl_exp => 1,
	    sub => sub{'0xF'.($_[0]<<2)}
	});
    }
    use TestPkg10;
}
ok(CONST21 == 0xF4, '9 sub hex-string test');
ok(CONST22 == 0xF8, '10 sub hex-string test');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg11', [qw/const23 const24/], {
	    fl_exp => 1,
	    sub => sub{'0x01'.($_[0]<<2)}
	});
    }
    use TestPkg11;
}
ok(CONST23 == 20, '9 sub octal-string test');
ok(CONST24 == 24, '10 sub octal-string test');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg12', [qw/const25 const26/], {
	    fl_exp => 1,
	    fl_decl => 1
	});
    }
    use TestPkg12;
}
ok(${TestPkg12::CONSTS}{CONST25} == 1, '1 fl_decl');
ok(${TestPkg12::CONSTS}{CONST26} == 2, '2 fl_decl');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg13', [qw/const27 const28/], {
	    fl_exp => 1,
	    sub => sub{'5_'.($_[0]<<2).'_X'},
	    fl_decl => 1
	});
    }
    use TestPkg13;
}
ok(${TestPkg13::CONSTS}{CONST27} eq '5_4_X', '1 fl_decl bareword');
ok(${TestPkg13::CONSTS}{CONST28} eq '5_8_X', '2 fl_decl bareword');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg14', [qw/const29 const30/], {
	    fl_exp => 1,
	    fl_decl => 0,
	    fl_rev => 1,
	});
    }
    use TestPkg14;
}
ok(${TestPkg14::STSNOC}{1} eq 'CONST29', '1 fl_rev');
ok(${TestPkg14::STSNOC}{2} eq 'CONST30', '2 fl_rev');


BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg15', [qw/const31 const32/], {
	    fl_exp => 1,
	    sub => sub{'5_'.($_[0]<<2).'_X'},
	    fl_rev => 1
	});
    }
    use TestPkg15;
}
ok(${TestPkg15::STSNOC}{'5_4_X'} eq 'CONST31', '1 fl_rev bareword');
ok(${TestPkg15::STSNOC}{'5_8_X'} eq 'CONST32', '2 fl_rev bareword');

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg16', [qw/const33 const34/], {
	    fl_exp => 1,
	    fl_decl => 1,
	    fl_rev => 1,
	    prfx => 'CONST_',
	    sub_dcrtr => sub{ # `rot13-decorator'
	    	my $a = $_[0]; $a=~tr/a-zA-Z/n-za-mN-ZA-M/; $a;
	    },
	});
    }
    use TestPkg16;
}

ok(pbafg33 == 1, '1 verify const33');
ok(pbafg34 == 2, '2 verify const34');
