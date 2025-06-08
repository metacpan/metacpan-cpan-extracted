use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;
use Hash::Merge qw/merge/;
Hash::Merge::set_behavior('RIGHT_PRECEDENT');

do_for_all_dbs {
    my $db = shift;

    db my_db => sub {
        dialect curdialect();

        if (curdialect() =~ m/MySQL/) {
            db_name 'quickdb';
            socket $db->socket;
            user $db->username;
            pass $db->password;
        }
        elsif (curdialect() =~ m/PostgreSQL/) {
            db_name 'quickdb';
            socket $db->dir;
            user $db->username;
            pass $db->password;
        }
        elsif (curdialect() =~ m/SQLite/) {
            db_name 'quickdb';
            db_name $db->dir . '/quickdb';
        }
    };

    orm my_orm => sub {
        db 'my_db';

        autofill;
    };

    ok(my $orm   = orm('my_orm')->connect,                         "Got a connection");
    ok(my $a_row = $orm->handle('example')->insert({name => 'a'}), "Inserted a row");

    # This prevents some issues where the DB takes too long and does not get
    # cleaned up properly.
    $DBIx::QuickORM::Test::END_DELAY = 1;
};

done_testing;
