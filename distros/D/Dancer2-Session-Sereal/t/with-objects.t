use strict;
use warnings;
use Test::More;
use JSON;
use Plack::Test;
use HTTP::Cookies;
use HTTP::Request::Common;

use File::Temp 0.22;
use HTTP::Date qw/str2time/;

{ 
    package Thing;
    use Moo;
    has name => ( is => 'rw' );
}

{
    package App;
    use Dancer2;

    get '/set_session/*' => sub {
        session thing => Thing->new( name => splat );
        return '';
    };

    get '/read_session' => sub {
        return  session( 'thing' )->name;
    };

    setting( engines => { session => { Sereal => { encoder_args => {}, decoder_args => {} } }} );

    setting( session => 'Sereal' );

    set(
        show_errors  => 1,
        startup_info => 0,
        environment  => 'production',
    );
}

my $url  = "http://localhost";
my $test = Plack::Test->create( App->to_app );
my $jar = HTTP::Cookies->new;


my $sid1;
subtest "Set value into session" => sub {
    my $res = $test->request( GET "$url/set_session/larry" );
    ok $res->is_success, "/set_session/larry";

    $jar->extract_cookies($res);
    ok( $jar->as_string, 'Cookie set' );

    # extract SID
    $jar->scan( sub { $sid1 = $_[2] } );
    ok( $sid1, 'Got SID from cookie' );
};

subtest "Read value back" => sub {

    # read value back
    my $req = GET "$url/read_session";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok $res->is_success, "/read_session";

    $jar->clear;
    ok( !$jar->as_string, 'Jar cleared' );

    $jar->extract_cookies($res);
    ok( $jar->as_string, 'session cookie set again' );
    like $res->content, qr/larry/, "session value looks good";
};

done_testing;
