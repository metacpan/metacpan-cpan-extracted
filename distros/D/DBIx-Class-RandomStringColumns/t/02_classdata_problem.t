use strict;
use warnings;
use Test::More;
$| = 1;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 1);
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
                        id  VARCHAR(32) PRIMARY KEY,
                        xxx VARCHAR(32)
                    )
                });
            },
        );
        
        $class->storage->dbh_do(
            sub {
                my ($storage, $dbh, @cols) = @_;
                $dbh->do(q{
                    CREATE TABLE bar (
                        id  VARCHAR(32) PRIMARY KEY,
                        xxx VARCHAR(32)
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
    __PACKAGE__->add_columns(qw(id xxx));
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->random_string_columns('xxx'); # foo.xxx is random_string_columns
    
    1;

    package TestDB::Schema::Bar;
    use strict;
    use warnings;
    use base qw/DBIx::Class/;

    __PACKAGE__->load_components(qw/RandomStringColumns Core/); # load but not use
    __PACKAGE__->table('bar');
    __PACKAGE__->add_columns(qw(id xxx));
    
    # bar.xxx is NOT random_string_columns

    1;
}

my (undef, $DB) = tempfile();
my $schema = TestDB::Schema->connection("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });
END { unlink $DB if -e $DB }

$schema->create_table;

TestDB::Schema->load_classes('Bar');

my $bar = $schema->resultset('Bar')->create({ id => 1 });

is($bar->xxx, undef, 'no random_string_columns column');
