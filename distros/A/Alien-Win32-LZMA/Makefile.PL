use inc::Module::Install 0.91;

unless ( winlike or $ENV{ADAMK_RELEASE} ) {
	print "This module is only useful on Windows\n";
	exit(0);
}

all_from      'lib/Alien/Win32/LZMA.pm';
requires_from 'lib/Alien/Win32/LZMA.pm';
test_requires 'Test::More'   => '0.42';
test_requires 'File::Remove' => '1.42';
install_share;

WriteAll;
