#! perl -w
use strict;
use Cwd;
use Test::More;

use Babble;

$main::TZ = "GMT";

eval q{require Babble::DataSource::Mail};
plan skip_all => 'Problem importing Mail datasource; ' .
	'probably missing dependencies' if $@;
plan tests => 5;

my $babble = Babble->new ();

$babble->add_sources (
	Babble::DataSource::Mail->new (
		-location => cwd() . "/t/data/1.mbox",
		-permalink_base => '.',
	),
);

isa_ok ($babble->{Sources}[0], "Babble::DataSource::Mail");

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
like ($all[0]->{title}, qr/test entry/,
      "First document's title is like 'test entry'");

like ($all[0]->{content}, qr/from a mailbox/,
      "First document's content is like 'from a mailbox'");

# arch-tag: 0195d0a9-e1c5-44d7-b5d2-0612d78ba5dc
