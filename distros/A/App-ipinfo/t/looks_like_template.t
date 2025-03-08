use utf8;

use strict;
use warnings;
use open qw(:std :utf8);

use Test::More;

plan skip_all => 'set APP_IPINFO_TOKEN for live tests'
	unless defined $ENV{'APP_IPINFO_TOKEN'};

my $class  = 'App::ipinfo';
my $method = 'looks_like_template';

my $ip = '151.101.130.132';

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, $method;
	};

subtest 'templates' => sub {
	my @templates = qw( %% %n %T %j acb%T );
	foreach my $t ( @templates ) {
		ok $class->$method($t), "<$t> looks like a template";
		}
	};

subtest 'non templates' => sub {
	my @templates = qw( abc 123 % abc% );
	foreach my $t ( @templates ) {
		ok ! $class->$method($t), "<$t> does not look like a template";
		}
	};

done_testing();
