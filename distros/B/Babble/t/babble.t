#! perl -w
use strict;
use Cwd;
use Date::Manip;
use Test::More tests => 12;
use lib qw(t/dummy);

$main::TZ = "GMT";

# First, check if we can create a Babble object
use_ok ("Babble");

my $object = Babble->new ();
isa_ok ($object, "Babble");

# Then, check if it is set up properly
isa_ok ($object->{Collection}, "Babble::Document::Collection");

# Right, time to add a source, and check if it succeeded
use_ok ("Babble::DataSource::FlatFile");

$object->add_sources (
	Babble::DataSource::FlatFile->new (
		-location => cwd() . "/t/data/",
		-permalink_base => "."
	),
);

isa_ok ($object->{Sources}[0], "Babble::DataSource::FlatFile");

# Lets collect the feeds.
can_ok ($object, qw(collect_feeds));
$object->collect_feeds ();

# Did we collect something?
if (eq_array ($object->{Collection}->{documents}, [])) {
	fail ("collect_feed() run");
} else {
	pass ("collect_feed() run");
}

# Are there any documents there?
can_ok ($object, qw(all));

my @all = $object->all ();
ok ($#all == 1, "Number of documents fetched: " . ($#all + 1).
	    " (should be 2)");

# Are they ok?
like ($all[0]->{title}, qr/First blog entry/,
      "First document's title is like 'First blog entry'");

# Can we filter?
my @result = $object->search ([{
	field => "title",
	pattern => "Second"
}]);

ok ($#result == 0, "Search for /Second/");

# Good, then do some output.
like ($object->output (-type => "test"), qr/First.*Second/sm,
      "\$object->output() is like /First.*Second/");

# arch-tag: 57c6add8-a065-4a9f-98be-210aac2f2074
