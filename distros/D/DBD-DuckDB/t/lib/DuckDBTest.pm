package DuckDBTest;

use strict;
use warnings;
use v5.10;

use Test::More ();

use Exporter 'import';

use DBI ();

our @EXPORT = qw(connect_ok);

my $parent;
my %dbfiles;

BEGIN {
    $parent = $$;
}

sub dbfile { $dbfiles{$_[0]} ||= (defined $_[0] && length $_[0] && $_[0] ne ':memory:') ? $_[0] . $$ : $_[0] }

sub connect_ok {

    my $attr   = {@_};
    my $dbfile = dbfile(defined $attr->{dbfile} ? delete $attr->{dbfile} : ':memory:');
    my @params = ("dbi:DuckDB:dbname=$dbfile", '', '');

    if (%$attr) {
        push @params, $attr;
    }

    my $dbh = DBI->connect(@params);

    Test::More::isa_ok($dbh, 'DBI::db');
    return $dbh;

}

sub clean {

    return if $$ != $parent;

    for my $dbfile (values %dbfiles) {

        next           if $dbfile eq ':memory:';
        unlink $dbfile if -f $dbfile;

        my $wal = $dbfile . '.wal';
        unlink $wal if -f $wal;

    }

}

BEGIN { clean() }
END   { clean() }

1;
