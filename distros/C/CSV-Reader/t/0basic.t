use strict;
use warnings;
use Cwd ();
use Test::More;
use File::Basename;
use lib (
	File::Basename::dirname(Cwd::abs_path(__FILE__)) . '/../lib',	# in build dir
	File::Basename::dirname(Cwd::abs_path(__FILE__)) . '/../..'		# in project dir with t subdir in same dir as .pm file
);

my @methods = qw(
	new
	eof
	fieldNames
	nextRow
);

plan tests => 1 + scalar(@methods);

my $class = 'CSV::Reader';
require_ok($class) || BAIL_OUT("Failed to require $class");
foreach my $method (@methods) {
	can_ok($class, $method);
}
#done_testing();
