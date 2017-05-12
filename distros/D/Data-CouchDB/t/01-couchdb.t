use Test::Most 0.22 (tests => 6);

use Test::Exception;
use Test::NoWarnings;
use Test::MockModule;
use strict;
use warnings;
use CouchDB::Client;

use Data::CouchDB;
use LWP::UserAgent;
use Cache::RedisDB;

subtest 'builds' => sub {
    subtest 'host & port' => sub {
        my $couch = Data::CouchDB->new(
            replica_host => 'localhost',
            replica_port => 5984,
            master_host  => 'localhost',
            master_port  => 5984
        );

        isa_ok $couch->replica, 'Data::CouchDB::Connection';
        isa_ok $couch->master,  'Data::CouchDB::Connection';

        is $couch->master->protocol,  'http://';
        is $couch->replica->protocol, 'http://';
    };

    subtest 'host, port & password' => sub {
        my $couch = Data::CouchDB->new(
            replica_host => 'localhost',
            replica_port => 5984,
            master_host  => 'localhost',
            master_port  => 5984,
            couchdb      => 'TESTPASS'
        );

        isa_ok $couch->replica, 'Data::CouchDB::Connection';
        isa_ok $couch->master,  'Data::CouchDB::Connection';

        is $couch->master->protocol,  'http://';
        is $couch->replica->protocol, 'http://';

        is $couch->master->couchdb,  'TESTPASS';
        is $couch->replica->couchdb, 'TESTPASS';
    };

    subtest 'host, port & protocol' => sub {
        my $couch = Data::CouchDB->new(
            replica_host     => 'localhost',
            replica_port     => 5984,
            replica_protocol => 'https://',
            master_host      => 'localhost',
            master_port      => 5984,
            master_protocol  => 'https://'
        );

        isa_ok $couch->replica, 'Data::CouchDB::Connection';
        isa_ok $couch->master,  'Data::CouchDB::Connection';

        is $couch->master->protocol,  'https://';
        is $couch->replica->protocol, 'https://';
    };
};
my $test_db = 'couch_ds_test';
subtest 'postive' => sub {
    my $couch = Data::CouchDB->new(
        replica_host => 'localhost',
        replica_port => 5984,
        master_host  => 'localhost',
        master_port  => 5984,
        db           => $test_db
    );

    my $client = CouchDB::Client->new(uri => $couch->master->uri);
    eval { $client->newDB($test_db)->delete; };

    subtest 'build' => sub {
        isa_ok $couch->replica, 'Data::CouchDB::Connection';
        isa_ok $couch->master,  'Data::CouchDB::Connection';

        is $couch->master->protocol,  'http://';
        is $couch->replica->protocol, 'http://';

        ok $couch->can_read,  'Can Read';
        ok $couch->can_write, 'Can Write';
    };

    subtest 'interface' => sub {
        ok $couch->create_database();
        ok $couch->create_document('test_doc');
        my $contents = {'planet' => 'Mars'};
        ok $couch->document('test_doc', $contents);
        my $retrieved = $couch->document('test_doc');
        ok $couch->document_present('test_doc');
        is_deeply($contents, $retrieved, 'Stored & Retrieved are same');
        my $view = {all => {map => 'function(doc) { emit(doc._id, doc._rev) }'}};
        ok $couch->master->create_or_update_view($view);
        ok $couch->view('all');
        ok $couch->delete_document('test_doc');
        ok !$couch->document_present('test_doc');
    };

    subtest 'nameless document' => sub {
        my $doc_name = $couch->create_document();
        ok $doc_name;
        ok $couch->document($doc_name, {reached => 1});
        my $new_doc = $couch->document($doc_name);
        is $new_doc->{reached}, 1, 'Correct content';
    };
};


subtest 'replica_executions' => sub {
    my $couch = Data::CouchDB->new(
        replica_host => '127.0.0.2',
        replica_port => 5984,
        master_host  => 'localhost',
        master_port  => 5984,
        db           => $test_db
    );

    ok !$couch->can_read, 'Cannot Read';
    ok $couch->can_write, 'Can Write';

    throws_ok {
        $couch->document('test');
    }
    'Data::CouchDB::ConnectionFailed';

    throws_ok {
        $couch->view('test');
    }
    'Data::CouchDB::ConnectionFailed';

    ok !$couch->document_present('test');
};

subtest 'master_executions' => sub {
    my $couch = Data::CouchDB->new(
        replica_host => 'localhost',
        replica_port => 5984,
        master_host  => '127.0.0.2',
        master_port  => 5984,
        db           => 'test'
    );

    ok $couch->can_read, 'Cannot Read';
    ok !$couch->can_write, 'Can Write';

    throws_ok {
        $couch->create_database();
    }
    'Data::CouchDB::ConnectionFailed';

    throws_ok {
        $couch->create_document('test');
    }
    'Data::CouchDB::ConnectionFailed';

    throws_ok {
        $couch->document('test', {galaxy => ['planets', 'stars', 'debris']});
    }
    'Data::CouchDB::ConnectionFailed';

    throws_ok {
        $couch->delete_document('test');
    }
    'Data::CouchDB::ConnectionFailed';
};

subtest 'teardown' => sub {
    my $couch = Data::CouchDB->new(
        replica_host => 'localhost',
        replica_port => 5984,
        master_host  => 'localhost',
        master_port  => 5984
    );
    my $client = CouchDB::Client->new(uri => $couch->master->uri);
    ok $client->newDB($test_db)->delete, 'Test DB deleted';
};
