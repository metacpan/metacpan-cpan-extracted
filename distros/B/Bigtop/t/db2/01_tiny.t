use strict;

use Test::More tests => 1;

use Bigtop::Parser qw/SQL=DB2/;

my $bigtop_string = join '', <DATA>;

my $tree        = Bigtop::Parser->parse_string($bigtop_string);
my $lookup      = $tree->{application}{lookup};

my $output      = $tree->walk_postorder( 'output_sql_db2', $lookup );

my @sql         = split /\n/, join '', @{ $output };

my @correct_sql = split /\n/, <<'EO_CORRECT_SQL';
DROP TABLE payeepayor;
CREATE TABLE payeepayor (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1, NO CACHE),
    PRIMARY KEY( id )
);

DROP TABLE multiplier;
CREATE TABLE multiplier (
    id INTEGER,
    subid INTEGER,
    PRIMARY KEY( id, subid )
);

DROP TABLE pointer;
CREATE TABLE pointer (
    id INTEGER,
    refer_to INTEGER REFERENCES payeepayor(id),
    other VARCHAR(255),
    PRIMARY KEY( id )
);

DROP TABLE pointer2;
CREATE TABLE pointer2 (
    id INTEGER,
    refer_to INTEGER,
    PRIMARY KEY( id )
);
EO_CORRECT_SQL

is_deeply( \@sql, \@correct_sql, 'tiny sql' );

__DATA__
config { }
app Apps::Checkbook {
    sequence payeepayor_seq {}
    table payeepayor {
        field id    { is int4, primary_key, auto; }
        sequence payeepayor_seq;
    }
    table multiplier {
        field id    { is int4, primary_key; }
        field subid { is int4, primary_key; }
    }
    table pointer {
        field id { is int4, primary_key; }
        field refer_to {
            is int4;
            refers_to payeepayor => id;
        }
        field other { is varchar; }
    }
    table pointer2 {
        field id { is int4, primary_key; }
        field refer_to { is int4; refers_to payeepayor; }
    }
}
