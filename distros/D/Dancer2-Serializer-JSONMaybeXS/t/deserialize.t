use strict;
use warnings;
# Tests adapted from Dancer2 core t/deserialize.t

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Dancer2::Logger::Capture;

my $logger = Dancer2::Logger::Capture->new;
isa_ok( $logger, 'Dancer2::Logger::Capture' );

{
    package MyApp;
    use Dancer2;

    set serializer => 'JSONMaybeXS';

    # for now
    set logger     => 'Console';

    put '/from_params' => sub {
        my %p = params();
        return [ map +( $_ => $p{$_} ), sort keys %p ];
    };

    put '/from_data' => sub {
        my $p = request->data;
        return [ map +( $_ => $p->{$_} ), sort keys %{$p} ];
    };

    # This route is used for both toure and body params.
    post '/from/:town' => sub {
        my $p = params;
        return [ map +( $_ => $p->{$_} ), sort keys %{$p} ];
    };

    any [qw/del patch/] => '/from/:town' => sub {
        my $p = params('body');
        return [ map +( $_ => $p->{$_} ), sort keys %{$p} ];
    };
}

my $test = Plack::Test->create( MyApp->to_app );

subtest 'PUT request with parameters' => sub {
    for my $type ( qw<params data> ) {
        my $res = $test->request(
            PUT "/from_$type",
                'Content-Type' => 'application/json',
                Content        => '{ "foo": 1, "bar": 2 }'
        );

        is(
            $res->content,
            '["bar",2,"foo",1]',
            "Parameters deserialized from $type",
        );
    }
};

my $app = MyApp->to_app;
use utf8;
use JSON::MaybeXS;
use Encode;
use Dancer2::Serializer::JSONMaybeXS;

note "Verify Serializers decode into characters"; {
    my $utf8 = '∮ E⋅da = Q,  n → ∞, ∑ f(i) = ∏ g(i)';

    test_psgi $app, sub {
        my $cb = shift;

        my $serializer = Dancer2::Serializer::JSONMaybeXS->new();
        my $body = $serializer->serialize({utf8 => $utf8});

        my $r = $cb->(
            PUT '/from_params',
                'Content-Type' => $serializer->content_type,
                Content        => $body,
        );

        my $content = Encode::decode( 'UTF-8', $r->content );

        like(
            $content,
            qr{\Q$utf8\E},
            "utf-8 string returns the same using the JSONMaybeXS serializer",
        );
    };
}

note "Decoding of mixed route and deserialized body params"; {
    # Check integers from request body remain integers
    # but route params get decoded.
    test_psgi $app, sub {
        my $cb = shift;

        my @req_params = (
            "/from/D\x{c3}\x{bc}sseldorf", # /from/d%C3%BCsseldorf
            'Content-Type' => 'application/json',
            Content        => encode_json({ population => 592393 }),
        );

        my $r = $cb->( POST @req_params );

        # Watch out for hash order randomization..
        is_deeply(
            $r->content,
            '["population",592393,"town","'."D\x{c3}\x{bc}sseldorf".'"]',
            "Integer from JSON body remains integer and route params decoded",
        );
    };
}

# Check body is deserialized on PATCH and DELETE.
# The RFC states the behaviour for DELETE is undefined; We take the lenient
# and deserialize it.
# http://tools.ietf.org/html/draft-ietf-httpbis-p2-semantics-24#section-4.3.5
note "Deserialze any body content that is allowed or undefined"; {
    test_psgi $app, sub {
        my $cb = shift;

        for my $method ( qw/DELETE PATCH/ ) {
            my $request  = HTTP::Request->new(
                $method,
                "/from/D\x{c3}\x{bc}sseldorf", # /from/d%C3%BCsseldorf
                [ 'Content-Type' => 'application/json' ],
                encode_json({ population => 592393 }),
            );
            my $response = $cb->($request);
            my $content  = Encode::decode( 'UTF-8', $response->content );

            # Only body params returned
            is(
                $content,
                '["population",592393]',
                "JSON body deserialized for " . uc($method) . " requests",
            );
        }
    }
}

note 'Check serialization errors'; {
    Dancer2->runner->apps->[0]->set_serializer_engine(
        Dancer2::Serializer::JSONMaybeXS->new( log_cb => sub { $logger->log(@_) } )
    );

    test_psgi $app, sub {
        my $cb = shift;

        $cb->(
            PUT '/from_params',
                'Content-Type' => 'application/json',
                Content        => '---',
        );

        my $trap = $logger->trapper;
        isa_ok( $trap, 'Dancer2::Logger::Capture::Trap' );

        my $errors = $trap->read;
        isa_ok( $errors, 'ARRAY' );
        is( scalar @{$errors}, 1, 'One error caught' );

        my $msg = $errors->[0];
        delete $msg->{'formatted'};
        isa_ok( $msg, 'HASH' );
        is( scalar keys %{$msg}, 2, 'Two items in the error' );

        is( $msg->{'level'}, 'core', 'Correct level' );
        like(
            $msg->{'message'},
            qr{^Failed to deserialize (?:the request|content): malformed number},
            'Correct error message',
        );
    }
}

done_testing;
