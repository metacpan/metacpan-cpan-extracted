package t::lib::Utils;
use utf8;
use strict;
use warnings;

sub import {
    strict->import;
    warnings->import;
    utf8->import;
}

my $dbh;
sub dbh {
    my $file = shift || ':memory:';
    eval qq{use DBI};

    $dbh ||= DBI->connect(
        "dbi:SQLite:$file", '', '', {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1,
        }
    );
}

!!1;
