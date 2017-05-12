use DBIx::Class::Schema::Loader::Optional::Dependencies
    -skip_all_without => qw(test_backcompat test_rdbms_oracle);

use strict;
use warnings;
use lib qw(t/backcompat/0.04006/lib);
use dbixcsl_common_tests;
use Test::More;

my $dsn      = $ENV{DBICTEST_ORA_DSN} || '';
my $user     = $ENV{DBICTEST_ORA_USER} || '';
my $password = $ENV{DBICTEST_ORA_PASS} || '';

dbixcsl_common_tests->new(
    vendor      => 'Oracle',
    auto_inc_pk => 'INTEGER NOT NULL PRIMARY KEY',
    auto_inc_cb => sub {
        my ($table, $col) = @_;
        return (
            qq{ CREATE SEQUENCE ${table}_${col}_seq START WITH 1 INCREMENT BY 1},
            qq{
                CREATE OR REPLACE TRIGGER ${table}_${col}_trigger
                BEFORE INSERT ON ${table}
                FOR EACH ROW
                BEGIN
                    SELECT ${table}_${col}_seq.nextval INTO :NEW.${col} FROM dual;
                END;
            }
        );
    },
    auto_inc_drop_cb => sub {
        my ($table, $col) = @_;
        return qq{ DROP SEQUENCE ${table}_${col}_seq };
    },
    dsn         => $dsn,
    user        => $user,
    password    => $password,
)->run_tests();
