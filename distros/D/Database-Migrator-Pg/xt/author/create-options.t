# This is in xt/ because of the /usr/bin/createdb path. It could differ on
# other systems, and I'm happy to just test this on my own system for now.
use strict;
use warnings;

use Pg::CLI::createdb;
use Test::More 0.88;

use Database::Migrator::Pg;
use Pg::CLI::createdb;

my %tests = (
    'no options' => {
        options => { database => 'test' },
        expect  => [qw( /usr/bin/createdb -w test )],
    },
    'encoding' => {
        options => {
            database => 'test',
            encoding => 'UTF-8',
        },
        expect => [qw( /usr/bin/createdb -w --encoding UTF-8 test )],
    },
    'locale' => {
        options => {
            database => 'test',
            locale   => 'en-US.UTF-8',
        },
        expect => [qw( /usr/bin/createdb -w --locale en-US.UTF-8 test )],
    },
    'lc_collate' => {
        options => {
            database   => 'test',
            lc_collate => 'en-US.utf8',
        },
        expect => [qw( /usr/bin/createdb -w --lc-collate en-US.utf8 test )],
    },
    'lc_ctype' => {
        options => {
            database => 'test',
            lc_ctype => 'en_IN',
        },
        expect => [qw( /usr/bin/createdb -w --lc-ctype en_IN test )],
    },
    'owner' => {
        options => {
            database => 'test',
            owner    => 'foo',
        },
        expect => [qw( /usr/bin/createdb -w --owner foo test )],
    },
    'tablespace' => {
        options => {
            database   => 'test',
            tablespace => 'foo',
        },
        expect => [qw( /usr/bin/createdb -w --tablespace foo test )],
    },
    'template' => {
        options => {
            database => 'test',
            template => 'template42',
        },
        expect => [qw( /usr/bin/createdb -w --template template42 test )],
    },
    'many options' => {
        options => {
            database   => 'test',
            encoding   => 'UTF-8',
            owner      => 'bob',
            tablespace => 'spacey',
            template   => 'template42',
        },
        expect => [
            qw( /usr/bin/createdb -w --encoding UTF-8 --owner bob --tablespace spacey --template template42 test )
        ],
    },
);

my $command;
no warnings 'redefine';

## no critic (Variables::ProtectPrivateVars)
local *Pg::CLI::createdb::_call_run3 = sub { $command = $_[1] };
## use critic

for my $test ( sort keys %tests ) {
    undef $command;

    my %params = %{ $tests{$test}{options} };
    $params{quiet}           = 1;
    $params{migration_table} = 'Migration';
    $params{migrations_dir}  = '/dev/null';
    $params{schema_file}     = '/dev/null';

    Database::Migrator::Pg->new(%params)->_create_database;

    is_deeply(
        $command,
        $tests{$test}{expect},
        "got expected command for $test"
    );
}

done_testing;
