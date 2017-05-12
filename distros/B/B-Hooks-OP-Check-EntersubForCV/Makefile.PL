use strict;
use warnings;
use inc::Module::Install;
use ExtUtils::Depends;

name 'B-Hooks-OP-Check-EntersubForCV';
all_from 'lib/B/Hooks/OP/Check/EntersubForCV.pm';

requires 'parent';
requires 'Scalar::Util';
requires 'B::Utils' => '0.19';
requires 'B::Hooks::OP::Check' => '0.19';
build_requires 'B::Utils' => '0.19';
build_requires 'B::Hooks::OP::Check' => '0.19';
configure_requires 'B::Utils' => '0.19';
configure_requires 'ExtUtils::Depends';
configure_requires 'B::Hooks::OP::Check' => '0.19';

my $pkg = ExtUtils::Depends->new('B::Hooks::OP::Check::EntersubForCV', 'B::Hooks::OP::Check', 'B::Utils');
$pkg->install('hook_op_check_entersubforcv.h');
$pkg->add_xs('EntersubForCV.xs');
$pkg->add_pm('lib/B/Hooks/OP/Check/EntersubForCV.pm' => '$(INST_LIB)/B/Hooks/OP/Check/EntersubForCV.pm');

mkdir 'build';
$pkg->save_config('build/IFiles.pm');

makemaker_args(
    $pkg->get_makefile_vars,
    FUNCLIST => [qw/hook_op_check_entersubforcv hook_op_check_entersubforcv_remove/],
    DL_FUNCS => { 'B::Hooks::OP::Check::EntersubForCV' => [] },
    dist => { PREOP => 'pod2text lib/B/Hooks/OP/Check/EntersubForCV.pm > README' },
);

repository 'git://lake.fysh.org/zefram/B-Hooks-OP-Check-EntersubForCV.git';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=B-Hooks-OP-Check-EntersubForCV';

extra_tests;

WriteAll;
