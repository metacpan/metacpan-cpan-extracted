#!perl

use strict;
use Test::More tests => 3;

BEGIN{
    use_ok('Constant::Generator');
}

my ($src1, $src2);
BEGIN{
    Constant::Generator::gen('TestPkg1', [qw/const1 const2/], {fl_no_load => 1, sub_post_src => sub{ $src1=shift }});
    Constant::Generator::gen('TestPkg2', [qw/const3 const4/], {fl_no_load => 1, sub_post_src => sub{ $src2=shift }});

    my $str = 'package TestPkg2;';
    substr($src2, index($src2, $str) + length($str), 0, ' use TestPkg1; ');

    $Constant::Generator::GEN{'TestPkg2.pm'} = $src2;
}

use TestPkg2;

ok((TestPkg1::CONST1 == 1 && TestPkg2::CONST3 == TestPkg1::CONST1), '1 base gen w/o exports');
ok((TestPkg1::CONST2 == 2 && TestPkg2::CONST4 == TestPkg1::CONST2), '2 base gen w/o exports');
