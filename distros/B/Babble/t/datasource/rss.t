#! perl -w
use strict;
use Cwd;
use Test::More;

use Babble;

$main::TZ = "GMT";

eval q{require Babble::DataSource::RSS};
plan skip_all => 'Problem importing RSS datasource; ' .
	'probably missing dependencies' if $@;
plan tests => 4;

my $babble = Babble->new ();

$babble->add_sources (
	Babble::DataSource::RSS->new (
		-location => 'file:' . cwd() . "/t/data/1.rss",
	),
);

isa_ok ($babble->{Sources}[0], "Babble::DataSource::RSS");

# Lets collect the feeds.
$babble->collect_feeds ();

# Did we collect something?
if (eq_array ($babble->{Collection}->{documents}, [])) {
	fail ("collect_feed() run");
} else {
	pass ("collect_feed() run");
}

my @all = $babble->all ();
ok ($#all == 0, "Number of documents fetched: " . ($#all + 1).
	    " (should be 1)");

# Are they ok?
like ($all[0]->{title}, qr/Babble!/,
      "First document's title is like 'Babble!'");

# arch-tag: 1afe292c-659d-4add-9908-72c60355689b
