use strict;
use warnings;
use Test::More;

use Alien::TinyCCx;

sub diag_dir {
	my ($name, $path) = @_;
	diag("$name path is [$path] and contains:");
	
	# Print out all the files in the directory, in the hopes I might
	# be able to pick out the right extension for this OS from the
	# testers reports:
	opendir my $dh, $path or return diag "Can't opendir: $!";
	diag "  $_" foreach (sort readdir $dh);
	closedir $dh;
}

# Can we find libtcc.h?
ok(-f Alien::TinyCCx->libtcc_include_path . '/libtcc.h',
	'libtcc.h is in the given include path')
		or diag_dir('include', Alien::TinyCCx->libtcc_include_path);

# Can we find the shared library?
my $extension = '.a';
$extension = '.dll' if $^O =~ /MSWin/;

ok(-f Alien::TinyCCx->libtcc_library_path . "/libtcc$extension",
	"libtcc$extension is in the given path")
		or diag_dir('library', Alien::TinyCCx->libtcc_library_path);

my $exec = 'tcc';
$exec .= '.exe' if $^O =~ /MSWin/;
ok(-f Alien::TinyCCx->path_to_tcc . "/$exec",
	"$exec is in the given path")
		or diag_dir('tcc executable', Alien::TinyCCx->path_to_tcc);

done_testing;
