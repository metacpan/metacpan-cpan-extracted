use 5.008008;
use inc::Module::Install;

name     'Dash-Leak';
all_from 'lib/Dash/Leak.pm';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'Test::More';
build_requires 'Test::NoWarnings';
build_requires 'lib::abs';

requires 'Devel::Declare';
requires 'Guard';

if ($^O eq 'freebsd') {
	requires 'BSD::Process';
}
elsif ($^O eq 'linux') {
	requires 'Proc::ProcessTable';
}
elsif ($^O eq 'MSWin32') {
	requires 'Win32::Process::Info::WMI';
}
else {
	die "NA: No support for $^O yet. Patches are welcome";
}

auto_provides;
auto_install;

WriteAll;
