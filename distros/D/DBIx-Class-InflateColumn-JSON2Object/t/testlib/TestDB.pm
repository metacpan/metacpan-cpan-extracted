package testlib::TestDB;
use strict;
use warnings;
use DBI;
use testlib::Schema;

sub import {
    my $class  = shift;
    my $caller = caller();

    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=:memory:",
        "", "",
        {   RaiseError     => 1,
            sqlite_unicode => 1,
        }
    );

    $dbh->do( "
CREATE TABLE test (
    id integer primary key not null,
    no_class text,
    fixed_class text,
    data text,
    type text
);
" );

    my $schema = testlib::Schema->connect( sub {$dbh} );

    {
        no strict 'refs';
        *{ $caller . '::dbh' }    = \$dbh;
        *{ $caller . '::schema' } = \$schema;
    }
}

1;
