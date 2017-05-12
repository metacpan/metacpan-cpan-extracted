use Test::Most 0.22 (tests => 6);

use Test::Exception;
use Test::NoWarnings;
use strict;
use warnings;
use CouchDB::Client;

use Data::CouchDB::Connection;

subtest 'connection' => sub {
    subtest 'basic' => sub {
        my $couch = Data::CouchDB::Connection->new(
            host => 'localhost',
            port => '5984'
        );

        ok $couch->can_connect, 'Can connect';
    };
    subtest 'faked' => sub {
        my $fake_couch = Data::CouchDB::Connection->new(
            host => '127.0.0.2',
            port => '5984'
        );

        ok !$fake_couch->can_connect, 'Cannot connect';
    };
};

my $couch = Data::CouchDB::Connection->new(
    host => 'localhost',
    port => '5984',
    db   => 'couch_ds_test',
);

$couch->can_connect or BAIL_OUT('Unable to connect to couch');

my $client = CouchDB::Client->new(uri => $couch->uri);
eval { $client->newDB('couch_ds_test')->delete; };

subtest 'positives' => sub {
    ok $couch->create_database(), 'Created Couch Test Db';
    subtest 'create/delete' => sub {
        ok $couch->create_document('test_doc'), 'Creates named doc';
        ok $couch->delete_document('test_doc'), 'Deletes named doc';

        my $rev_id = $couch->create_document();
        ok $rev_id, 'Creates unnamed doc';
        ok $couch->delete_document($rev_id), 'Deletes named doc';
    };

    subtest 'read/write document' => sub {
        ok $couch->create_document('test_doc');
        my $contents = {'alien' => 'vortigaunts'};
        ok $couch->document('test_doc', $contents), 'Able to save document';
        my $fetched = $couch->document('test_doc');
        ok $fetched->{_rev}, 'Revision is populated';
        is $fetched->{_id}, 'test_doc', 'Id is populated';
        is_deeply($contents, $fetched, 'Got the right document');
    };

    subtest 'create/query simple view' => sub {
        my $function = {all => {map => 'function(doc) { emit(doc._id, doc._rev) }'}};
        ok $couch->create_or_update_view($function), "View Created";

        my $docs = $couch->view("all");
        ok $docs;
        is scalar @$docs, 1, 'Got 1 document';
        my $contents = $couch->document($docs->[0]);
        is $contents->{_id}, 'test_doc', 'Correct document';
    };

    subtest 'update view' => sub {
        my $function = {all => {map => 'function(doc) { emit(doc._id, doc.alien) }'}};
        ok $couch->create_or_update_view($function), "View Created";

        my $docs = $couch->view("all");
        ok $docs;
        is scalar @$docs, 1, 'Got 1 document';
        my $contents = $couch->document($docs->[0]);
        is $contents->{_id}, 'test_doc', 'Correct document';
    };

    subtest 'create/query a more complex view' => sub {
        my $function = {
            append => {
                map    => 'function(doc) { emit(doc._id, doc.alien) }',
                reduce => 'function (key, values, rereduce) { return sum(values); }'
            }};
        ok $couch->create_or_update_view($function), "View Created";

        ok $couch->create_document('test_doc1');
        my $contents = {'alien' => 'headcrabs'};
        ok $couch->document('test_doc1', $contents), 'Able to save document';

        $contents = $couch->view("append");
        is $contents->[0]->{value}, '0headcrabsvortigaunts', 'Got Correct content';
    };
};

subtest 'Exceptions' => sub {
    subtest 'connection' => sub {
        my $fake_couch = Data::CouchDB::Connection->new(
            host => '127.0.0.2',
            port => '5984'
        );

        ok !$fake_couch->can_connect, 'Cannot connect';
        throws_ok {
            $fake_couch->document('test_doc');
        }
        'Data::CouchDB::ConnectionFailed';

        throws_ok {
            $fake_couch->view('test_doc');
        }
        'Data::CouchDB::ConnectionFailed';
    };

    subtest 'retrieve' => sub {
        my $couch = Data::CouchDB::Connection->new(
            host       => 'localhost',
            port       => '5984',
            design_doc => '_design/mamba',
        );

        ok $couch->can_connect, 'Connected';

        throws_ok {
            $couch->document('doc');
        }
        'Data::CouchDB::RetrieveFailed';

        throws_ok {
            $couch->view('doc');
        }
        'Data::CouchDB::RetrieveFailed';
    };

    subtest 'view' => sub {
        my $couch = Data::CouchDB::Connection->new(
            host => 'localhost',
            port => '5984',
            db   => 'couch_ds_test',
        );

        ok $couch->can_connect, 'Connected';
        my $view = {all => {map => 'function(doc) { emit(doc._id, doc._rev) }'}};
        ok $couch->create_or_update_view($view);
        throws_ok {
            $couch->view('doc');
        }
        'Data::CouchDB::QueryFailed';
    };
};

throws_ok {
    $couch->create_database();
}
qr/Connection error: 412 Precondition Failed/;

subtest 'teardown' => sub {
    my $client = CouchDB::Client->new(uri => $couch->uri);
    ok $client->newDB('couch_ds_test')->delete, 'Test DB deleted';
};
