use strict;
use warnings;

use Test::More tests => 2;
use Text::ParseWords qw/shellwords/;

BEGIN { use_ok( 'Alien::zlib::Static' ); }

diag("Libs: ".Alien::zlib::Static->libs);
diag("Cflags: ".Alien::zlib::Static->cflags);
diag("Install type: ".Alien::zlib::Static->install_type);

my %libs = map { $_ => 1 } shellwords( Alien::zlib::Static->libs );
if ($^O eq 'MSWin32') {
	ok(1, 'Library defined') if defined($libs{'-lz'});
} else {
	ok(defined($libs{'-lz'}), 'zlib defined');
}
