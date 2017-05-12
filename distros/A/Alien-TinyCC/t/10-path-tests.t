use strict;
use warnings;
use Test::More;

use Alien::TinyCC;

# Can we find libtcc.h?
ok(-f Alien::TinyCC->libtcc_include_path . '/libtcc.h',
	'libtcc.h is in the given include path')
		or diag('include path is [' . Alien::TinyCC->libtcc_include_path . ']');

# Can we find the shared library?
my $extension = '.a';
$extension = '.dll' if $^O =~ /MSWin/;
ok(-f Alien::TinyCC->libtcc_library_path . "/libtcc$extension",
	"libtcc$extension is in the given path")
		or diag('library path is [' . Alien::TinyCC->libtcc_library_path . ']');

my $exec = 'tcc';
$exec .= '.exe' if $^O =~ /MSWin/;
ok(-f Alien::TinyCC->path_to_tcc . "/$exec",
	"$exec is in the given path")
		or diag('path to tcc is [' . Alien::TinyCC->path_to_tcc . ']');

done_testing;
