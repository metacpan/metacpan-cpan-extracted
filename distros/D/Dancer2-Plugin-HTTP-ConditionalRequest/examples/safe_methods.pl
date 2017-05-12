use Dancer2;
use lib '../lib';
use Dancer2::Plugin::HTTP::ConditionalRequest;

get '/get_safe' => sub {
    if (http_method_is_safe) {
        "GET is a safe method"
    };
};

put '/put_safe' => sub {
    if ( ! http_method_is_safe) {
        "PUT is not a safe method";
    };
};

any '/any_safe' => sub {
    my $method = request->method;
    if (http_method_is_safe) {
        "$method is a safe method";
    } else {
        "$method is not a safe method";
    }
};

dance;