use strict;
use warnings;

use Cwd qw(realpath);
use Test::More;
use Test::Exception;
use DBIx::Pg::CallFunction;

# test we can connect to a postgres on localhost
# create some test functions
# check if return is expected

(my $sqlfile = __FILE__) =~ s/\.t/.sql/;
(my $dir = realpath($sqlfile)) =~ s:/t/[^/]+$::;

# create test db
my $dbname = "dbix_pg_callfunction_test".$$;
system("createdb --echo $dbname") == 0
    or plan skip_all => "Can't run createdb (PostgreSQL not installed?)";

my $dbh = eval { DBI->connect("dbi:Pg:dbname=$dbname", undef, undef, { PrintError => 0 }) }
    or plan skip_all => "Can't connect to local database: $@";

$dbh->{pg_server_version} >= 90000
    or plan skip_all => "Requires PostgreSQL 9.0 or later";

plan tests => 15;

$dbh->begin_work;
# silence "NOTICE: function does not exist, skipping"
$dbh->do("set session client_min_messages = warning");
$dbh->do("drop function if exists get_userid_by_username(text)");
$dbh->do("drop function if exists get_user_hosts(integer)");
$dbh->do("drop function if exists get_user_details(integer)");
$dbh->do("drop function if exists get_user_friends(integer)");
$dbh->do("drop function if exists same_name_same_input_arguments(integer)");
$dbh->do("drop function if exists same_name_same_input_arguments(text)");
$dbh->do("drop function if exists test_default_values(text, text, text, text)");
$dbh->commit;

my $sql = do { # slurp!
    open my $fh, $sqlfile or die "Can't open $sqlfile: $!";
    local $/;
    <$fh>
};
$dbh->do($sql);

my $pg = DBIx::Pg::CallFunction->new($dbh);

my $now = $pg->random();
like($now, qr/^0\.\d+$/, 'function with no arguments called okay');

my $userid = $pg->get_userid_by_username({username => 'joel'});
is($userid, 123, 'single-row single-column');

my $hosts = $pg->get_user_hosts({userid => 123});
ok(eq_array($hosts, ['127.0.0.1','192.168.0.1','10.0.0.1']), 'multi-row single-column');

my $user_details = $pg->get_user_details({userid => 123});
ok(eq_hash($user_details, {firstname => 'Joel', lastname => 'Jacobson', creationdate => '2012-05-25'}), 'single-row multi-column');

my $user_friends = $pg->get_user_friends({userid => 123});

ok(eq_array($user_friends, [
    {userid => 234, firstname => 'Claes',  lastname => 'Jakobsson', creationdate => '2012-05-26'},
    {userid => 345, firstname => 'Magnus', lastname => 'Hagander',  creationdate => '2012-05-27'},
    {userid => 456, firstname => 'Lukas',  lastname => 'Gratte',    creationdate => '2012-05-28'}
]), 'multi-row multi-column');

throws_ok( sub{ $pg->same_name_same_input_arguments({foo => 123}) }, qr/multiple functions matches the same input arguments, function: same_name_same_input_arguments/, 'multiple function match caught okay' );

throws_ok( sub{ $pg->i_do_not_exist({bar => 123}) }, qr/no function matches the input arguments, function: i_do_not_exist/, 'no function match caught okay' );

throws_ok( sub{ $pg->get_user_hosts({userid => 'joel'}) }, qr/Call to get_user_hosts failed: .*? invalid input syntax for integer: "joel"/, 'caught input syntax error' );

my $default_values_filled = $pg->test_default_values({one => 'one', two => 'two', three=> '3', four => '4'});
like($default_values_filled, qr/^onetwo34$/, 'function with default values filled');

my $default_one_value_filled = $pg->test_default_values({one => 'one', two => 'two', three => '3'});
like($default_one_value_filled, qr/^onetwo3four$/, 'function with one default value filled');

my $default_no_value_filled = $pg->test_default_values({one => 'one', two => 'two'});
like($default_no_value_filled, qr/^onetwothreefour$/, 'function without default values filled');

throws_ok( sub { $pg->test_default_values({one => 'one'}) }, qr/no function matches the input arguments, function: test_default_values/, 'try calling function without all required input arguments' );
throws_ok( sub { $pg->test_default_values({one => 'one', two => 'two', three=> '3', four => '4', five => '5'}) }, qr/no function matches the input arguments, function: test_default_values/, 'try calling function with too many input arguments' );
throws_ok( sub { $pg->test_default_values({three=> '3', four => '4'}) }, qr/no function matches the input arguments, function: test_default_values/, 'try calling function with too few required input arguments' );
like(
    $pg->test_default_values({one => 'one', two => 'two', four => '4'}),
    qr/^onetwothree4$/,
    'try calling function where input argument three is not specified'
);

END {
    $dbh->disconnect if $dbh;
    system("dropdb --echo $dbname");
}
