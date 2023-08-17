use strict;
use warnings;
use Test::Spec;

use FindBin qw/ $Bin /;
use lib "$Bin/../lib";

use_ok( 'API::BigBlueButton' );

describe "Constructor" => sub {

    it "Normal creation" => sub {
        my $bbb = API::BigBlueButton->new(
            secret => 'mysecret',
            server => 'myserver',
        );
        ok( $bbb );
        is( $bbb->{server}, 'myserver' );
        is( $bbb->{secret}, 'mysecret' );
    };

    it "Empty required params" => sub {
        my $bbb;
        eval { $bbb = API::BigBlueButton->new };
        ok( $@ );

        eval { $bbb = API::BigBlueButton->new( secret => 'mysecret' ) };
        ok( $@ );
        like( $@, qr/Parameter server required/ );

        eval { $bbb = API::BigBlueButton->new( server => 'myserver' ) };
        ok( $@ );
        like( $@, qr/Parameter secret required/ );
    };
};

describe "abstract_request" => sub {

    my $checksum = '1233dfgdfg';
    my $bbb;

    before each => sub {
        $bbb = API::BigBlueButton->new(
            secret => 'mysecret',
            server => 'myserver',
        );
    };

    it "Without data" => sub {
        my $url;
        API::BigBlueButton->expects( 'request' )
            ->returns( sub { $url = $_[1]; return 1 } )->at_least(1);

        my $res = $bbb->abstract_request( {
            request  => 'create',
            checksum => $checksum,
        } );

        ok( $res );
        like( $url, qr/myserver.+create\?checksum=$checksum/ );
    };

    it "With data" => sub {
        my $url;
        my $key = 'myparam';
        my $val = 'myvalue';

        API::BigBlueButton->expects( 'request' )
            ->returns( sub { $url = $_[1]; return 1 } )->at_least(1);

        API::BigBlueButton->expects( 'generate_url_query' )
            ->returns( sub { return $key . '=' . $_[1]->{ $key } } )->at_least(1);

        my $res = $bbb->abstract_request( {
            request  => 'create',
            checksum => $checksum,
            $key     => $val,
        } );

        ok( $res );
        like( $url, qr/myserver.+create\?$key=$val&checksum=$checksum/ );
    };

    it "Empty param request" => sub {
        eval { $bbb->abstract_request( { checksum => $checksum } ) };

        ok ( $@ );
        like( $@, qr/Parameter request required/ );
    };
};

runtests unless caller;
