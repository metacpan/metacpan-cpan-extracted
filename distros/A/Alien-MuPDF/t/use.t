use Test::More tests => 2;

use strict;
use warnings;
use File::Spec;
use File::Which 1.21 qw(which);
use Capture::Tiny qw(capture_merged);

BEGIN{  use_ok 'Alien::MuPDF' }

my $p = Alien::MuPDF->new;

my ($merged, $exit) = capture_merged {
	system( Alien::MuPDF->mutool_path, qw(-v) );
};

like($merged, qr/mutool version/, 'can run mutool');


done_testing;
