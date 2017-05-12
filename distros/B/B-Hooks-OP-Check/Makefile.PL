use 5.008001;
use strict;
use warnings;


use inc::Module::Install;
use ExtUtils::Depends;

name 'B-Hooks-OP-Check';
all_from 'lib/B/Hooks/OP/Check.pm';

requires 'parent';
configure_requires 'ExtUtils::Depends' => 0.302; #minimum version that works on Win32+gcc
test_requires 'Test::More';

my $pkg = ExtUtils::Depends->new('B::Hooks::OP::Check');
$pkg->install('hook_op_check.h');
$pkg->add_xs('Check.xs');
$pkg->add_pm('lib/B/Hooks/OP/Check.pm' => '$(INST_LIB)/B/Hooks/OP/Check.pm');

mkdir 'build';
$pkg->save_config('build/IFiles.pm');

makemaker_args(
    $pkg->get_makefile_vars,
    FUNCLIST => [qw/hook_op_check hook_op_check_remove/],
    DL_FUNCS => { 'B::Hooks::OP::Check' => [] },
    dist => { PREOP => 'pod2text lib/B/Hooks/OP/Check.pm > $(DISTVNAME)/README' },
);

repository 'git://lake.fysh.org/zefram/B-Hooks-OP-Check.git';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=B-Hooks-OP-Check';

extra_tests;

WriteAll;
