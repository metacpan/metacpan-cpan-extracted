use strict;

use Test::More tests => 1;

use Bigtop::Parser qw/SQL=SQLite/;

my $bigtop_string = join '', <DATA>;

my $tree        = Bigtop::Parser->parse_string($bigtop_string);
my $lookup      = $tree->{application}{lookup};

my $output      = $tree->walk_postorder( 'output_sql_lite', $lookup );

my @sql         = split /\n/, join '', @{ $output };

my @correct_sql = split /\n/, <<'EO_CORRECT_SQL';
CREATE TABLE payeepayor (
    id INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE multiplier (
    id INTEGER,
    subid INTEGER,
    PRIMARY KEY( id, subid )
);

CREATE TABLE pointer (
    id INTEGER PRIMARY KEY,
    refer_to INTEGER REFERENCES payeepayor(id),
    other varchar
);

CREATE TABLE pointer2 (
    id INTEGER PRIMARY KEY,
    refer_to INTEGER
);
EO_CORRECT_SQL

is_deeply( \@sql, \@correct_sql, 'tiny sql' );

__DATA__
config { }
app Apps::Checkbook {
    sequence payeepayor_seq {}
    table payeepayor {
        field id    { is int4, primary_key, assign_by_sequence; }
        sequence payeepayor_seq;
    }
    table multiplier {
        field id    { is int4, primary_key; }
        field subid { is int4, primary_key; }
    }
    table pointer {
        field id { is int4, primary_key; }
        field refer_to { is int4; refers_to payeepayor => id; }
        field other { is varchar; }
    }
    table pointer2 {
        field id { is int4, primary_key; }
        field refer_to { is int4; refers_to payeepayor; }
    }
}
