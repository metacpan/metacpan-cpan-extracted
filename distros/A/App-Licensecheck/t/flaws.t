use Test2::V0;

use App::Licensecheck;
use Path::Tiny;

plan 20;

my @opts = (
	top_lines => 0,
);

sub parse
{
	my ($path) = @_;

	my ($license) = App::Licensecheck->new(@opts)->parse($path);

	return $license;
}

path('t/flaws/fsf_address')->visit(
	sub {
		like parse($_), qr/ \[(?:mis-spelled|obsolete) FSF postal address /;
	}
);

path('t/flaws/no_fsf_address')->visit(
	sub {
		unlike parse($_), qr/ \[(?:mis-spelled|obsolete) FSF postal address /;
	}
);

path('t/flaws/generated')
	->visit( sub { like parse($_), qr/\Q [generated file]/ } );

unlike parse('t/SPDX/BSL-1.0.txt'), qr/\Q [generated file]/,
	'false positive: BSL-1.0 license fulltext';

done_testing;
