use strict;
use warnings;
use Test::Spec;

use FindBin qw/ $Bin /;
use lib "$Bin/../lib";

use_ok( 'API::BigBlueButton' );

describe "Get version" => sub {
    it "Normal run" => sub {
        my $url;

        API::BigBlueButton->expects( 'request' )
            ->returns( sub { $url = $_[1]; return 1; } )->at_least(1);

        my $bbb = API::BigBlueButton->new(
            secret => 'mysecret',
            server => 'myserver',
        );

        ok( $bbb->get_version );
        is( $url, 'http://myserver/bigbluebutton/api' );
    };
};

describe "Other requests" => sub {
    my ( $bbb, $url );

    before all => sub {
        $bbb = API::BigBlueButton->new(
            secret => 'mysecret',
            server => 'myserver',
        );
    };

    before each => sub {
        undef $url;
        API::BigBlueButton->expects( 'request' )
            ->returns( sub { $url = $_[1]; return 1; } )->any_number;
    };

    describe "create" => sub {
        it "Normal run" => sub {
            ok( $bbb->create( meetingID => 'mymeeting' ) );
            like( $url, qr/create\?meetingID=mymeeting/ );
        };

        it "Empty meetingID" => sub {
            eval { $bbb->create };
            ok( $@ );
            like( $@, qr/Parameter meetingID required!/ );
        };
    };

    describe "join" => sub {
        it "Normal run" => sub {
            ok( $bbb->join(
                fullName  => 'myname',
                meetingID => 'mymeeting',
                password  => 'mypass',
                )
            );
            like( $url, qr/join\?fullName=myname&meetingID=mymeeting&password=mypass/ );
        };
    };

    describe "ismeetingrunning" => sub {
        it "Normal run" => sub {
            ok( $bbb->ismeetingrunning( meetingID => 'mymeeting' ) );
            like( $url, qr/isMeetingRunning\?meetingID=mymeeting/ );
        };
    };

    describe "end" => sub {
        it "Normal run" => sub {
            ok( $bbb->end( meetingID => 'mymeeting', password  => 'mypass' ) );
            like( $url, qr/end\?meetingID=mymeeting&password=mypass/ );
        }
    };

    describe "getmeetinginfo" => sub {
        it "Normal run" => sub {
            ok( $bbb->getmeetinginfo( meetingID => 'mymeeting', password  => 'mypass' ) );
            like( $url, qr/getMeetingInfo\?meetingID=mymeeting&password=mypass/ );
        }
    };

    describe "getmeetings" => sub {
        it "Normal run" => sub {
            ok( $bbb->getmeetings );
            like( $url, qr/getMeetings/ );
        }
    };

    describe "getrecordings" => sub {
        it "Normal run" => sub {
            ok( $bbb->getrecordings( meetingID => 'mymeeting', password  => 'mypass' ) );
            like( $url, qr/getRecordings\?meetingID=mymeeting&password=mypass/ );
        }
    };
};

runtests unless caller;
