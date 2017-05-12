use inc::Module::Install;

# Make sure we have a display
use Test::NeedsDisplay;

name		'App-GUI-Notepad';
abstract	'A cross-platform CPAN-installable Perl Notepad';
author		'Ben Marsh';
license		'perl';
all_from	'lib/App/GUI/Notepad.pm';
requires	'File::Spec'         => '0.80';
requires	'Data::Dumper'       => 0;
requires	'Wx'                 => '0.25';
build_requires	'Test::More'         => '0.47';
# Allow testing on systems without a display
build_requires	'Test::NeedsDisplay' => 0;
include		'Test::NeedsDisplay';
install_script	'bin/perlpad';
auto_install;
WriteAll;
