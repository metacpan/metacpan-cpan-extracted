package TestDB;

use strict;
use warnings;

use DBI;

sub setup {
    my $self = shift;

    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    die $DBI::errorstr unless $dbh;

    $dbh->do("PRAGMA default_synchronous = OFF");
    $dbh->do("PRAGMA temp_store = MEMORY");

    return $dbh;
}

1;
