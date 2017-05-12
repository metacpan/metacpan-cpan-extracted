use strict;

use Test::More tests => 1;

use Bigtop::Parser qw/SQL=Postgres/;

my $bigtop_string = join '', <DATA>;

my $tree        = Bigtop::Parser->parse_string($bigtop_string);
my $lookup      = $tree->{application}{lookup};

my $output      = $tree->walk_postorder( 'output_sql', $lookup );
my @sql         = split /\n/, join '', @{ $output };

my @correct_sql = split /\n/, <<'EO_CORRECT_SQL';
CREATE SCHEMA my_schema;
CREATE SEQUENCE payeepayor_seq;
CREATE TABLE payeepayor (
    id int4 PRIMARY KEY DEFAULT NEXTVAL( 'payeepayor_seq' )
);

CREATE TABLE multiplier (
    id int4,
    subid int4,
    PRIMARY KEY( id, subid )
);

CREATE TABLE pointer (
    id int4 PRIMARY KEY,
    refer_to int4 REFERENCES payeepayor(id)
        ON DELETE CASCADE
        ON UPDATE NO ACTION,
    other varchar
);

CREATE TABLE pointer2 (
    id int4 PRIMARY KEY,
    refer_to int4
);
EO_CORRECT_SQL

is_deeply( \@sql, \@correct_sql, 'tiny sql' );

__DATA__
config { }
app Apps::Checkbook {
    schema my_schema { }
    sequence payeepayor_seq { }
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
        field refer_to {
            is int4;
            refers_to payeepayor => id;
            on_delete CASCADE;
            on_update `NO ACTION`;
        }
        field other { is varchar; }
    }
    table pointer2 {
        field id { is int4, primary_key; }
        field refer_to { is int4; refers_to payeepayor; }
    }
}
