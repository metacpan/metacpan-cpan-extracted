#!/usr/bin/perl

use strict;
use warnings;

use Test2::Bundle::More;

use DBIx::ParseError::MySQL;

############################################################

our %ERRORS = (
    lock => [
        'Deadlock found when trying to get lock; try restarting transaction',
        'Lock wait timeout exceeded; try restarting transaction',
        'WSREP detected deadlock/conflict and aborted the transaction. Try restarting the transaction',
    ],
    connection => [
        'MySQL server has gone away',
        'Lost connection to MySQL server during query',
        "Host 'example.com' is blocked because of many connection errors",
        "Can't connect to local MySQL server",
        "Can't connect to MySQL server",
        'Got an error reading communication packets',
        'Got an error writing communication packets',
        'Got timeout reading communication packets',
        'Got timeout writing communication packets',
    ],
    shutdown => [
        'WSREP has not yet prepared node for application use',
        'Server shutdown in progress',
    ],
    duplicate_value => [
        "Duplicate entry '12345' for key 'PRIMARY'",
        "Duplicate entry 'The wren\nEarns his living\nNoiselessly.' for key 'haiku'",
    ],
    unknown => [
        'MySQL client ran out of memory',
        "Can't read record in system table",
        'File name is too long',
    ],
);

foreach my $error_type (sort keys %ERRORS) {
    my $i = 0;
    foreach my $error_string (@{ $ERRORS{$error_type} }) {
        $i++;
        my $header = "$error_type $i";

        eval {
            die "DBI Exception: DBD::mysql::st execute failed: $error_string";
        };
        if ($@) {
            pass "$header: Has exception";
            my $parsed   = DBIx::ParseError::MySQL->new($@);
            my $got_type = $parsed->error_type;

            note $parsed->orig_error;
            is($got_type, $error_type, "$header: Right type");
            is(
                !!$parsed->is_transient,
                ($error_type eq 'lock' || $error_type eq 'connection' || $error_type eq 'shutdown'),
                "$header: is_transient set right",
            );
        }
        else {
            fail "$header: Has exception";
        }
    }
}

done_testing;
