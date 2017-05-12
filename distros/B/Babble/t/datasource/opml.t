#! perl -w
use strict;
use Cwd;
use Test::More;

use Babble;

$main::TZ = "GMT";

eval q{require Babble::DataSource::OPML};
plan skip_all => 'Problem importing OPML datasource; ' .
	'probably missing dependencies' if $@;
plan tests => 4;

my $babble = Babble->new ();

$babble->add_sources (
	Babble::DataSource::OPML->new (
		-location => 'file:' . cwd() . "/t/data/1.opml",
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

# arch-tag: 2d5a933b-0bad-4b01-b586-31b3a94a1c86
