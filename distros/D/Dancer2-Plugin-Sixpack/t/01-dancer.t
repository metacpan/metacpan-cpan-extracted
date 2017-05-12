use HTTP::Request::Common;
use Plack::Test;
use Test::More tests => 6;

{
    package GreatApp;
    use Dancer2;
    use Dancer2::Plugin::Sixpack;
    use Test::LWP::UserAgent;

    my $ua = Test::LWP::UserAgent->new();

    $ua->map_response(
        qr{localhost:5000/participate}, HTTP::Response->new('200', 'OK',
            ['Content-Type' => 'application/json'],
            '{"status": "ok", "alternative": {"name": "black"}, "experiment": {"name": "test"},
               "client_id": "16D1F1FA-458D-11E3-A0C3-B218A53797BD"}'
        )
    );
    $ua->map_response(
        qr{localhost:5000/convert}, HTTP::Response->new('200', 'OK',
            ['Content-Type' => 'application/json'],
            '{"status": "ok", "alternative": {"name": "black"}, "experiment": {"name": "test"}, "conversion":
             {"kpi": null, "value": null}, "client_id": "16D1F1FA-458D-11E3-A0C3-B218A53797BD"}'

        )
    );

    set session => 'Simple';
    set plugins => {
        Sixpack => {
            ua => $ua,
            experiments => {
                successful => [ qw( true false ) ]
            },
        }
    };

    post '/force_session' => sub {
        # this feels like cheating, but since we have mocked, static
        # output, we kinda rely on this id.
        session 'sixpack_id' => '16D1F1FA-458D-11E3-A0C3-B218A53797BD';
    };

    get '/with_alt_name' => sub {
        my $alt =  experiment 'test', [ qw( black blue ) ];
        return $alt;
    };

    get '/without_alt_name' => sub {
        my $alt =  experiment 'successful';
        return $alt;
    };

    get '/session_id' => sub {
        session('sixpack_id');
    };

    post '/convert_with_exp' => sub {
        my $res = convert 'test';
        return join " ", keys %{$res};
    };

    post '/convert_no_exp' => sub {
        my $res = convert;
        return join " ", sort keys %{$res};
    };
}

my $test = Plack::Test->create( GreatApp->to_app );

my $res = $test->request(GET '/with_alt_name');
is( $res->content, 'black' );

my $cookie = $res->{_headers}{'set-cookie'};
$cookie =~ s/;.*$//;

$res = $test->request(GET '/session_id', Cookie => $cookie);
like( $res->content, qr/[A-Z0-9\-]{36}/ );

$res = $test->request(POST '/force_session', Cookie => $cookie);
$res = $test->request(GET '/without_alt_name', Cookie => $cookie);
is( $res->content, 'black' ); # yes, black, 'cause we mock the participate call :-|

$res = $test->request(GET '/session_id', Cookie => $cookie);
is( $res->content, '16D1F1FA-458D-11E3-A0C3-B218A53797BD');

$res = $test->request(POST '/convert_with_exp', Cookie => $cookie);
is( $res->content, 'test' );

$res = $test->request(POST '/convert_no_exp', Cookie => $cookie);
is( $res->content, 'successful test' );
