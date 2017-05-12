use strict;
use warnings;
use Test::More;
$| = 1;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 6);
    use File::Temp qw/tempfile/;
}

{
    package TestDB::Schema;
    use base qw(DBIx::Class::Schema);
    use strict;
    use warnings;

    sub create_table {
        my $class = shift;
        $class->storage->dbh_do(
            sub {
                my ($storage, $dbh, @cols) = @_;
                $dbh->do(q{
                    CREATE TABLE foo (
                        session_id VARCHAR(32) PRIMARY KEY,
                        u_rand_id  VARCHAR(32),
                        number     INT,
                        rand_id    VARCHAR(32),
                        rand_id2   VARCHAR(32)
                    )
                });
            },
        );
    }

    1;

    package TestDB::Schema::Foo;
    use strict;
    use warnings;
    use base qw/DBIx::Class/;

    __PACKAGE__->load_components(qw/RandomStringColumns Core/);
    __PACKAGE__->table('foo');
    __PACKAGE__->add_columns(qw(number rand_id rand_id2 session_id u_rand_id));
    __PACKAGE__->set_primary_key('session_id');
    __PACKAGE__->random_string_columns('u_rand_id');
    __PACKAGE__->random_string_columns('session_id', 'rand_id2');
    __PACKAGE__->random_string_columns('rand_id', {length => 3, salt => '[0-9]'});

    1;
}

my (undef, $DB) = tempfile();
my $schema = TestDB::Schema->connection("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });
END { unlink $DB if -e $DB }

ok($schema->create_table, 'create table');

TestDB::Schema->load_classes('Foo');

my $foo = $schema->resultset('Foo')->create({number => 3, u_rand_id => 'foo'});
is($foo->number, 3, 'can set number');
is($foo->u_rand_id, 'foo', 'no rewrite if set');
like($foo->session_id, qr/^[A-Za-z0-9]{32}$/, 'set random string column');
like($foo->rand_id,  qr/^[0-9]{3}$/, 'set random string column at rand_id');
like($foo->rand_id2, qr/^[A-Za-z0-9]{32}$/, 'set random string column at rand_id2');

