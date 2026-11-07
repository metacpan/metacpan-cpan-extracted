use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

my @modules = qw(
	App::WebPerimeterScan
	App::WebPerimeterScan::Checks
	App::WebPerimeterScan::Findings
	App::WebPerimeterScan::HTTP
	App::WebPerimeterScan::I18N
	App::WebPerimeterScan::Messages
	App::WebPerimeterScan::Ports
	App::WebPerimeterScan::Report
	App::WebPerimeterScan::Scope
	App::WebPerimeterScan::Source
	App::WebPerimeterScan::TLS
);

for my $module (@modules) {
	use_ok($module) or BAIL_OUT("Cannot load $module");
}

# Every module ships in the same distribution, so one release has one
# version; mixed versions make it impossible to tell which code produced a
# report.
my $version = $App::WebPerimeterScan::VERSION;
for my $module (@modules) {
	is($module->VERSION, $version, "$module is at $version");
}

done_testing();
