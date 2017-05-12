#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 10;
use FindBin '$Bin';
use File::Spec;
use DateTime;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    use_ok ( 'Build::Daily' ) or exit;
}

exit main();

sub main {
    chdir(File::Spec->catdir($Bin, 'mb')) or die $!;
    my $ymd = DateTime->now('time_zone' => 'local')->ymd("");

    my $builder = module_build('lib/Build/Daily/t/mb.pm');
    my $mm = extutils_mm('lib/Build/Daily/t/mb.pm');
    is($builder->dist_version, '1.01.01_'.$ymd, 'today mb build version variant 1');
    is($mm->{'VERSION'}, '1.01.01_'.$ymd, 'today mm build version variant 1');
    
    $builder = module_build('lib/Build/Daily/t/mb2.pm');
    $mm = extutils_mm('lib/Build/Daily/t/mb2.pm');
    is($builder->dist_version, '1.01.01_03'.$ymd, 'today mb build version variant 2');
    is($mm->{'VERSION'}, '1.01.01_03'.$ymd, 'today mm build version variant 2');
    
    $builder = module_build('lib/Build/Daily/t/mb3.pm');
    $mm = extutils_mm('lib/Build/Daily/t/mb3.pm');
    is($builder->dist_version, '1.01.01_30'.$ymd, 'today mb build version variant 3');
    is($mm->{'VERSION'}, '1.01.01_30'.$ymd, 'today mm build version variant 3');
    

    eval 'use Build::Daily "version" => 12345;';
    $builder = module_build('lib/Build/Daily/t/mb3.pm');
    $mm = extutils_mm('lib/Build/Daily/t/mb3.pm');
    is($builder->dist_version, '1.01.01_3012345', 'forced mb build version');
    is($mm->{'VERSION'}, '1.01.01_3012345', 'forced mb version');
    
    
    return 0;
}

sub module_build {
    my $filename = shift;
    die 'require argument'
        if not $filename;
    
    local *STDOUT;
    open STDOUT, '>', File::Spec->devnull;
    return Module::Build->new(
        module_name         => 'Foo::Bar',
        license             => 'perl',
        dist_author         => 'fantomas',
        dist_version_from   => $filename,
        build_requires => {
            'Test::More' => 0,
        },
        add_to_cleanup      => [ 'Build-Daily-t-mb*' ],
    );
}

sub extutils_mm {
    my $filename = shift;

    return ExtUtils::MakeMaker::WriteMakefile(
        NAME                => 'Foo::Bar',
        AUTHOR              => 'fantomas',
        VERSION_FROM        => $filename,
        PL_FILES            => {},
        PREREQ_PM => {
            'Test::More' => 0,
        },
        dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
        clean               => { FILES => 'Foo-Bar-*' },
    );
}

no warnings 'redefine';
package ExtUtils::MakeMaker;
sub flush { return; }
