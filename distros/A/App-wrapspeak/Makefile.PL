use inc::Module::Install;

name     'App-wrapspeak';
all_from 'lib/App/wrapspeak.pm';
author   q{mucker <mukcer@gmx.com>};
license  'perl';

requires_external_bin 'festival';

requires       'Modern::Perl'  => 0;
requires       'Term::TermKey'  => 0;
requires       'IPC::Open3'  => 0;
requires       'File::Slurp'  => 0;
requires       'Time::HiRes'  => 0;
requires       'IO::Select'  => 0;

install_script 'scripts/wrapspeak.pl';

build_requires 'Test::More';

auto_install;

WriteAll;

