use Test2::V0;

use App::Licensecheck;
use Path::Tiny;

plan 20;

my $app = App::Licensecheck->new(
	top_lines => 0,
);

path('t/flaws/fsf_address')->visit(
	sub {
		like [ $app->parse($_) ], array {
			item qr/ \[(?:mis-spelled|obsolete) FSF postal address /;
		};
	}
);

path('t/flaws/no_fsf_address')->visit(
	sub {
		like [ $app->parse($_) ], array {
			item mismatch qr/ \[(?:mis-spelled|obsolete) FSF postal address /;
		};
	}
);

path('t/flaws/generated')->visit(
	sub {
		like [ $app->parse($_) ], array {
			item qr/\Q [generated file]/;
		};
	}
);

like [ $app->parse('t/SPDX/BSL-1.0.txt') ], array {
	item mismatch qr/\Q [generated file]/;
}, 'false positive: BSL-1.0 license fulltext';

done_testing;
