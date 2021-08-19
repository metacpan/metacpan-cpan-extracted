use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.2';

use Test::Without::Module qw( re::engine::RE2 );
use App::Licensecheck;
use Path::Tiny;

use Test2::Require::Module 'Regexp::Pattern::License' => '3.6.0';

plan 2;

my $app = App::Licensecheck->new( shortname_scheme => 'debian,spdx' );
$app->lines(0);

my ( $license, $copyright ) = $app->parse('t/devscripts/texinfo.tex');
like $license,
	qr{GPL-3+},
	'matches expected license';
like $copyright,
	qr{1985.*2012 Free Software Foundation, Inc.},
	'matches expected copyright string';

done_testing;
