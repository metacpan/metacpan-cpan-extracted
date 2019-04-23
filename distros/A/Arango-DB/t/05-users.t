# -*- cperl -*-

use Arango::DB;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;

do "./t/helper.pl";

skip_all "No ArangoDB environment variables for testing. See README" unless valid_env_vars();
skip_all "Can't reach ArangoDB Server" unless server_alive(); 

my $arango = Arango::DB->new( );
clean_test_environment($arango);

my $ans = $arango->create_user('tmp_');
is $ans->{user}, "tmp_", "Looks like it was created";

$ans = $arango->delete_user('tmp_');
is $ans->{code}, 202, "Looks like it was deleted";

done_testing;

