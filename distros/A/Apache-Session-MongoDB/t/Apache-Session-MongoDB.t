# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Apache-Session-MongoDB.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use utf8;

use Test::More tests => 11;
BEGIN { use_ok('Apache::Session::MongoDB') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

SKIP: {

    unless ( defined $ENV{MONGODB_SERVER} ) {
        skip 'MONGODB_SERVER is not set', 10;
    }
    my %h;
    my $args = { host => $ENV{MONGODB_SERVER} };

    ok( tie( %h, 'Apache::Session::MongoDB', undef, $args ), 'New object' );

    my $id;
    ok( $id = $h{_session_id}, '_session_id is defined' );
    $h{some}         = 'data';
    $h{utf8}         = 'éàèœ';
    $h{'dotted.key'} = 'test';
    $h{'dollar$key'} = 'test';

    untie %h;

    my %h2;
    ok(
        tie(
            %h2, 'Apache::Session::MongoDB',
            $id, { host => $ENV{MONGODB_SERVER} }
        ),
        'Access to previous session'
    );

    ok( $h2{some} eq 'data',         'Find data' );
    ok( $h2{utf8} eq 'éàèœ',     'UTF string' );
    ok( $h2{'dotted.key'} eq 'test', 'Dotted key' );
    ok( $h2{'dollar$key'} eq 'test', 'Dollar key' );
    Apache::Session::MongoDB->get_key_from_all_sessions($args);

    #binmode(STDERR, ":utf8");
    #print STDERR $h2{utf8}."\n";

    ok( ( tied(%h2)->delete or 1 ), 'Delete session' );

    unless ( defined $ENV{MONGODB_USER} and defined $ENV{MONGODB_DB_NAME} ) {

        skip 'MONGODB_USER and MONGODB_DB_NAME are not set', 2;
    }
    for my $w (qw(db_name username password)) {
        $args->{$w} = $ENV{ "MONGODB_" . uc($w) };
    }
    ok( tie( %h, 'Apache::Session::MongoDB', undef, $args ),
        'Authentified object' );
    ok( ( tied(%h)->delete or 1 ), 'Delete session' );
}
