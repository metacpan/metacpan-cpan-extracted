use strict;
use warnings;
use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 98;

use Atompub::Client;
use Atompub::DateTime qw(datetime);
use Atompub::MediaType qw(media_type);
use File::Slurp;
use FindBin;
use HTTP::Status;
use XML::Atom::Entry;

#system "sqlite3 $FindBin::Bin/../test.db < $FindBin::Bin/../init.sql";

my $client = Atompub::Client->new;

$client->username('foo');
$client->password('foo');

# Service

my $serv = $client->getService('http://localhost:3000/service');
isa_ok $serv, 'XML::Atom::Service';

my @work = $serv->workspaces;
is @work, 1;

is $work[0]->title, 'My Blog';

my @coll = $work[0]->collections;
is @coll, 2;

is $coll[0]->title, 'Diary';
is $coll[0]->href, 'http://localhost:3000/entrycollection';

is $coll[1]->title, 'Photo';
is $coll[1]->href, 'http://localhost:3000/mediacollection';

# Create Entry Resource

my $entry = XML::Atom::Entry->new;
$entry->title('Entry 1');
$entry->content('This is the 1st entry');

my $category = XML::Atom::Category->new;
$category->term('animal');
$category->scheme('http://example.com/dogs/big3');
$entry->add_category($category);

ok !$client->createEntry($coll[0]->href, $entry, 'Entry 1');
like $client->errstr, qr{Forbidden category}i;

$category->scheme('http://example.com/cats/big3');

ok my $uri = $client->createEntry($coll[0]->href, $entry, 'Entry 1');
is $uri, 'http://localhost:3000/entrycollection/entry_1.atom';

is $client->res->code, RC_CREATED;
is $client->res->location, 'http://localhost:3000/entrycollection/entry_1.atom';
ok $client->res->etag;
#ok $client->res->last_modified;
ok media_type( $client->res->content_type )->is_a('entry');

$entry = $client->rc;
is $entry->title, 'Entry 1';
like $entry->id, qr{tag:localhost:3000,\d{4}-\d\d-\d\d:/entrycollection/entry_1.atom};
is $entry->link->href, 'http://localhost:3000/entrycollection/entry_1.atom';
ok $entry->edited;
ok $entry->updated;
is $entry->category->term, 'animal';
like $entry->content->body, qr{This is the 1st entry};

ok $client->createEntry($coll[0]->href, $entry, 'Entry 1'); # same slug

# List Entry Resources

ok my $feed = $client->getFeed($coll[0]->href);

is $client->res->code, RC_OK;
ok media_type($client->res->content_type)->is_a('feed');

is $feed->title, 'Diary';
ok $feed->updated;
is $feed->id, 'http://localhost:3000/entrycollection';

is $feed->self_link, 'http://localhost:3000/entrycollection';
is $feed->first_link, 'http://localhost:3000/entrycollection';
is $feed->next_link, undef;

my @entries = $feed->entries;
is @entries, 2;
is $entries[0]->title, 'Entry 1';

# Read Entry Resource

ok $entry = $client->getEntry($uri);

is $client->res->code, RC_NOT_MODIFIED;

# Update Entry Resource

$entry->title('Entry 1, ver.2');

ok $client->updateEntry($uri, $entry);

is $client->res->code, RC_OK;
ok $client->res->etag;
#ok $client->res->last_modified;
ok media_type($client->res->content_type)->is_a('entry');

$entry = $client->rc;
is $entry->title, 'Entry 1, ver.2';

# Delete Entry Resource

ok $client->deleteEntry($uri);

ok $feed = $client->getFeed($coll[0]->href);
is $feed->entries, 1;

# Create Media Resource

ok ! $client->createMedia($coll[1]->href, 't/samples/media1.gif', 'text/plain', 'Media 1');
like $client->errstr, qr{unsupported media type}i;

ok $uri = $client->createMedia($coll[1]->href, 't/samples/media1.gif', 'image/gif', 'Media 1');
is $uri, 'http://localhost:3000/mediacollection/media_1.atom';

is $client->res->code, RC_CREATED;
is $client->res->location, 'http://localhost:3000/mediacollection/media_1.atom';
ok $client->res->etag;
#ok $client->res->last_modified;
ok media_type($client->res->content_type)->is_a('entry');

$entry = $client->rc;
is $entry->title, 'Media 1';
ok $entry->edited;
ok $entry->updated;
like $entry->id, qr{tag:localhost:3000,\d{4}-\d\d-\d\d:/mediacollection/media_1.atom};

is $entry->edit_link, 'http://localhost:3000/mediacollection/media_1.atom';
is my $media_uri = $entry->edit_media_link, 'http://localhost:3000/mediacollection/media_1.gif';

is $entry->content->src, 'http://localhost:3000/mediacollection/media_1.gif';
is $entry->content->type, 'image/gif';

ok $client->createMedia($coll[1]->href, 't/samples/media1.gif', 'image/gif', 'Media 1'); # same slug

# List Media Link Entries

ok $feed = $client->getFeed($coll[1]->href);

is $client->res->code, RC_OK;
ok media_type($client->res->content_type)->is_a('feed');

is $feed->title, 'Photo';
ok $feed->updated;
is $feed->id, 'http://localhost:3000/mediacollection';

is $feed->self_link, 'http://localhost:3000/mediacollection';
is $feed->first_link, 'http://localhost:3000/mediacollection';
is $feed->next_link, undef;

@entries = $feed->entries;
is @entries, 2;
is $entries[0]->title, 'Media 1';

# Read Media Link Entry

ok $entry = $client->getEntry($uri);

is $client->res->code, RC_NOT_MODIFIED;

# Update Media Link Entry

$entry->title('Media 1, ver.2');
$entry->content->src('http://wrong.uri');
$entry->content->type('wrong/type');

ok $client->updateEntry($uri, $entry);

is $client->res->code, RC_OK;
ok $client->res->etag;
#ok $client->res->last_modified;
ok media_type($client->res->content_type)->is_a('entry');

$entry = $client->rc;
is $entry->title, 'Media 1, ver.2';
is $entry->content->src, 'http://localhost:3000/mediacollection/media_1.gif';
is $entry->content->type, 'image/gif';

# Read Media Resource

ok my $media = $client->getMedia($media_uri);

is $client->res->code, RC_OK;
ok $client->res->etag;
#ok $client->res->last_modified;

is $media, read_file('t/samples/media1.gif', binmode => ':raw');

ok $client->getMedia($media_uri);
is $client->res->code, RC_NOT_MODIFIED;

# Update Media Resource

my $prev_edited = $entry->edited;
sleep 1;

ok $client->updateMedia($media_uri, 't/samples/media2.png', 'image/png');

is $client->res->code, RC_OK;
ok $client->res->etag;
#ok $client->res->last_modified;

is $client->rc, read_file('t/samples/media2.png', binmode => ':raw');

$entry = $client->getEntry($uri);
ok datetime($entry->edited) > datetime($prev_edited);
is $entry->content->src, 'http://localhost:3000/mediacollection/media_1.gif';
is $entry->content->type, 'image/png';

# Delete Entry Resource

ok $client->deleteMedia($media_uri);

ok $feed = $client->getFeed($coll[1]->href);
is $feed->entries, 1;
