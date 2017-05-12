use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More;

plan skip_all => 'set ATOMPUB_TEST_LIVE to enable this test' unless $ENV{ATOMPUB_TEST_LIVE};
plan tests => 84;

use Atompub;
use Atompub::Client;
use Atompub::DateTime qw(datetime);
use HTTP::Status;
use URI::Escape;

my $SERVICE = 'http://teahut.sakura.ne.jp:3000/service';
#my $SERVICE = 'http://localhost:3000/service';
my $USER = 'foo';
my $PASS = 'foo';


my $client = Atompub::Client->new;
isa_ok $client, 'Atompub::Client';

$client->username($USER);
$client->password($PASS);

if (my $proxy = $ENV{HTTP_PROXY} || $ENV{http_proxy}) {
    diag "using HTTP proxy: $proxy";
    $client->proxy( $proxy ) if $proxy;
}

# Service

ok !$client->getService('http://example.com/service'); # Not Found

like $client->errstr, qr/not found/i;

isa_ok $client->req, 'HTTP::Request';
isa_ok $client->res, 'HTTP::Response';
ok !$client->rc;

is $client->res->code, RC_NOT_FOUND;

ok $client->getService($SERVICE);

isa_ok $client->req, 'HTTP::Request';
isa_ok $client->res, 'HTTP::Response';
isa_ok $client->rc, 'XML::Atom::Service';

ok $client->res->is_success;

my $serv = $client->rc;
my($entry_coll, $media_coll) = $serv->workspace->collections;

isa_ok $client->info->get($entry_coll->href), 'XML::Atom::Collection';
isa_ok $client->info->get($media_coll->href), 'XML::Atom::Collection';


# Create Entry Resource

my $entry = XML::Atom::Entry->new;
$entry->title('Entry 1');
$entry->updated(datetime->w3c);
$entry->id('tag:teahut.sakura.ne.jp,2007:1');
$entry->content('<span>This is the 1st entry</span>');

my $category = XML::Atom::Category->new; # Forbidden category
$category->term('animal');
$category->scheme('http://example.com/dogs/big3');
$entry->category( $category );

ok !$client->createEntry($entry_coll->href, $entry, 'Entry 1');

like $client->errstr, qr/forbidden category/i;

ok !$client->req;
ok !$client->res;
ok !$client->rc;


$category = XML::Atom::Category->new;
$category->term('animal');
$category->scheme('http://example.com/cats/big3');
$entry->category($category);

ok $client->createEntry($entry_coll->href, $entry, 'Entry 1');

isa_ok $client->req, 'HTTP::Request';
isa_ok $client->res, 'HTTP::Response';
isa_ok $client->rc, 'XML::Atom::Entry';

is $client->req->slug, 'Entry 1';
is $client->res->code, RC_CREATED;
ok my $uri = $client->res->location;

$entry = $client->rc;
is $entry->title, 'Entry 1';

isa_ok $client->cache->get($uri), 'Atompub::Client::Cache::Resource';


# List Entry Resources (Get Feed)

ok $client->getFeed($entry_coll->href);

isa_ok $client->req, 'HTTP::Request';
isa_ok $client->res, 'HTTP::Response';
isa_ok $client->rc, 'XML::Atom::Feed';

ok $client->res->is_success;


# Get Entry Resource

ok $client->getEntry($uri);

isa_ok $client->req, 'HTTP::Request';
isa_ok $client->res, 'HTTP::Response';
isa_ok $client->rc, 'XML::Atom::Entry';

is $client->res->code, RC_NOT_MODIFIED;

$entry = $client->rc;
is $entry->title, 'Entry 1';

isa_ok $client->cache->get($uri), 'Atompub::Client::Cache::Resource';


# Update Entry Resource

$entry->title('Entry 2');

ok $client->updateEntry($uri, $entry);

isa_ok $client->req, 'HTTP::Request';
isa_ok $client->res, 'HTTP::Response';
isa_ok $client->rc, 'XML::Atom::Entry';

ok $client->res->is_success;

$entry = $client->rc;
is $entry->title, 'Entry 2';

isa_ok $client->cache->get($uri), 'Atompub::Client::Cache::Resource';


# Delete Entry Resource

ok $client->deleteEntry($uri);

isa_ok $client->req, 'HTTP::Request';
isa_ok $client->res, 'HTTP::Response';
ok !$client->rc;

ok $client->res->is_success;


# Create Media Resource

# Unsupported media type
ok !$client->createMedia($media_coll->href, 't/samples/media1.gif', 'text/plain', 'Media 1');

like $client->errstr, qr/unsupported media type/i;

ok !$client->req;
ok !$client->res;
ok !$client->rc;


ok $client->createMedia($media_coll->href, 't/samples/media1.gif', 'image/gif', 'Media 1');

isa_ok $client->req, 'HTTP::Request';
isa_ok $client->res, 'HTTP::Response';
isa_ok $client->rc, 'XML::Atom::Entry';

is $client->req->slug, 'Media 1';
is $client->res->code, RC_CREATED;
ok $uri = $client->res->location;

isa_ok $client->cache->get($uri), 'Atompub::Client::Cache::Resource';


# Get Media Resource

($uri) = map { $_->href } grep { $_->rel eq 'edit-media' } $client->rc->link;

ok $client->getMedia($uri);

isa_ok $client->req, 'HTTP::Request';
isa_ok $client->res, 'HTTP::Response';
ok $client->rc;

ok $client->res->is_success;
is $client->res->content_type, 'image/gif';

isa_ok $client->cache->get($uri), 'Atompub::Client::Cache::Resource';


# Update Media Resource

ok $client->updateMedia($uri, 't/samples/media2.gif', 'image/gif');

isa_ok $client->req, 'HTTP::Request';
isa_ok $client->res, 'HTTP::Response';
ok $client->rc;

ok $client->res->is_success;
is $client->res->content_type, 'image/gif';

isa_ok $client->cache->get($uri), 'Atompub::Client::Cache::Resource';


# Delete Media Resource

ok $client->deleteMedia($uri);

isa_ok $client->req, 'HTTP::Request';
isa_ok $client->res, 'HTTP::Response';
ok !$client->rc;

ok $client->res->is_success;
