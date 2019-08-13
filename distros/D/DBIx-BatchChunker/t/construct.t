#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use Test2::Tools::Exception;
use Test2::Tools::Explain;

use DBIx::BatchChunker;
use DBIx::Connector::Retry;
use CDTest;

############################################################

my $schema   = CDTest->init_schema;
my $track_rs = $schema->resultset('Track')->search({ position => 1 });

my $dbh  = $schema->storage->dbh;
my $conn = DBIx::Connector::Retry->new(
    connect_info => [ @{ $schema->storage->connect_info } ],
);

subtest 'Valid construction' => sub {
    try_ok {
        DBIx::BatchChunker->new(
            rs      => $track_rs,
            coderef => sub {},
        )->execute;
    }
    'execute lives even without min/max calculations';
    try_ok {
        DBIx::BatchChunker->new(
            dbi_connector => $conn,
            min_stmt      => ['SELECT 1', undef],
            max_stmt      => ['SELECT 1', { arg => 1 }, 'foobar'],
            stmt          => 'SELECT 1',
        );
    }
    'constructor lives with different types of stmt coersion';
};

subtest 'Legacy syntax' => sub {
    local $SIG{__WARN__} = sub {};

    try_ok {
        DBIx::BatchChunker->new(
            min_sth => $dbh->prepare('SELECT 1'),
            max_sth => $dbh->prepare('SELECT 1'),
            sth     => $dbh->prepare('SELECT 1'),
        );
    }
    'constructor lives with sth options';

    like(
        dies {
            DBIx::BatchChunker->new(
                min_sth => $dbh->prepare('SELECT 1'),
            );
        },
        qr/Range calculations requires/,
        'constructor dies with min_sth + no max_sth',
    );
};

subtest 'Errors' => sub {
    like(
        dies {
            DBIx::BatchChunker->new;
        },
        qr/Range calculations requires/,
        'constructor dies with no parameters'
    );
    like(
        dies {
            DBIx::BatchChunker->construct_and_execute;
        },
        qr/Range calculations requires/,
        'construct_and_execute dies with no parameters',
    );

    like(
        dies {
            DBIx::BatchChunker->new(
                dbi_connector => $conn,
                min_stmt      => 'SELECT 1',
                stmt          => 'SELECT 1',
            );
        },
        qr/Range calculations requires/,
        'constructor dies with min_stmt + no max_stmt',
    );
    like(
        dies {
            DBIx::BatchChunker->new(
                dbi_connector => $conn,
                min_stmt      => ['SELECT 1', [], {arg => 1}],
                max_stmt      => ['SELECT 1'],
                stmt          => 'SELECT 1',
            );
        },
        qr/Must be either an SQL string or an arrayref/,
        'constructor dies with bad $sth args',
    );

    like(
        dies {
            DBIx::BatchChunker->new(
                rs => $track_rs,
            );
        },
        qr/Block execution requires/,
        'constructor dies with rs + no coderef',
    );

    like(
        dies {
            DBIx::BatchChunker->new(
                rs          => $track_rs,
                coderef    => sub {},
                single_row => 1,
            );
        },
        qr/Found unknown attribute.+single_row/,
        'constructor dies with misspelled attr',
    );

};

############################################################

done_testing;
