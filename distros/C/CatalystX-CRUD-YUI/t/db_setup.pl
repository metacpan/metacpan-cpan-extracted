#!/usr/bin/perl

use strict;

# check for sqlite version per Rose::DB tests
eval { require DBD::SQLite };

if ( $@ || $DBD::SQLite::VERSION < 1.08 ) {
    croak 'Missing DBD::SQLite 1.08+';
}
elsif ( $DBD::SQLite::VERSION == 1.13 ) {
    carp 'DBD::SQLite 1.13 is broken but we will try testing anyway';
}

my $db = 't/yui.db';

if ( !-s $db ) {
    system("sqlite3 $db < t/yui.sql")
        and die "can't create $db: $!";
}

END { unlink($db) unless $ENV{PERL_DEBUG}; }
