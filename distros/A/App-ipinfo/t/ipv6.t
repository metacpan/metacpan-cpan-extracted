use utf8;

use strict;
use warnings;
use open qw(:std :utf8);

use Test::More;
use Net::CIDR qw(cidrvalidate);

my $class  = 'App::ipinfo';
my $method = '_compact_ipv6';

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, $method;
	};

subtest 'check that we can compact IPv6 addresses' => sub {
	my $sub = $class->can($method);

	my @table = (
		[ '0:0:0:0:0:0:0:0',  '::',              'null address is ::' ],
		[ '1:2:3:4:5:6:0:0',  '1:2:3:4:5:6::',   'trailing zero' ],
		[ '0:0:2:3:4:5:6:7',  '::2:3:4:5:6:7',   'leading zero' ],
		[ '1:2:3:0:0:5:6:7',  '1:2:3::5:6:7',    'internal zero' ],
		[ '1:2:3:4:5:6:7:8',  '1:2:3:4:5:6:7:8', 'no zero' ],
		);

	foreach my $row ( @table ) {
		subtest $row->[2] => sub {
			my $compact = $sub->($row->[0]);
			is $compact, $row->[1], 'compact version is expected';
			ok cidrvalidate($compact), 'compact version validates';
			};
		}
	};

done_testing();
