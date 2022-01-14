use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use App::Licensecheck;
use Path::Tiny;

plan 88;

my $app = App::Licensecheck->new(
	shortname_scheme => 'spdx',
	top_lines        => 0,
);

# TODO: Report SPDX bug: Missing versioning
my %Debian2SPDX = (
	'AGPLv3'  => 'AGPL-3.0',
	'LGPL-2'  => 'LGPL-2.0',
	'WTFPL-2' => 'WTFPL',
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
