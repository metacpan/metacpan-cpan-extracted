#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use Test2::Tools::Exception;
use Test2::Tools::Explain;

use DBI;
use DBIx::Connector::Retry::MySQL;

############################################################

sub _connector {
    my @extra_args = @_;

    # In-memory DB.  Only needed to make sure a connection will work.
    my %args = ( AutoCommit => 1, RaiseError => 1, PrintError => 0 );
    my @conn = ( 'dbi:SQLite::memory:', '', '', \%args );

    my $conn = DBIx::Connector::Retry::MySQL->new( connect_info => \@conn, @extra_args );

    return $conn;
}

# Completely ignore DB activity
no warnings 'redefine';
*DBI::db::do = sub { "0E0" };
use warnings 'redefine';

############################################################

subtest 'DBI syntax constructor' => sub {
    try_ok {
        DBIx::Connector::Retry::MySQL->new(
            connect_info => [ 'dbi:SQLite::memory:', '', '' ],
        );
    } 'Standard Moo syntax works';

    try_ok {
        DBIx::Connector::Retry::MySQL->new({
            connect_info => [ 'dbi:SQLite::memory:', '', '' ],
        });
    } 'Moo hashref works';

    try_ok {
        DBIx::Connector::Retry::MySQL->new(
            'dbi:SQLite::memory:', '', '', {}
        );
    } 'Full DBI syntax works';

    try_ok {
        DBIx::Connector::Retry::MySQL->new(
            'dbi:SQLite::memory:', '', '', {}, max_attempts => 5,
        );
    } 'Full DBI syntax + args works';

    try_ok {
        DBIx::Connector::Retry::MySQL->new(
            'dbi:SQLite::memory:', '', '', max_attempts => 5,
        );
    } 'No DBI args + Moo args works';

    try_ok {
        DBIx::Connector::Retry::MySQL->new(
            'dbi:SQLite::memory:', '', '', {}, { max_attempts => 5 },
        );
    } 'Full DBI syntax + Moo hashref works';

    try_ok {
        DBIx::Connector::Retry::MySQL->new(
            'dbi:SQLite::memory:', '', '', {}, [ max_attempts => 5 ],
        );
    } 'Full DBI syntax + Moo arrayref works';

    try_ok {
        DBIx::Connector::Retry::MySQL->new(
            'dbi:SQLite::memory:', '', '', [ max_attempts => 5 ],
        );
    } 'No DBI args + Moo arrayref works';
};

subtest 'Wantarray' => sub {
    # Constructor
    my $retries = 0;
    my $conn = _connector(
        max_attempts => 1,
    );

    $conn->run(no_ping => sub {
        is wantarray, undef, 'Void context works';
        return (10, 20, 30);
    });

    my $val = $conn->run(no_ping => sub {
        is wantarray, !1, 'Scalar context works';
        return (10, 20, 30);
    });
    is $val, 30, 'Scalar return works';  # rightmost value because "comma operator"

    my @val = $conn->run(no_ping => sub {
        is wantarray, 1, 'List context works';
        return (10, 20, 30);
    });
    is \@val, [10, 20, 30], 'List return works';
};

subtest 'Errors' => sub {
    like(
        dies {
            DBIx::Connector::Retry::MySQL->new;
        },
        qr/Missing required arguments: connect_info/,
        'constructor dies with no parameters'
    );

    like(
        dies {
            DBIx::Connector::Retry::MySQL->new(
                connect_info => ['dbi:SQLite::memory:', { attr_hash_in_wrong_place => 1 }],
            );
        },
        qr/did not pass type constraint/,
        'constructor dies with bad connect_info'
    );
};

############################################################

done_testing;
