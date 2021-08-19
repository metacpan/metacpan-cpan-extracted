use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use App::Licensecheck;
use Path::Tiny;

plan 26;

my $app = App::Licensecheck->new( shortname_scheme => 'osi' );
$app->lines(0);

path("t/OSI")->visit(
	sub {
		my ( $license, $copyright ) = $app->parse($_);
		is( $license, $_->basename('.txt'),
			"Corpus file $_"
		);
	}
);

done_testing;
