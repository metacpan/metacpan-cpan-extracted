#!perl

use strict;
use Test::More tests => 9;
use File::Temp qw'tempdir';

BEGIN{
    use_ok('Constant::Generator');
}

my $tdir;
BEGIN{
    BEGIN{
	$tdir = tempdir(CLEANUP => 1, DIR => '/tmp/');
	Constant::Generator::gen('TestPkg21', [qw/const43 const44/], {
	    fl_exp => 1,
	    fl_decl => 1,
	    fl_rev => 1,
	    fl_no_load => 0,
	    fl_no_ldr  => 1,
	    fl_no_inc_stub => 1,
	});
	ok(!defined $INC{'TestPkg21.pm'}, '1 fl_no_inc_stub (no fl_no_load but both fl_no_ldr and fl_no_inc_stub set)');
	ok(ref $INC[0] ne 'CODE', '2 fl_no_inc_stub');
	ok((eval('use TestPkg21;') == undef and $@=~/Can\'t\s+locate/oi), '3 fl_no_inc_stub; can\'t load');
    }
    ok((eval("ok(CONST43 == 1, \"4 subtest\");"),$@=~/Bareword/oi), '4 no export constants');
    ok(${TestPkg21::CONSTS}{CONST44} == 2, '5 but defined in pkg');
}

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg22', [qw/const45 const46/], {
	    fl_exp => 1,
	    fl_decl => 1,
	    fl_rev => 1,
	    fl_no_load => 0,
	    fl_no_ldr  => 1,
	    fl_no_inc_stub => 1,
	    fl_exp2file => 1,
	    root_dir => $tdir,
	});
	unshift @INC, $tdir;
    }
    use TestPkg22;
}
ok(CONST45 == 1, '1 test module export');
open my $fh, "< $tdir/TestPkg22.pm";
my $s = join '',<$fh>;
close $fh;
ok($s=~/package\s+TestPkg22/oi, 'verify source');

my $src;
sub sub1{
    $src = $_[0];
};

BEGIN{
    BEGIN{
	Constant::Generator::gen('TestPkg23', [qw/const47 const48/], {
	    fl_exp => 1,
	    fl_decl => 1,
	    fl_rev => 1,
	    fl_no_load => 1,
	    fl_no_ldr  => 1,
	    fl_no_inc_stub => 1,
	    fl_exp2file => 0,
	    root_dir => $tdir,
	    sub_post_src => \&sub1,
	});
    }
}
ok($src=~/package\s+TestPkg23.*use\s+constant/oi, 'sub_post_src test');
