#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 1;
use DBI;
use DBIx::Lite;

# Regression for https://github.com/alranel/DBIx-Lite/issues/32:
# dbh_do() must localize $_ so it does not clobber foreach aliases
# when constructed with new(dbh => ...).

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1 });
my $dbix = DBIx::Lite->new(dbh => $dbh);

$dbh->do('CREATE TABLE t (name TEXT, x INTEGER)');

my @names = qw(foo bar baz);

for (@names) {
    $dbix->table('t')->insert({ name => $_, x => 0 });
}

is_deeply \@names, [qw(foo bar baz)], 'insert inside for (@array) does not clobber $_ aliases';
