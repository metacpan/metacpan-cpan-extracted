use strict;

use File::Spec;
use Test::More tests => 1;
use Test::Files;

use Bigtop::Parser;

use lib 't';
use Purge;

my $dir         = File::Spec->catdir( qw( t db2 ) );
my $sql_file    = File::Spec->catfile(
    $dir, 'Apps-Checkbook', 'docs', 'schema.db2'
);

my $actual_dir  = File::Spec->catdir( $dir, 'Apps-Checkbook' );

Purge::real_purge_dir( $actual_dir );

my $bigtop_string = << "EO_Bigtop_STRING";
config {
    base_dir   `$dir`;
    SQL        DB2 {}
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int4, primary_key, assign_by_sequence; }
        field name  { is `varchar(20)`; }
        field user  { is varchar; }
        data
            name => `Gas Company`;
        data
            id   => 2,
            name => `Crow Business Center`;
    }
    literal SQL `CREATE INDEX payor_name_ind ON payeepayor ( name );`;
    table not_seen {
        not_for        SQL;
        field id       { is int4, primary_key; }
        field not_much { is varchar; }
    }
    table other {
        field id       { is int4, primary_key; }
    }
    join_table myschema.payeeor_other {
        joins payeepayor => other;
    }
}
EO_Bigtop_STRING

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'SQL', ],
    }
);

my $correct_sql = <<'EO_CORRECT_SQL';
DROP TABLE payeepayor;
CREATE TABLE payeepayor (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1, NO CACHE),
    name varchar(20),
    user VARCHAR(255),
    PRIMARY KEY( id )
);

INSERT INTO payeepayor ( name )
    VALUES ( 'Gas Company' );

INSERT INTO payeepayor ( id, name )
    VALUES ( 2, 'Crow Business Center' );

CREATE INDEX payor_name_ind ON payeepayor ( name );
DROP TABLE other;
CREATE TABLE other (
    id INTEGER,
    PRIMARY KEY( id )
);

DROP TABLE myschema.payeeor_other;
CREATE TABLE myschema.payeeor_other (
    id INTEGER PRIMARY KEY NOT NULL GENERATED ALWAYS AS IDENTITY
       ( START WITH 1, INCREMENT BY 1, NO CACHE ),
    payeepayor INTEGER REFERENCES payeepayor(id),
    other INTEGER REFERENCES other(id)
);
EO_CORRECT_SQL

file_ok( $sql_file, $correct_sql, 'tiny gened sql file' );

Purge::real_purge_dir( $actual_dir );
