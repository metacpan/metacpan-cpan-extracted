# -*- perl -*-

# t/011_bad_quotes.t - Tests bad quoting

use Test::More tests => 5;
use Config::ApacheExtended;

my $conf = Config::ApacheExtended->new(
	source		=> "t/bad_quotes.conf",
	ignore_case	=> 1,
);


ok($conf);														# test 1
ok($conf->parse);												# test 2

my $mq1 = $conf->get('MixedQuotes1');
my $mq2 = $conf->get('MixedQuotes2');

ok($mq1);														# test 3
is($mq1, "This is a test\"\nMixedQuotes2\t\"This is a test");	# test 4
ok(!$mq2);														# test 5
