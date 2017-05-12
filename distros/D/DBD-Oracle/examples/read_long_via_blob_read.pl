#!/usr/bin/env perl

use strict;
use warnings;

use DBI;

my $dbh = DBI->connect( 'dbi:Oracle:mydb', 'username', 'password' );

$dbh->{RaiseError} = 1;
$dbh->{LongTruncOk} = 1; # truncation on initial fetch is ok

my $sth = $dbh->prepare("SELECT key, long_field FROM table_name");
$sth->execute;

while ( my ($key) = $sth->fetchrow_array) {
    my $offset = 0;
    my $lump = 4096; # use benchmarks to get best value for you
    my @frags;
    while (1) {
        my $frag = $sth->blob_read(1, $offset, $lump);
        last unless defined $frag;
        my $len = length $frag;
        last unless $len;
        push @frags, $frag;
        $offset += $len;
    }
    my $blob = join "", @frags;
    print "$key: $blob\n";
}

