use Test::Most 0.22 (tests => 6);

use Test::Exception;
use Test::NoWarnings;
use strict;
use warnings;

use Data::CouchDB::Connection;

subtest 'Password URI' => sub {
    my $couch = Data::CouchDB::Connection->new(
        host    => 'localhost',
        port    => '6984',
        couchdb => 'TESTPASS'
    );

    is $couch->uri,     'https://couchdb:TESTPASS@localhost:6984/';
    is $couch->log_uri, 'https://localhost:6984/';
};

subtest 'Protocol wth Password URI' => sub {
    my $couch = Data::CouchDB::Connection->new(
        host     => 'localhost',
        port     => '6984',
        protocol => 'https://',
        couchdb  => 'TESTPASS'
    );

    is $couch->uri,     'https://couchdb:TESTPASS@localhost:6984/';
    is $couch->log_uri, 'https://localhost:6984/';
};

subtest 'Auto protocol selection' => sub {
    subtest 'port 5984' => sub {
        my $couch = Data::CouchDB::Connection->new(
            host => 'localhost',
            port => 5984
        );

        is $couch->uri,     'http://localhost:5984/';
        is $couch->log_uri, 'http://localhost:5984/';
    };
};

subtest 'port 5984 has no password' => sub {
    my $couch = Data::CouchDB::Connection->new(
        host    => 'localhost',
        port    => '5984',
        couchdb => 'TESTPASS',
    );

    is $couch->uri,     'http://localhost:5984/';
    is $couch->log_uri, 'http://localhost:5984/';
};

subtest 'design_doc' => sub {
    subtest 'defualt' => sub {
        my $couch = Data::CouchDB::Connection->new(
            host => 'localhost',
            port => '5984',
        );

        is $couch->design_doc, '_design/docs', 'Correct Design doc';
    };

    subtest 'passed' => sub {
        my $couch = Data::CouchDB::Connection->new(
            host       => 'localhost',
            port       => '5984',
            design_doc => 'ikeepthemhere',
        );

        is $couch->design_doc, 'ikeepthemhere', 'Correct Design doc';
    };
};
