package t::Utils;
use strict;
use warnings;
use DBI;
use Test::More;

BEGIN {
  eval "use DBD::SQLite";
  plan skip_all => 'needs DBD::SQLite for testing' if $@;
}

sub setup {
    my $dbh = DBI->connect('dbi:SQLite:');
    $dbh->do('create table foo (id INTEGER PRIMARY KEY, var text)');
    $dbh;
}

1;

