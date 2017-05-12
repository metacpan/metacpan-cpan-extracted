#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;

use CouchDB::Deploy;
use CouchDB::Client qw();

my $SERVER = $ARGV[0] || $ENV{COUCHDB_DEPLOY_SERVER} || 'http://localhost:5984/';
my $C = CouchDB::Client->new(uri => $SERVER);

if($C->testConnection) {
    plan tests => 31;
}
else {
    plan skip_all => 'Could not connect to CouchDB, skipping.';
    warn <<EOMSG;
You can specify how these tests can connect to CouchDB by setting the 
COUCHDB_CLIENT_URI environment variable to the address of your server.
EOMSG
    exit;
}


# CONFIG
my $dbName = 'test-perl-couchdb-deploy';
my $docName1 = 'dahut-is-coolness';
my $docName2 = 'higher-circle';
my $ddName1 = '_design/dahuts';
my $ddName2 = '_design/circles';

sub deploy {
    db $dbName, containing {
        doc {
            _id     => $docName1,
            type    => 'dahut',
            _attachments => {
                'foo.txt'   => {
                    content_type    => 'text/plain',
                    data            => 'RGFodXRzIEZvciBXb3JsZCBEb21pbmF0aW9uIQ==',
                },
                'bar.svg'   => {
                    content_type    => 'image/svg+xml',
                    data            => file 'dahut.svg',
                },
            },
        };
        design {
            _id         => $ddName1,
            language    => 'javascript',
            views   => {
                'all'   => {
                    map     => "function(doc) { if (doc.type == 'dahut')  emit(null, doc) }",
                },
            },
        };
    };
}

### --- FIRST CALL
eval { deploy(); };
ok not($@), 'deploy did not explode';

ok $C->dbExists($dbName), 'DB was created';
my $DB = $C->newDB($dbName);

ok @{$DB->listDocs} == 2, 'DB contains two docs (the doc and the design doc)';
ok $DB->docExists($docName1), 'DB contains the right doc name';
my $DOC = $DB->newDoc($docName1)->retrieve;
ok $DOC->data->{type} eq 'dahut', 'Good doc content';
ok keys %{$DOC->attachments} == 2, 'Good number of attachments';
ok $DOC->fetchAttachment('foo.txt') eq 'Dahuts For World Domination!', 'Attach 1 good content';
ok $DOC->fetchAttachment('bar.svg') =~ m/svg/, 'Attach 2 good content';

ok @{$DB->listDesignDocs} == 1, 'DB contains one design doc';
ok $DB->designDocExists($ddName1), 'DB contains the right design doc name';
my $DD = $DB->newDesignDoc($ddName1)->retrieve;
ok $DD->views->{all}, 'Good design doc content';

### --- SECOND CALL

my $docRev = $DOC->rev;
my $ddRev = $DD->rev;
eval { deploy(); };
ok not($@), 'deploy did not explode the second time';
ok $C->dbExists($dbName), 'DB still there';
ok @{$DB->listDocs} == 2, 'DB still contains two docs';
ok $DB->docExists($docName1), 'DB still contains the right doc name';
ok @{$DB->listDesignDocs} == 1, 'DB still contains one design doc';
ok $DB->designDocExists($ddName1), 'DB still contains the right design doc name';
$DOC->retrieve;
$DD->retrieve;
ok $docRev == $DOC->rev, 'Doc rev has not changed';
ok $ddRev == $DD->rev, 'Design Doc rev has not changed';


### --- EXTRA DOC AND DESIGN

eval {
    db $dbName, containing {
        doc {
            _id     => $docName2,
            type    => 'dahut',
        };
        design {
            _id         => $ddName2,
            language    => 'javascript',
            views   => {},
        };
    };
};
ok not($@), 'deploy of more did not explode';

ok $C->dbExists($dbName), 'DB still still there';
ok @{$DB->listDocs} == 4, 'DB now contains four docs';
ok $DB->docExists($docName2), 'DB contains new doc';
ok @{$DB->listDesignDocs} == 2, 'DB now contains two design doc';
ok $DB->designDocExists($ddName2), 'DB contains new design doc';
$DOC->retrieve;
$DD->retrieve;
ok $docRev == $DOC->rev, 'Old Doc rev has not changed';
ok $ddRev == $DD->rev, 'Old Design Doc rev has not changed';


### --- update a bit
my $DOC2 = $DB->newDoc($docName2)->retrieve;
my $doc2Rev = $DOC2->rev;
eval {
    db $dbName, containing {
        doc {
            _id     => $docName2,
            type    => 'dahut',
            more    => 'see elsewhere',
        };
    };
};
ok not($@), 'deploy of more did not explode';
ok @{$DB->listDocs} == 4, 'DB still contains four docs';
ok $DB->docExists($docName2), 'DB contains doc 2';
$DOC2->retrieve;
ok $doc2Rev != $DOC2->rev, 'Doc rev has changed';



### --- THE CLEANUP AT THE END

eval {
    $DD->delete;
    $DOC->delete;
    $DB->delete;
};
warn "\n\nSmall cleanup problem: $@\n\n" if $@;
