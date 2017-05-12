# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use DBIx::ORM::Declarative;
ok(1); # If we made it this far, we're ok.

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
                table               => 'Table1',
                primary             => [ 'Column1T1', ],
                unique              => [ [ qw(Column2T1 Column3T1) ], ],
                select_null_primary => 'SELECT LAST_INSERT_ID()',
                columns =>
                [
                    { name    => 'Column1T1', },
                    { name    => 'Column2T1', },
                    { name    => 'Column3T1', },
                    { name    => 'Column4T1', },
                    { name    => 'Column5T1', },
                ],
            },
            {
                table               => 'Table2',
                primary             => [ 'Column1T2', ],
                select_null_primary => 'SELECT LAST_INSERT_ID()',
                columns =>
                [
                    { name    => 'Column1T2', },
                    { name    => 'Column2T2', },
                    { name    => 'Column3T2', },
                    { name    => 'Column4T2', },
                    { name    => 'Column5T2', },
                ],
            },
        ],
        joins =>
        [
            {
                name    => 'Join1',
                primary => 'Table1',
                tables =>
                [
                    {
                        table => 'Table2',
                        columns =>
                        {
                            Column2T1 => Column2T2,
                        },
                    },
                ],
            },
        ],
    },
) ;

my $db = DBIx::ORM::Declarative->new->Schema1->Table1;

ok($db->_class eq 'DBIx::ORM::Declarative::Schema::Schema1::Table1');

# Add a table on the fly, using the Join1 class
$db = $db->Join1;
$db->table(table => 'Table3', columns => [ { name => 'Column1T3' } ]);
$db = $db->Table3;
ok($db->_class eq 'DBIx::ORM::Declarative::Schema::Schema1::Table3');
ok($db->Join1->_class eq 'DBIx::ORM::Declarative::Schema::Schema1::Join1');
