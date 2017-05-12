use strict;

use Test::More;

# To run this test, you need a postgresql 8 database called kids2.  There
# is a dump of mine in the same directory as this script called:
#   kids2.pg_dump
# That database must be accessible by the postgres user without password.
# Beware of the security considerations of that.
# With the database in place, you still need to set the BIGTOP_PGLIVE
# shell environment variable to a true value (like 1) for the test to run.

BEGIN {
    plan skip_all => 'set BIGTOP_PGLIVE to enable test, must have kids2 db'
            unless $ENV{BIGTOP_PGLIVE};
    plan tests => 1;
}

use Bigtop::ScriptHelp::Style;
my $style = Bigtop::ScriptHelp::Style->get_style( 'Pg8Live' );

my $db_layout = $style->get_db_layout( 'dbi:Pg:dbname=kids2 postgres' );

my $correct_layout = {
    all_tables => { parent => 1, child => 1, },
    new_tables => [ 'child', 'parent' ],
    foreigners => {
        child => [ { table => 'parent', col => 1 } ],
    },
    columns => {
        parent => [
          { name => 'id',        types => [ 'int4', 'primary_key', 'auto' ] },
          { name => 'names',     types => [ 'varchar'  ] },
          { name => 'address',   types => [ 'varchar'  ] },
          { name => 'created',   types => [ 'datetime' ] },
          { name => 'modified',  types => [ 'datetime' ] },
          { name => 'city',      types => [ 'varchar'  ] },
          { name => 'state',     types => [ 'varchar'  ],
                               default => 'KS' },
          { name => 'zip',       types => [ 'varchar' ] },
          { name => 'phone',     types => [ 'varchar' ] },
        ],
        child => [
          { name => 'id',        types => [ 'int4', 'primary_key', 'auto' ] },
          { name => 'name',      types => [ 'varchar' ] },
          { name => 'birth_day', types => [ 'date' ] },
          { name => 'created',   types => [ 'datetime' ] },
          { name => 'modified',  types => [ 'datetime' ] },
        ],
    },
};

is_deeply( $db_layout, $correct_layout );
