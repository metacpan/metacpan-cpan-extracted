use strict;
use warnings;
use lib 't/lib';
use Test::More;
use DBIx::ThinSQL;
use DBIx::ThinSQL::Deploy;
use DBIx::ThinSQL::Drop;
use Path::Tiny;
use Test::DBIx::ThinSQL qw/run_in_tempdir/;
use Test::Database;

my ( $dir1, $dir2 );

BEGIN {
    $dir1 = path(qw/t share deploy/)->absolute;
    $dir2 = path(qw/t share deploy2/)->absolute;
}

plan skip_all => 'No database handles to test'
  unless Test::Database->handles(qw/SQLite Pg/);

foreach my $handle ( Test::Database->handles(qw/SQLite Pg/) ) {

    $handle->driver->drop_database( $handle->name )
      if $handle->dbd eq 'SQLite';

    run_in_tempdir {
        my $db = DBIx::ThinSQL->connect(
            $handle->connection_info,
            {
                PrintError => 0,
                RaiseError => 1,
            }
        );

        if ( $handle->dbd eq 'Pg' ) {
            $db->do('SET client_min_messages = WARNING;');
            $db->do("SET TIMEZONE TO 'UTC';");
        }

        if ( $handle->dbd eq 'SQLite' ) {
            $db->do('PRAGMA foreign_keys = ON;');
        }

        $db->drop_everything();

        my $file1 = $dir1->child('1.sql');
        my $ret;
        my $prev_id;

        $prev_id = $db->last_deploy_id;
        is $prev_id, 0, 'Nothing deployed yet: ' . $prev_id;

        $ret = $db->deploy_file($file1);
        is $ret, 2, 'deployed to ' . $ret;

        $prev_id = $db->last_deploy_id;
        is $prev_id, 2, 'last id check';

        $ret = $db->deploy_file($file1);
        is $ret, 2, 'still deployed to ' . $ret;

        $prev_id = $db->last_deploy_id;
        is $prev_id, 2, 'still last id check';

        $ret = $db->deploy_dir($dir1);
        is $ret, 3, 'upgraded to ' . $ret;

        $db->drop_everything();

        $prev_id = $db->last_deploy_id;
        is $prev_id, 0, 'Nothing deployed yet: ' . $prev_id;

        $ret = $db->deploy_dir($dir1);
        is $ret, 3, 'deployed to ' . $ret;

        $prev_id = $db->last_deploy_id;
        is $prev_id, 3, 'last id check';

        $ret = $db->deploy_dir($dir1);
        is $ret, 3, 'still deployed to ' . $ret;

        $prev_id = $db->last_deploy_id;
        is $prev_id, 3, 'still last id check';

        $ret = $db->deploy_dir($dir2);
        is $ret, 5, 'upgraded to ' . $ret;

        my $table_info = $db->deployed_table_info;

        isa_ok( $table_info, 'HASH' );

        is_deeply(
            [ sort keys %$table_info ],
            [qw/_deploy actors film_actors films/],
            'deployed_table_info'
        );
    };
}
done_testing();
