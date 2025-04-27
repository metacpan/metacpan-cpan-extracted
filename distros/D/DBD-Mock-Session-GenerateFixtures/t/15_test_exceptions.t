

use strict;
use warnings;

use Test2::V0;

use lib qw(lib t);

use MyDatabase qw(db_handle build_tests_db populate_test_db);
use DBD::Mock::Session::GenerateFixtures;

use feature 'say';

use Try::Tiny;
use File::Path qw(rmtree);

my $dbh = db_handle('test.db');

# build_tests_db($dbh);
# populate_test_db($dbh);

subtest 'no mocked data is available' => sub {
    try {
        my $dbh = DBD::Mock::Session::GenerateFixtures->new()->get_dbh();
    } catch {
        my $error = $_;
        like($error, qr/No mocked data is available/, 'mocked data no found')
    };
};

subtest 'validate args' => sub {
    try {
        my $dbh = DBD::Mock::Session::GenerateFixtures->new([1, 2])->get_dbh();
    } catch {
        my $error = $_;
        like($error, qr/arguments to new must be hash/, 'arguments to new must be hash')
    };

    try {
        my $dbh = DBD::Mock::Session::GenerateFixtures->new({dbh => $dbh, file => 't/db_fixtures/14_upsert.t.json'})->get_dbh();
    } catch {
        my $error = $_;
        like($error, qr/to many args to new at/, 'to many args to new');
    };

    try {
        my $dbh = DBD::Mock::Session::GenerateFixtures->new({foo => 'var'})->get_dbh();
    } catch {
        my $error = $_;
        like($error, qr/Key not allowed:/, 'Key not allowed:');
    };
};

done_testing();
