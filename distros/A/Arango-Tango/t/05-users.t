# -*- cperl -*-

use Arango::Tango;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;

do "./t/helper.pl";

skip_all "No ArangoDB environment variables for testing. See README" unless valid_env_vars();
skip_all "Can't reach ArangoDB Server" unless server_alive();

my $arango = Arango::Tango->new( );
clean_test_environment($arango);

## 1. Create User
my $ans = $arango->create_user('tmp_user_');
is $ans->{user}, "tmp_user_", "Looks like it was created";

## 2. List Users
my $users = $arango->list_users;
ok(exists($users->{result}));
is ref($users->{result}), "ARRAY";

## 3. Retrieve User Data
my $user = $arango->user('tmp_user_');
ok $user->{active};

## 4. Check New User Has No Database Access
my $dbs = $arango->user_databases('tmp_user_');
ok exists($dbs->{result});
is scalar(keys %{$dbs->{result}}), 0;

## 5. Create a database to test permissions
my $db = $arango->create_database('tmp_');

## 6. Ask about user access level to database

my $perms = $arango->get_access_level('tmp_user_', 'tmp_');
ok !$perms->{error};
is $perms->{result}, "none"; # no permission for the user

my $perms2 = $db->get_access_level('tmp_user_');
is $perms, $perms2, "Permissions are the same, getting them from different methods";

## 7. Create Collection
my $col = $db->create_collection('tmp_col');

$perms = $arango->get_access_level('tmp_user_', 'tmp_', 'tmp_col');
ok !$perms->{error};
is $perms->{result}, "none"; # no permission for the user
$perms2 = $db->get_access_level('tmp_user_', 'tmp_col');
is $perms, $perms2, "Permissions are the same, getting them from different methods";

$perms2 = $col->get_access_level('tmp_user_');
is $perms, $perms2, "Permissions are the same, getting them from different methods";

## 8. Update and Replace user

$ans = $arango->update_user('tmp_user_', extra => { email => q'me@there.com' });
ok !$ans->{error};
$user = $arango->user('tmp_user_');
is $ans->{extra}{email}, 'me@there.com';

$ans = $arango->replace_user('tmp_user_', extra => { phone => q'696969696' });
ok !$ans->{error};
$user = $arango->user('tmp_user_');
ok !exists($ans->{extra}{email});

## 9. Grant Permissions

$ans = $arango->set_access_level( 'tmp_user_', 'rw', 'tmp_');
is ($ans->{code}, 200);

$perms = $arango->get_access_level( 'tmp_user_', 'tmp_');
is ($perms->{result}, "rw");

$ans = $db->set_access_level('tmp_user_', 'ro');
is ($ans->{code}, 200);
$perms = $arango->get_access_level('tmp_user_', 'tmp_');
is ($perms->{result}, "ro");

$ans = $arango->set_access_level( 'tmp_user_', 'rw', 'tmp_', 'tmp_col');
is ($ans->{code}, 200);
$perms = $arango->get_access_level( 'tmp_user_', 'tmp_', 'tmp_col');
is ($perms->{result}, "rw");

$ans = $db->set_access_level( 'tmp_user_', 'none', 'tmp_col');
is ($ans->{code}, 200);
$perms = $arango->get_access_level( 'tmp_user_', 'tmp_', 'tmp_col');
is ($perms->{result}, "none");

$ans = $col->set_access_level('tmp_user_', 'rw');
is ($ans->{code}, 200);
$perms = $arango->get_access_level( 'tmp_user_', 'tmp_', 'tmp_col');
is ($perms->{result}, "rw");

$ans = $col->clear_access_level('tmp_user_');
is ($ans->{code}, 202);

{
    my $todo = todo "Need way to check default collection access level";

    $perms = $arango->get_access_level('tmp_user_', 'tmp_', 'tmp_col');
    is ($perms->{result}, "none");
}

$ans = $db->clear_access_level('tmp_user_');
is ($ans->{code}, 202);

{
    my $todo = todo "Need way to check default collection access level";

    $perms = $arango->get_access_level('tmp_user_', 'tmp_');
    is ($perms->{result}, "none");
}


## CLEANUP

$ans = $arango->delete_user('tmp_user_');
is $ans->{code}, 202, "Looks like it was deleted";

$arango->delete_database('tmp_');

done_testing;

