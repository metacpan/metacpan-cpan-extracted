use Test2::V0 '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;

# schema I2: two columns that resolve to the same generated accessor name used
# to silently drop the second (hash-order winner). Column-vs-column collisions
# now croak, matching the link-vs-link collision behavior. Reuse the links
# schema (foo has foo_id + name, so a constant field_accessor hook collides).

sub SCHEMA_DIR { 't/links' }

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm my_orm => sub {
        db 'mydb';
        autofill sub {
            autorow 'ColClashRow';
            autoname field_accessor => sub { 'dup' };    # collapse every column to one name
        };
    };

    like(
        dies { orm('my_orm')->connect },
        qr/Cannot generate the 'dup' accessor.*both map to it/s,
        "two columns mapping to the same accessor name croak instead of silently dropping one",
    );
} 'sqlite';

done_testing;
