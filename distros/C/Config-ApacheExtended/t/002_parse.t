# -*- perl -*-

# t/002_parse.t - Makes sure that the parser parses properly.

use Test::More tests => 3;
use Config::ApacheExtended;

my $conf = Config::ApacheExtended->new(source => "t/parse.conf");

ok($conf);							# test 1
my $pt = $conf->parse();

ok(defined($pt));					# test 2
cmp_ok($pt, '>', 0);				# test 3

