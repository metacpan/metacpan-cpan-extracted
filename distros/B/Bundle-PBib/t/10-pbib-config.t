# $Id: 10-pbib-config.t 18 2004-12-12 07:41:44Z tandler $
# pbib-config.t
#
# test PBib::Config

use strict;
use Test::More tests => 2 + 3 + 3;

BEGIN {
	use_ok('PBib::Config');
}

# use Data::Dumper;

my $c = new PBib::Config(
	argv => 0,
	env => 0,
	site => 0,
	user => 0,
	default => 1,
	quiet => 1,
	verbose => 0,
	);
isnt($c, undef, "config create");
# print Dumper $c;

my $options = $c->options( -file => 'sample.txt' );
# print Dumper $options;
foreach my $cat (qw(pbib biblio doc)) {
	ok( defined $options->{$cat}, "$cat options defined");
}

ok( $c->option("label.unique"), "label.unique is set per default");

is_deeply($options, $c->merge({}), "merge with empty set");
$c->merge({pbib => {showresult => 1}});
ok( $c->option("pbib.showresult"), "merge with single nested value");
