# -*- perl -*-

# t/010_path.t - Makes sure that we are handling paths properly in the parser

use Test::More tests => 4;
use Config::ApacheExtended;

my $conf = Config::ApacheExtended->new(
	source		=> "t/path.conf",
	ignore_case	=> 1,
);


ok($conf);												# test 1
ok($conf->parse);										# test 2

my $path = $conf->get('SamplePath');

ok($path);												# test 3
is($path,'/usr/local/bin');								# test 4

