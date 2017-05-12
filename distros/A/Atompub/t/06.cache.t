use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 5;

use Atompub::Client;
use Atompub::MediaType qw(media_type);
use XML::Atom::Entry;

# instance

my $cache = Atompub::Client::Cache->instance;
isa_ok $cache, 'Atompub::Client::Cache';

# put and get a resource

my $entry = XML::Atom::Entry->new;
$entry->title('Entry 1');

my $uri = 'http://example.com/text/1';
$cache->put($uri, {
    rc   => $entry,
    etag => 'tag:abc',
});
my $rc = $cache->get($uri);
isa_ok $rc, 'Atompub::Client::Cache::Resource';

is $rc->rc->title, 'Entry 1';
is $rc->etag, 'tag:abc';

# remove a resource

$cache->put($uri);
is $cache->get($uri), undef;
