# -*- cperl -*-

use Arango::Tango;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;

do "./t/helper.pl";

skip_all "No ArangoDB environment variables for testing. See README" unless valid_env_vars();
skip_all "Can't reach ArangoDB Server" unless server_alive();

my $arango = Arango::Tango->new( );
clean_test_environment($arango);

my $ans = $arango->create_user('tmp_');
is $ans->{user}, "tmp_", "Looks like it was created";

my $users = $arango->list_users;
ok(exists($users->{result}));
is ref($users->{result}), "ARRAY";

my $user = $arango->user('tmp_');
ok $user->{active};

my $dbs = $arango->user_databases('tmp_');
ok exists($dbs->{result});
is scalar(keys %{$dbs->{result}}), 0;

$ans = $arango->delete_user('tmp_');
is $ans->{code}, 202, "Looks like it was deleted";

done_testing;

