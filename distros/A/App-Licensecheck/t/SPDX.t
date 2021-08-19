use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use App::Licensecheck;
use Path::Tiny;

plan 88;

my $app = App::Licensecheck->new( shortname_scheme => 'debian,spdx' );
$app->lines(0);

# TODO: make naming scheme configurable
# TODO: Detect MPL-1.0 version on separate line
# TODO: Report SPDX bug: Missing versioning
my %Debian2SPDX = (
	'AGPL-1'       => 'AGPL-1.0',
	'AGPL-3'       => 'AGPL-3.0',
	'AGPL-3+'      => 'AGPL-3.0',
	'Aladdin-8'    => 'Aladdin',
	'Artistic'     => 'Artistic-1.0',
	'BSD-2-clause' => 'BSD-2-Clause',
	'BSD-3-clause' => 'BSD-3-Clause',
	'BSD-4-clause' => 'BSD-4-Clause',
	'Expat'        => 'MIT',
	'GPL-1+'       => 'GPL-1.0',
	'GPL-2+'       => 'GPL-2.0',
	'LGPL-2'       => 'LGPL-2.0',
	'LGPL-2.1+'    => 'LGPL-2.1',
	'MPL'          => 'MPL-1.0',
	'Python-2'     => 'Python-2.0',
	'WTFPL-2'      => 'WTFPL',
	'NUnit'        => 'zlib-acknowledgement',
);

path("t/SPDX")->visit(
	sub {
		my ( $license, $copyright ) = $app->parse($_);
		is( $Debian2SPDX{$license} || $license, $_->basename('.txt'),
			"Corpus file $_"
		);
	}
);

done_testing;
