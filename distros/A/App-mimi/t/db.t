use strict;
use warnings;

use lib 't/lib';

use Test::More;
use TestDB;

use App::mimi::db;

subtest 'returns false when no table' => sub {
    my $db = _build_db();

    ok !$db->is_prepared;
};

subtest 'returns true when table exists' => sub {
    my $db = _build_db();

    $db->prepare;

    ok $db->is_prepared;
};

subtest 'returns undef when no last migration' => sub {
    my $db = _build_db();

    $db->prepare;

    ok !defined $db->fetch_last_migration;
};

subtest 'fixes nothing when nothing to fix' => sub {
    my $db = _build_db();

    $db->prepare;
    $db->create_migration(no => 1, status => 'success');

    ok $db->fix_last_migration;
};

subtest 'fixes last migration' => sub {
    my $db = _build_db();

    $db->prepare;
    $db->create_migration(no => 1, status => 'error');

    $db->fix_last_migration;

    is $db->fetch_last_migration->{status}, 'success';
    is $db->fetch_last_migration->{error}, '';
};

subtest 'returns last migration' => sub {
    my $db = _build_db();

    $db->prepare;

    $db->create_migration(no => 1, status => 'success');
    $db->create_migration(no => 2, status => 'success');
    $db->create_migration(no => 3, status => 'success');

    my $last_migration = $db->fetch_last_migration;

    like $last_migration->{created}, qr/^\d+$/;
    is $last_migration->{no}, 3;
    is $last_migration->{status}, 'success';
};

done_testing;

sub _build_db {
    App::mimi::db->new(dbh => TestDB->setup);
}
