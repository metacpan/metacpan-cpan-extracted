use strict;
use warnings;
use Test::More tests => 6;
use Test::Requires qw(
    DBI
    DBD::SQLite
);

use DBI;
my $db = DBI->connect(
    'dbi:SQLite:dbname=:memory:', '', '', {
        RootClass => 'DBIx::Simple::Inject',
        
        private_dbixsimple => {
            lc_columns      => 0,
            keep_statements => 20,
            result_class    => 'MyApp::Result',
            abstract        => sub {
                my $dbh = shift;
                isa_ok($dbh, 'DBI::db');
                isa_ok($dbh, 'DBIx::Simple::Inject::db');
                bless {}, 'MyApp::Abstract';
            },
        },
    }
);

is($db->lc_columns, 0, "lc_columns()");
is($db->keep_statements, 20, "keep_statements()");
is($db->result_class, "MyApp::Result", "result_class()");
isa_ok($db->abstract, "MyApp::Abstract", "abstract()");
