use strict;
use warnings;
use inc::Module::Install;
use ExtUtils::Depends;

name 'B-Hooks-OP-Check-StashChange';
all_from 'lib/B/Hooks/OP/Check/StashChange.pm';

requires 'parent';
requires 'B::Hooks::OP::Check' => '0.14';
test_requires 'Test::More';
build_requires 'B::Hooks::OP::Check' => '0.14';
configure_requires 'B::Hooks::OP::Check' => '0.14';
configure_requires 'ExtUtils::Depends';

my $pkg = ExtUtils::Depends->new('B::Hooks::OP::Check::StashChange', 'B::Hooks::OP::Check');
$pkg->install('hook_op_check_stashchange.h');
$pkg->add_xs('StashChange.xs');
$pkg->add_pm('lib/B/Hooks/OP/Check/StashChange.pm' => '$(INST_LIB)/B/Hooks/OP/Check/StashChange.pm');

mkdir 'build';
$pkg->save_config('build/IFiles.pm');

makemaker_args(
    $pkg->get_makefile_vars,
    FUNCLIST => [qw/hook_op_check_stashchange hook_op_check_stashchange_remove/],
    DL_FUNCS => { 'B::Hooks::OP::Check::StashChange' => [] },
    dist => { PREOP => 'pod2text lib/B/Hooks/OP/Check/StashChange.pm > README' },
);

repository 'git://github.com/rafl/b-hooks-op-check-stashchange.git';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=B-Hooks-OP-Check-StashChange';

extra_tests;

WriteAll;
