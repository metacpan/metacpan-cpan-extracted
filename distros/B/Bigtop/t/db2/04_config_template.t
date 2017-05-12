use strict;

use Test::More tests => 1;
use Test::Files;
use File::Spec;

use Bigtop::Parser;

use lib 't';
use Purge;

my $base_dir = File::Spec->catdir( 't', 'db2' );
my $template = File::Spec->catfile( $base_dir, 'ext.tt' );

my $doomed_dir = File::Spec->catdir( $base_dir, 'Apps-Checkbook' );
Purge::real_purge_dir( $doomed_dir );

my $bigtop_string = <<"EO_BIGTOP";
config {
    base_dir `$base_dir`;
    SQL DB2 {
        template `$template`;
    }
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int4, primary_key, assign_by_sequence; }
    }
}
EO_BIGTOP

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'SQL', ],
    }
);

my $correct_sql = <<'EO_CORRECT_SQL';
CREATE TABLE payeepayor {
    id =     INTEGER:NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1, NO CACHE);
    PRIMARY KEY( id )}

EO_CORRECT_SQL

my $docs_dir = File::Spec->catdir( $base_dir, 'Apps-Checkbook', 'docs' );
my $sql_file = File::Spec->catfile( $docs_dir, 'schema.db2' );

file_ok( $sql_file, $correct_sql, 'template through gen_from' );

Purge::real_purge_dir( $doomed_dir );
