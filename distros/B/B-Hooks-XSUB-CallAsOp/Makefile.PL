use 5.008001;
use strict;
use warnings;


use inc::Module::Install 0.91;
use ExtUtils::Depends;

name 'B-Hooks-XSUB-CallAsOp';
all_from 'lib/B/Hooks/XSUB/CallAsOp.pm';

requires 'parent';
configure_requires 'ExtUtils::Depends' => 0.302; #minimum version that works on Win32+gcc
test_requires 'Test::More';
test_requires 'Test::use::ok';

my $pkg = ExtUtils::Depends->new('B::Hooks::XSUB::CallAsOp');
$pkg->install('hook_xsub_callasop.h');
$pkg->add_xs('CallAsOp.xs');
$pkg->add_pm('lib/B/Hooks/XSUB/CallAsOp.pm' => '$(INST_LIB)/B/Hooks/XSUB/CallAsOp.pm');

mkdir 'build';
$pkg->save_config('build/IFiles.pm');

makemaker_args(
    $pkg->get_makefile_vars,
    FUNCLIST => [qw/hook_op_check hook_op_check_remove/],
    DL_FUNCS => { 'B::Hooks::XSUB::CallAsOp' => [] },
);

repository 'git://github.com/nothingmuch/b-hooks-xsub-callasop.git';

ppport;

WriteAll;

