use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 1 );
}

my $schema = DBICTest->init_schema;
ok(-f "t/var/DBIxClass.db", 'Database created');
