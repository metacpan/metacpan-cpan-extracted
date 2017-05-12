use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 1 );       
}

use lib qw(t/lib);

use_ok('DBIx::Class::DigestColumns');