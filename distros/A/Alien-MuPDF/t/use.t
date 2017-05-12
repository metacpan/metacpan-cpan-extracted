use Test::More tests => 2;

use strict;
use warnings;
use File::Spec;
use File::Which 1.21 qw(which);
use Capture::Tiny qw(capture_merged);

BEGIN{  use_ok 'Alien::MuPDF' }

my $p = Alien::MuPDF->new;

my $mutool_path_in_build =
	File::Spec->catfile( $p->dist_dir, # path when building
		qw(build release mutool));
my $mutool_path = which($mutool_path_in_build)
	|| which($p->mutool_path);             # installed path
my ($merged, $exit) = capture_merged {
	system( $mutool_path, qw(-v) );
};

like($merged, qr/mutool version/, 'can run mutool');


done_testing;
