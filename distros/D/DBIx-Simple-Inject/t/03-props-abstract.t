use strict;
use warnings;
use Test::More tests => 3;
use Test::Requires qw(
    DBI
    DBD::SQLite
    SQL::Abstract
    SQL::Abstract::Limit
    SQL::Maker
);

use DBI;

for my $abstract_class (qw/SQL::Abstract SQL::Abstract::Limit SQL::Maker/) {
    my $db = DBI->connect(
        'dbi:SQLite:dbname=:memory:', '', '', {
            RootClass => 'DBIx::Simple::Inject',
            private_dbixsimple => {
                abstract => $abstract_class,
            },
        }
    );
    
    isa_ok($db->abstract, $abstract_class, "abstract");
}
