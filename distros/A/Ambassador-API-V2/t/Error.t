use Test2::Bundle::Extended -target => 'Ambassador::API::V2::Error';
use Test2::Tools::Spec;

describe Error => sub {
    tests shortcode_example => sub {
        my %response = (
            success => 0,
            status  => 400,
            url     => 'https://example.com/foo/bar',
            reason  => 'Because',
            content => <<'CONTENT',
{
  "response": {
    "code": "400",
    "message": "BAD REQUEST: The parameters provided were invalid. See response body for error messages.",
    "errors": {
      "error": [
        "The following GET/POST parameter is required: short_code."
      ]
    }
  }
}
CONTENT
        );

        my $result = $CLASS->new_from_response(\%response);
        is $result->code,    400;
        is $result->message, "BAD REQUEST: The parameters provided were invalid. See response body for error messages.";
        ok !$result->is_success;
        ok $result->errors->[0], "The following GET/POST parameter is required: short_code.";

        is $result->as_string, <<'STRING', 'as_string';
400: BAD REQUEST: The parameters provided were invalid. See response body for error messages.
The following GET/POST parameter is required: short_code.
STRING

        is "$result", $result->as_string, "stringification";
    };
};

done_testing;
