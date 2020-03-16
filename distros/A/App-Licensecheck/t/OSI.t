use strictures;

use Test2::V0;

use App::Licensecheck;
use Path::Tiny;

plan 26;

my $app = App::Licensecheck->new;
$app->lines(0);
$app->deb_fmt(1);

# TODO: make naming scheme configurable
my %Debian2OSI = (
	'AGPL-3'            => 'AGPL-3.0',
	'Artistic'          => 'Artistic-1.0',
	'Artistic-1.0-Perl' => 'Artistic-1.0',
	'BSD-2-clause'      => 'BSD-2',
	'BSD-3-clause'      => 'BSD-3',
	'BSL'               => 'BSL-1.0',
	'Expat'             => 'MIT',
	'GPL-2'             => 'GPL-2.0',
	'LGPL-2+'           => 'LGPL-2.0',
	'LGPL-2.1+'         => 'LGPL-2.1',
	'Python-2'          => 'Python-2.0',
);

path("t/OSI")->visit(
	sub {
		my ( $license, $copyright ) = $app->parse($_);
		is( $Debian2OSI{$license} || $license, $_->basename('.txt'),
			"Corpus file $_"
		);
	}
);

done_testing;
