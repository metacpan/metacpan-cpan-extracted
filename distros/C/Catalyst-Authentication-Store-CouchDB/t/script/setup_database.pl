#!/usr/bin/env perl

use strict;
use warnings;
use CouchDB::Client 0.09;
use Try::Tiny 0.09;

my $uri = 'http://localhost:5984/';
my $db_name = 'demouser';


my $client = CouchDB::Client->new( uri => $uri );

$client->testConnection() or die "Cannot connect to CouchDB instance at ".$uri;

# Firstly, delete any existing database

my $db = $client->newDB($db_name);
try {
    $db->delete();
} catch {
};

# Now, create the database again

$db->create();

# Get the data for each document to be created, and create it.
# We create them all using newDoc - the design document is just
# an ordinary document with a special name, so newDoc can still
# create it.
#
foreach my $new_doc (get_doc_data()) {
    my $doc = $db->newDoc($new_doc->{id}, undef, $new_doc->{data});
    $doc->create();
}


sub get_doc_data {
    return 
    (
    {
        data => {
            language => "javascript",
            views => {
                user => {
                    "map" => "function(doc) {\n  if (doc.username) {\n  emit(doc.username, null)\n}\n}",
                },
            },
        },
        id => "_design/user",
    },
    {
        data => {
            fullname => "Test User",
            password => "test",
            roles    => ["admin", "user"],
            username => "test",
        },
        id => undef,
    },
    {
        data => {
            fullname => "Test User 2",
            password => "test2",
            roles    => ["user"],
            username => "test2",
        },
        id => undef,
    },
    );
}


