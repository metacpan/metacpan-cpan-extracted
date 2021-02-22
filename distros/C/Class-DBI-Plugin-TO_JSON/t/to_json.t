use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;

###############################################################################
# Make sure that we've got DBD::SQLite and JSON::XS available; they're both
# needed for testing.
BEGIN {
    eval "use DBD::SQLite";
    my $missing_dbd_sqlite = $@;

    eval "use JSON::XS";
    my $missing_json_xs = $@;

    plan $missing_dbd_sqlite ? (skip_all => 'need DBD::SQLite for testing')
       : $missing_json_xs    ? (skip_all => 'need JSON::XS for testing')
       :                       (tests => 11);
};

###############################################################################
# Create some test DB table classes
{
    package MY::DB::UserHistory;
    use base qw(Class::DBI::Test::SQLite);
    use Class::DBI::Plugin::TO_JSON;
    __PACKAGE__->set_table( 'user_history' );
    __PACKAGE__->columns( All => qw(id user_id notes) );
    __PACKAGE__->has_a( user_id => 'MY::DB::User' );
    sub create_sql {
        return q{
            id          INTEGER PRIMARY KEY,
            user_id     INTEGER,
            notes       VARCHAR(255)
        };
    }

    package MY::DB::User;
    use base qw(Class::DBI::Test::SQLite);
    use Class::DBI::Plugin::TO_JSON;
    __PACKAGE__->set_table( 'user' );
    __PACKAGE__->columns( All => qw(id username email) );
    __PACKAGE__->has_many( history => 'MY::DB::UserHistory' );
    sub create_sql {
        return q{
            id          INTEGER PRIMARY KEY,
            username    VARCHAR(64),
            email       VARCHAR(255)
        };
    }
}

###############################################################################
# Make sure we can create test data in our DB tables.
create_test_data: {
    my $user = MY::DB::User->create( {
        id          => 1,
        username    => 'gtermars',
        email       => 'cpan@howlingfrog.com',
        } );
    isa_ok $user, 'MY::DB::User', 'created test user';

    my $history = $user->add_to_history( {
        id          => 2,
        notes       => 'stuff',
        } );
    isa_ok $history, 'MY::DB::UserHistory', '... with history';
}

###############################################################################
# Extract data from our DB tables and convert it to JSON.
convert_to_json: {
    # get History record
    my $history = MY::DB::UserHistory->retrieve_all()->first();
    isa_ok $history, 'MY::DB::UserHistory', 'got history record';

    # verify that the record has an inflated column
    my %hash = $history->_as_hash();
    ok %hash, '... and turned it into a hash';
    isa_ok $hash{user_id}, 'MY::DB::User', '... which has inflated user record';

    # convert to JSON
    my $json = JSON::XS->new->allow_blessed->convert_blessed->encode($history);
    ok $json, '... which can be converted to JSON';
    isnt $json, 'null', "... ... and which isn't just 'null'";

    # convert JSON back to data, and verify contents
    my $data = JSON::XS->new->decode($json);
    ok $data, '... which gets converted back to a Perl hash';
    is $data->{id},      2,         '... ... verify data: "id"';
    is $data->{user_id}, 1,         '... ... verify data: "user_id"';
    is $data->{notes},   'stuff',   '... ... verify data: "notes"';
}
