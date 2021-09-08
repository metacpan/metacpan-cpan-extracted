# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Apache-Session-MongoDB.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use utf8;

use Test::More tests => 24;
BEGIN { use_ok('Apache::Session::MongoDB') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

SKIP: {

    unless ( defined $ENV{MONGODB_SERVER} ) {
        skip 'MONGODB_SERVER is not set', 23;
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

    # Create a few sessions to test deleteIfLowerThan
    my @delSessions;
    push @delSessions,
      newsession( $args, type => "persistent", ttl => 100 ),
      newsession( $args, type => "persistent", ttl => 10 ),
      newsession( $args, type => "temporary",  ttl => 100 ),
      newsession( $args, type => "temporary",  ttl => 10 ),
      newsession( $args, type => "temporary",  ttl => 100, actttl => 10 ),
      newsession( $args, type => "temporary",  ttl => 10 );

    is(
        keys
          %{ Apache::Session::MongoDB->searchOn( $args, "type", "persistent" )
          },
        2,
        "Check correct number of permanent sessions"
    );
    is(
        keys
          %{ Apache::Session::MongoDB->searchOn( $args, "type", "temporary" ) },
        4,
        "check correct number of temp sessions"
    );

    my ( $status, $count ) = Apache::Session::MongoDB->deleteIfLowerThan(
        $args,
        {
            not => { 'type' => 'persistent' },
            or  => {
                ttl    => 50,
                actttl => 50,
            }
        }
    );
    is( $status, 1, "reported success" );
    is( $count,  3, "3 sessions deleted" );

    # Make sure success is correctly returned as a scalar when no job is done
    $status = Apache::Session::MongoDB->deleteIfLowerThan(
        $args,
        {
            not => { 'type' => 'persistent' },
            or  => {
                ttl    => 50,
                actttl => 50,
            }
        }
    );
    is( $status, 1, "Status is OK" );

    is(
        keys
          %{ Apache::Session::MongoDB->searchOn( $args, "type", "persistent" )
          },
        2,
        "Check correct number of permanent sessions"
    );
    is(
        keys
          %{ Apache::Session::MongoDB->searchOn( $args, "type", "temporary" ) },
        1,
        "check correct number of temp sessions"
    );

    # Delete sessions
    for (@delSessions) {
        my %h;
        eval {
            tie( %h, 'Apache::Session::MongoDB', $_, $args );
            tied(%h)->delete;
        }
    }

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

sub newsession {
    my ( $args, %data ) = @_;
    my %h;
    ok( tie( %h, 'Apache::Session::MongoDB', undef, $args ), 'New object' );
    for ( keys %data ) {
        $h{$_} = $data{$_};
    }
    my $id = $h{_session_id};
    untie(%h);
    return $id;
}
