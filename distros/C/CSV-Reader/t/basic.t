use strict;
use warnings;
use Test::More;
use lib qw(../lib);

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
