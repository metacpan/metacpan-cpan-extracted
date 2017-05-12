use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 14;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::WWW::Mechanize::Catalyst 'TestAtompub';

use Atompub::MediaType qw(media_type);
use XML::Atom::Feed;

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('/collection');

ok media_type($mech->res->content_type)->is_a('feed');

my $feed = XML::Atom::Feed->new(\$mech->res->content);
isa_ok $feed, 'XML::Atom::Feed';

is $feed->title, 'Collection';
ok $feed->updated;
is $feed->id, 'http://localhost/collection';

is $feed->link->rel, 'self';
is $feed->link->href, 'http://localhost/collection';

my @entries = $feed->entries;
is @entries, 1;

is $entries[0]->title, 'Entry 1';

$mech->get_ok('/collection/entry_1.atom');

ok media_type($mech->res->content_type)->is_a('entry');

my $entry = XML::Atom::Feed->new(\$mech->res->content);
isa_ok $entry, 'XML::Atom::Feed';

is $entry->title, 'Entry 1';
