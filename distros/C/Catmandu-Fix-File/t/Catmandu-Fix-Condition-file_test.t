#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Catmandu::Fix::set_field;
use File::Basename;
use File::Temp qw(tempfile);

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition::file_test';
    use_ok $pkg;
}

my $pass_fixes = [Catmandu::Fix::set_field->new('test', 'pass')];
my $fail_fixes = [Catmandu::Fix::set_field->new('test', 'fail')];

{
    my $dir = dirname( __FILE__ );
    my $cond = $pkg->new('file','d');
    $cond->pass_fixes($pass_fixes);
    $cond->fail_fixes($fail_fixes);

    is_deeply $cond->fix({ file => $dir }), { file => $dir, test => 'pass' };
}
{
    my $dir = dirname( __FILE__ );
    my $cond = $pkg->new('file','f');
    $cond->pass_fixes($pass_fixes);
    $cond->fail_fixes($fail_fixes);

    is_deeply $cond->fix({ file => $dir }), { file => $dir, test => 'fail' };
}
{
    my $dir = dirname( __FILE__ );
    my $cond = $pkg->new('file','dr');
    $cond->pass_fixes($pass_fixes);
    $cond->fail_fixes($fail_fixes);

    is_deeply $cond->fix({ file => $dir }), { file => $dir, test => 'pass' };
}
{
    my $dir = dirname( __FILE__ );
    my $cond = $pkg->new('file','e');
    $cond->pass_fixes($pass_fixes);
    $cond->fail_fixes($fail_fixes);

    is_deeply $cond->fix({ file => $dir }), { file => $dir, test => 'pass' };
}
{
    my($fh,$file) = tempfile(UNLINK => 1,EXLOCK => 0);
    my $cond = $pkg->new('file','z');
    $cond->pass_fixes($pass_fixes);
    $cond->fail_fixes($fail_fixes);

    is_deeply $cond->fix({ file => $file }), { file => $file, test => 'pass' };
}
{
    my($fh,$file) = tempfile(UNLINK => 1,EXLOCK => 0);
    my $cond = $pkg->new('file','s');
    $cond->pass_fixes($pass_fixes);
    $cond->fail_fixes($fail_fixes);

    is_deeply $cond->fix({ file => $file }), { file => $file, test => 'fail' };
}

done_testing 7;
