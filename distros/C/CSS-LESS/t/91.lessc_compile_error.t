use Test::More;
use Test::Exception;
use strict;
use warnings;

use CSS::LESS;
use File::Slurp;
use FindBin;

# Test for error (as normal)
my $less = CSS::LESS->new();
unless ( $less->is_lessc_installed() ){
	plan(skip_all => 'Not installed lessc');
}
throws_ok( sub { $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_error.less")."" ) },
	qr/^Compile error:*/, 'LESS compile test for error file');

# Test for error (as dontdie option)
my $less_dontdie = CSS::LESS->new(dont_die => 1);
my $css;
lives_ok( sub { $css = $less_dontdie->compile( File::Slurp::read_file("$FindBin::Bin/data/90_error.less")."" ) },
	'LESS compile test for error file - dont_die');
like($css, qr/^.*FileError:.*/, 'LESS compile test for error file - check result');
like($less_dontdie->last_error(), qr/^.*FileError:.*/, 'LESS compile test for error file - check last_error');

done_testing();