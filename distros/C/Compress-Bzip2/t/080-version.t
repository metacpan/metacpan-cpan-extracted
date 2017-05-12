# -*- mode: perl -*-

## this is the 01version.t test from Compress::Bzip2 1.03 with no changes
## (except for comments)

# basic test, see if we can load the module and get a version

use strict;

use Test::More tests => 3;

BEGIN {
	use_ok('Compress::Bzip2',
	 qw(compress decompress compress_init decompress_init));
}

my $mod_ver = $Compress::Bzip2::VERSION;
ok($mod_ver,"module version $mod_ver");

my $lib_ver = Compress::Bzip2::version();
ok($lib_ver,"library version $lib_ver");


# vi:ts=4:noet
