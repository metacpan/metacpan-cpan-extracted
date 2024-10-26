package DBIx::QuickORM::Tester;
use strict;
use warnings;

use Test2::Tools::QuickDB;
use Test2::Tools::Subtest qw/subtest_buffered/;

use Importer 'Importer' => 'import';

BEGIN {
    $ENV{PATH} = "/home/exodist/percona/bin:$ENV{PATH}" if -d "/home/exodist/percona/bin";
}

our @EXPORT = qw{
    dbs_do
    all_dbs
};

my $psql    = eval { get_db({driver => 'PostgreSQL'}) } or diag(clean_err($@));
my $mysql   = eval { get_db({driver => 'MySQL'}) }      or diag(clean_err($@));
my $mariadb = eval { get_db({driver => 'MariaDB'}) }    or diag(clean_err($@));
my $percona = eval { get_db({driver => 'Percona'}) }    or diag(clean_err($@));
my $sqlite  = eval { get_db({driver => 'SQLite'}) }     or diag(clean_err($@));

sub clean_err {
    my $err = shift;

    my @lines = split /\n/, $err;

    my $out = "";
    while (@lines) {
        my $line = shift @lines;
        next unless $line;
        last if $out && $line =~ m{^Aborting at.*DBIx/QuickDB\.pm};

        $out = $out ? "$out\n$line" : $line;
    }

    return $out;
}

sub all_dbs { grep { $_->[1] } [PostgreSQL => $psql], [MySQL => $mysql], [MariaDB => $mariadb], [Percona => $percona], [SQLite => $sqlite] }

sub dbs_do {
    my ($subtest, $cb) = @_;
    my $caller = caller;

    for my $db_set (all_dbs()) {
        my ($name, $db) = @$db_set;

        $cb //= $caller->can($subtest);

        subtest_buffered("$subtest: $name" => sub { $cb->($name, $db, $subtest) });
    }

    return;
}

1;
