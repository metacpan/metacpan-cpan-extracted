# $Id: cdbi.t 10 2005-11-15 22:19:45Z evdb $
# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use lib qw( lib t );
use Data::Dumper;

use Test::More 'no_plan';

# Check that the module can be used.
use_ok 'Class::DBI::DFV';
use_ok 'Local::Test';

{    # create the table in the database.

    # Silence the warnings.
    local $SIG{__WARN__} = sub { 1 };

    ok(
        Local::Test->db_Main->do(
                "create table cdbi_tests (           "
              . "    id integer primary key,         "
              . "    val_unique text not null unique,"
              . "    val_optional text,              "
              . "    dup_a text,                     "
              . "    dup_b text                      "
              . ");                                  "
        ),
        "Created the test table."
    );
}

{    # Create a valid test object.
    my $test =
      Local::Test->create(
        { val_unique => 'test', val_optional => 'opt test' } );
    ok $test, "Created a test object";
    is $test->val_unique,   'test',     "check unique";
    is $test->val_optional, 'opt test', "check optional";

    # Change the value and check that it is trimmed.
    ok $test->val_optional('  optional  '), "set optional";
    is $test->val_optional, 'optional', "check optional";

    # Update the row and save it.
    ok $test->update,       "update to save the new value";
    is $test->val_unique,   'test', "check unique";
    is $test->val_optional, 'optional', "check optional";
}

{    # Try to create another object with duplicated val_unique
    ok !eval { Local::Test->create( { val_unique => 'test' } ); 1; },
      "Check to see that it is not possible to duplicate value";

    # See if there is an error message.
    is(
        Local::Test->dfv_results->msgs->{val_unique},
        'validation error: duplicate',
        "check that the message is correct"
    );
}

{    # Test that duplicate columns are checked correctly.
    for my $A ( 'A', 'B' ) {
        for my $B ( 'A', 'B' ) {

            my $id = $A . $B;

            my $object =
              Local::Test->create(
                { val_unique => $id, dup_a => $A, dup_b => $B } );

            # warn $object->id;
            ok $object, "create dup check '$id'";

            #ok Local::Test->retrieve( val_unique => 'AA' ),
            #  "check that the entry is there.";
        }
    }

    # check that the duplicate that we hope to access is in DB.
    ok Local::Test->retrieve( dup_a => 'A', dup_b => 'A' ),
      "check that the entry is there.";

    # Now try to create a duplicate;
    ok(
        !eval {
            Local::Test->create(
                { val_unique => 'duplicate test', dup_a => 'A', dup_b => 'A' }
            );

        },
        "try to create a duplicate over several rows"
    );

#warn Dumper Local::Test->db_Main->selectall_hashref( "select * from cdbi_tests", 'val_unique' );

}

# Drop the table.
ok( Local::Test->db_Main->do("drop table cdbi_tests"), "drop the test table" );

1;
