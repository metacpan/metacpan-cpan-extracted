use Test::More;
use strict;
use warnings;

use CSS::LESS;
use File::Slurp;
use FindBin;

my $less = CSS::LESS->new( include_paths => [ $FindBin::Bin.'/data/', $FindBin::Bin.'/data_sub/' ], );
unless ( $less->is_lessc_installed() ){
	plan(skip_all => 'Not installed lessc');
}

my $css = $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_test.less")."" );
cmp_ok($css, 'eq', File::Slurp::read_file("$FindBin::Bin/data/90_test.css")."",
	'LESS compile test');

$css = $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_test.less")."", compress => 1);
cmp_ok($css, 'eq', File::Slurp::read_file("$FindBin::Bin/data/90_test_compress.css")."",
		'LESS compile test with compress');

$css = $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_test.less")."", line_numbers => "comments");
like($css, qr/\/\* line \d+, .* \*\//,
	'LESS compile test (like) with line-numbers=comments');

done_testing();