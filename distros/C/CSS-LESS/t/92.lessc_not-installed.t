use Test::More;
use Test::Exception;
use strict;
use warnings;

use CSS::LESS;
use File::Slurp;
use FindBin;

# Test for lessc not-installed environment
my $less = CSS::LESS->new( path_lessc_bin => '/usr/not/found/foo/bar/lessc' );
cmp_ok($less->is_lessc_installed(), '==', 0, 'LESS compiler not-installed test');

# Test for compile kessc not-installed environment
throws_ok( sub { $less->compile('width: 100px;') },
	qr/^lessc is not installed/, 'lessc not-installed compile test');

# Test for lessc not-installed environment (dry-run)
$less = CSS::LESS->new( dry_run => 1, path_lessc_bin => '/usr/not/found/foo/bar/lessc' );
cmp_ok($less->is_lessc_installed(), '==', 1, '(Dry-run) LESS compiler not-installed test');
# Always it is 1, if dry-run.

done_testing();