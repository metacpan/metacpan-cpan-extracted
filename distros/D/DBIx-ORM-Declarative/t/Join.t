# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN
{
    require "t/mysqlinfo.pl";
    our $dsn;
    if($dsn)
    {
        plan tests => 5;
    }
    else
    {
        plan skip_all => "See README.MySQL to enable this test";
    }
};
use DBIx::ORM::Declarative;
use DBI;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

DBIx::ORM::Declarative->import
(
    {
        schema => 'Schema1',
        tables =>
        [
            {
                table               => 'address',
                primary             => [ 'recid', ],
                unique              =>
                [
                    [ qw(addr1 city state), ],
                    [ qw(addr1 zip), ],
                ],
                select_null_primary => 'SELECT LAST_INSERT_ID()',
                columns =>
                [
                    { name    => 'recid', },
                    { name    => 'addr1', },
                    { name    => 'addr2', },
                    { name    => 'city', },
                    { name    => 'state', },
                    { name    => 'zip', },
                ],
            },
            {
                table               => 'person',
                primary             => [ 'recid', ],
                unique              =>
                [
                    [ qw(name home_addr_id), ],
                    [ 'email' ],
                ],
                select_null_primary => 'SELECT LAST_INSERT_ID()',
                columns =>
                [
                    { name    => 'recid', },
                    { name    => 'name', },
                    { name    => 'home_addr_id', },
                    { name    => 'work_addr_id', },
                    { name    => 'email', },
                    { name    => 'phone', },
                ],
            },
        ],
        table_aliases =>
        {
            home_addr => 'address',
            work_addr => 'address',
        },
        joins =>
        [
            {
                name => 'person_data',
                primary => 'person',
                tables =>
                [
                    {
                        table => 'home_addr',
                        columns =>
                        {
                            home_addr_id => 'recid',
                        },
                    },
                    {
                        table => 'work_addr',
                        columns =>
                        {
                            work_addr_id => 'recid',
                        },
                    },
                ],
            },
        ],
    },
) ;

my $dbh = DBI->connect($dsn, $user, $pass);
ok($dbh);

die "Can't continue without a database handle\n" unless $dbh;

my $db = new DBIx::ORM::Declarative handle => $dbh;
my $sc = $db->Schema1;
ok($sc);

my $join = $sc->person_data;
ok($join);

# Create a join object
my $res = $join->create(
    home_addr_addr1 => '123 Anystreet',
    home_addr_city => 'Anytown',
    home_addr_state => 'AS',
    home_addr_zip => '12345',
    work_addr_addr1 => '123 Anystreet',
    work_addr_city => 'Anytown',
    work_addr_state => 'AS',
    work_addr_zip => '12345',
    name => 'Pudding Tame',
    email => 'pudding@ptame.ptame',
    phone => '123 456 7890',
) ;

ok($res);
ok($res->home_addr_addr1 eq '123 Anystreet');

# Clean up
$sc->work_addr->delete;
$sc->person->delete;
