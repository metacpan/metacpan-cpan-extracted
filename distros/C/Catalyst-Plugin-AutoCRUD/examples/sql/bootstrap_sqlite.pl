#!/usr/bin/perl

# this small program (originally written by Andy) will create an SQLite3 DB 
# from the .sql file in this same directory.
# just run it as: perl ./bootstrap_sqlite.pl

use DBI;
use Data::Dumper;

foreach my $name (qw/demo_app other_features/) {
    my $dbfile = "__autocrud_$name.sqlite";

    if (-e $dbfile) { unlink $dbfile or die "Failed to unlink $dbfile: $!"; }

    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile",'','',{ sqlite_unicode => 1 });

    open my $sql_fh, "$name.sql" or die "Can't read SQL file: $!";
    local $/ = "";  ## empty line(s) are delimeters
    while (my $sql = <$sql_fh>) {
        print $sql;
        $dbh->do($sql);
    }

    # to test it went in okay
    # print Dumper $dbh->selectall_arrayref('SELECT * FROM artist', { Slice => {} });

    $dbh->disconnect;
    close $sql_fh;
}
