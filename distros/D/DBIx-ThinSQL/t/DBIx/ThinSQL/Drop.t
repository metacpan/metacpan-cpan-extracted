use strict;
use warnings;
use lib 't/lib';
use DBIx::ThinSQL;
use DBIx::ThinSQL::Drop;
use Test::DBIx::ThinSQL qw/run_in_tempdir/;
use Test::Database;
use Test::Fatal qw/exception/;
use Test::More;

my $handle_count;

foreach my $handle ( Test::Database->handles(qw/SQLite Pg DBM/) ) {
    $handle_count++;

    run_in_tempdir {
        $handle->driver->drop_database( $handle->name )
          if $handle->dbd eq 'SQLite';

        my $db = DBIx::ThinSQL->connect(
            $handle->connection_info,
            {
                PrintError => 0,
                RaiseError => 1,
            }
        );

        if ( $handle->dbd eq 'DBM' ) {
            like exception { $db->drop_everything() },
              qr/unsupported/, 'DBM unsupported';
            return;
        }

        isa_ok( $db, 'DBIx::ThinSQL::db', 'DBIx::ThinSQL->connect' );
        undef $db;

        $db = DBI->connect(
            $handle->connection_info,
            {
                PrintError => 0,
                RaiseError => 1,
                RootClass  => 'DBIx::ThinSQL',
            }
        );

        isa_ok( $db, 'DBIx::ThinSQL::db', 'DBI->connect' );

        if ( $handle->dbd eq 'Pg' ) {
            $db->do('SET client_min_messages = WARNING;');
            $db->do("SET TIMEZONE TO 'UTC';");
        }

        if ( $handle->dbd eq 'SQLite' ) {
            $db->do('PRAGMA foreign_keys = ON;');
        }

        $db->drop_everything();
        my $table            = 'riik9Jay' . int( 100 * rand );
        my $table_identifier = $db->quote_identifier($table);
        $db->do("CREATE TABLE $table_identifier (name VARCHAR);");

        my $st = $db->table_info( '%', '%', '%' );
        ok scalar @{ $st->fetchall_arrayref }, 'have table_info';

        $db->drop_everything();
        $st = $db->table_info( '%', '%', $table );

        ok !scalar @{ $st->fetchall_arrayref }, 'have zero table_info';

    };
}

plan skip_all => 'No database handles available' unless $handle_count;

done_testing();
