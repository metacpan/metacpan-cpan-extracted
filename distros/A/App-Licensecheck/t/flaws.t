use Test2::V0;

use App::Licensecheck;
use Path::Tiny;

plan 20;

my $app = App::Licensecheck->new;
$app->lines(0);

path('t/flaws/fsf_address')->visit(
	sub {
		my ( $license, $copyright ) = $app->parse($_);
		like(
			$license, qr/ \[(?:mis-spelled|obsolete) FSF postal address /,
			"Corpus file $_"
		);
	}
);

path('t/flaws/no_fsf_address')->visit(
	sub {
		my ( $license, $copyright ) = $app->parse($_);
		unlike(
			$license, qr/ \[(?:mis-spelled|obsolete) FSF postal address /,
			"Corpus file $_"
		);
	}
);

path('t/flaws/generated')->visit(
	sub {
		my ( $license, $copyright ) = $app->parse($_);
		like(
			$license, qr/\Q [generated file]/,
			"Corpus file $_"
		);
	}
);

subtest 'false positive: BSL-1.0 license fulltext' => sub {
	my ( $license, $copyright ) = $app->parse( path('t/SPDX/BSL-1.0.txt') );
	unlike(
		$license, qr/\Q [generated file]/,
		"Corpus file t/SPDX/BSL-1.0.txt"
	);
};

done_testing;
