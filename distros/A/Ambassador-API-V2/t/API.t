use Test2::Bundle::Extended -target => 'Ambassador::API::V2';
use Test2::Tools::Spec;

describe bad_args => sub {
    my $Args;
    case no_args     => sub { $Args = {} };
    case no_key      => sub { $Args = {username => "blah"} };
    case no_username => sub { $Args = {key => "blah"} };

    tests args_error => sub {
        like dies { $CLASS->new($Args) }, qr/Missing required arguments: /;
    };
};

tests get => sub {
SKIP: {
        for my $key (qw(TEST_AMBASSADOR_API_V2_USERNAME TEST_AMBASSADOR_API_V2_KEY)) {
            skip "Set $key for sandbox API tests" unless $ENV{$key};
        }

        my $api = $CLASS->new(
            username => $ENV{TEST_AMBASSADOR_API_V2_USERNAME},
            key      => $ENV{TEST_AMBASSADOR_API_V2_KEY},
        );

        my $response = $api->get(
            '/shortcode/get/',
            {
                short_code => 'FAKE',
                sandbox    => "1"
            }
        );

        ok($response->is_success, "API call worked");
        like(
            $response->data->{shortcode},
            hash {
                field valid          => 0;
                field sandbox        => undef;
                field discount_value => undef;
            },
            "Used fake shortcode, so things should not be valid/defined"
        );
    }
};

done_testing;
