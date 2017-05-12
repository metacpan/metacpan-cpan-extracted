#! perl -w
use strict;
use Cwd;
use Test::More tests => 5;
use lib qw(t/dummy);

use Babble;
use Babble::DataSource::FlatFile;

$main::TZ = "GMT";

my $babble = Babble->new ();

$babble->add_sources (
	Babble::DataSource::FlatFile->new (
		-location => cwd() . "/t/data/",
		-permalink_base => "."
	),
);

isa_ok ($babble->{Sources}[0], "Babble::DataSource::FlatFile");

# Lets collect the feeds.
$babble->collect_feeds ();

# Did we collect something?
if (eq_array ($babble->{Collection}->{documents}, [])) {
	fail ("collect_feed() run");
} else {
	pass ("collect_feed() run");
}

my @all = $babble->all ();
ok ($#all == 1, "Number of documents fetched: " . ($#all + 1).
	    " (should be 2)");

# Are they ok?
like ($all[0]->{title}, qr/First blog entry/,
      "First document's title is like 'First blog entry'");

unlike ($all[0]->{id}, qr/SCALAR/,
	"First document's id is not like 'SCALAR'");

# arch-tag: b56ad589-da34-409b-8493-1bc0611a395d
