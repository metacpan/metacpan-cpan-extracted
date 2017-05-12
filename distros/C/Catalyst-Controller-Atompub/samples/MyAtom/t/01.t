use strict;
use warnings;
use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 38;

use Atompub::Client;
use Atompub::MediaType qw(media_type);
use File::Slurp;
use FindBin;
use HTTP::Status;
use XML::Atom::Entry;

#system "sqlite3 $FindBin::Bin/../test.db < $FindBin::Bin/../init.sql";

my $client = Atompub::Client->new;

# Service

my $serv = $client->getService('http://localhost:3000/myservice');
isa_ok $serv, 'XML::Atom::Service';

my @work = $serv->workspaces;
is @work, 1;

is $work[0]->title, 'MyAtom';

my @coll = $work[0]->collections;
is @coll, 1;

is $coll[0]->title, 'MyCollection';
is $coll[0]->href, 'http://localhost:3000/mycollection';

# Create Entry Resource

my $entry = XML::Atom::Entry->new;
$entry->title('Entry 1');
$entry->content('This is the 1st entry');

ok my $uri = $client->createEntry($coll[0]->href, $entry, 'Entry 1');
is $uri, 'http://localhost:3000/mycollection/entry_1.atom';

is $client->res->code, RC_CREATED;
is $client->res->location, 'http://localhost:3000/mycollection/entry_1.atom';
ok media_type($client->res->content_type)->is_a('entry');

$entry = $client->rc;
is $entry->title, 'Entry 1';
like $entry->id, qr{tag:localhost:3000,\d{4}-\d\d-\d\d:/mycollection/entry_1.atom};
is $entry->link->href, 'http://localhost:3000/mycollection/entry_1.atom';
ok $entry->edited;
ok $entry->updated;
like $entry->content->body, qr{This is the 1st entry};

# List Entry Resources

ok my $feed = $client->getFeed($coll[0]->href);

is $client->res->code, RC_OK;
ok media_type($client->res->content_type)->is_a('feed');

is $feed->title, 'MyCollection';
ok $feed->updated;
is $feed->id, 'http://localhost:3000/mycollection';

is $feed->link->rel, 'self';
is $feed->link->href, 'http://localhost:3000/mycollection';

my @entries = $feed->entries;
is @entries, 1;
is $entries[0]->title, 'Entry 1';

# Read Entry Resource

ok $entry = $client->getEntry($uri);

is $client->res->code, RC_OK;
ok media_type($client->res->content_type)->is_a('entry');

is $entry->title, 'Entry 1';

# Update Entry Resource

$entry->title('Entry 1, ver.2');

ok $client->updateEntry($uri, $entry);

is $client->res->code, RC_OK;
ok media_type($client->res->content_type)->is_a('entry');

$entry = $client->rc;
is $entry->title, 'Entry 1, ver.2';

# Delete Entry Resource

ok $client->deleteEntry($uri);

ok $feed = $client->getFeed($coll[0]->href);
ok !$feed->entries;
