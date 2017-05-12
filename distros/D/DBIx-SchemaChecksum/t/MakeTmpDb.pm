package MakeTmpDb;
use strict;
use warnings;
use File::Temp qw(tempfile);
use File::Copy;
use DBI;

sub setup {
    my ($fh, $filename) = tempfile();
    copy('t/dbs/database.tpl',$filename) || die "Cannot copy database to tempfile $filename: $!";
    return $filename;
}

sub dbh {
    return DBI->connect(dsn());
}

sub dsn {
    my $filename = setup();
    return "dbi:SQLite:dbname=$filename";
}

1;
