use strict;
use warnings;

use Test::More;
use lib 't/lib';

my @modules = qw(
	Class::Shared
	Class::Shared::Protocol
	Class::Shared::Frontend
	Class::Shared::Backend
);

for my $module (@modules) {
	use_ok($module) or BAIL_OUT("cannot load $module");
}

ok(defined $Class::Shared::VERSION, 'Class::Shared has a version');

done_testing();
