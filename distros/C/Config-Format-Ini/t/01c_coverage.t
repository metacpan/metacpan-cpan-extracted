use Test::More;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for POD coverage" if $@;
plan qw(no_plan);


my $trustme = { also_private => [ qr/^/ ] };

pod_coverage_ok( $_, $trustme ) for (
				'Config::Format::Ini',
				'Config::Format::Ini::Grammar',
				);

