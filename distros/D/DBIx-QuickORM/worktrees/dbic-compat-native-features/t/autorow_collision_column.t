use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;

# The account table has a column literally named 'users' AND a foreign key
# user_id -> users. The unique relationship accessor also defaults to the target
# table name 'users', so it collides with the column accessor. Autofill must
# croak rather than silently dropping the relationship accessor.

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm collide_col => sub {
        db 'mydb';
        autofill sub { autorow 'Collide::Col'; };
    };

    my $err = dies { orm('collide_col')->connect };
    ok($err, "a relationship accessor colliding with a column accessor dies");
    like($err, qr/Cannot generate the 'users' accessor on row class \S*Account/, "names the accessor and row class");
    like($err, qr/the 'users' column accessor/, "blames the column accessor");
    like($err, qr/relationship to 'users'/,     "blames the relationship");
    like($err, qr/distinct alias|autoname/,     "suggests how to resolve it");
};

done_testing;
