use Test2::Bundle::Extended -target => 'Ambassador::API::V2::Result';
use Test2::Tools::Spec;

describe Result => sub {
    tests shortcode_example => sub {
        my %response = (
            success => 1,
            status  => 200,
            url     => 'https://example.com/foo/bar',
            reason  => 'Because',
            content => <<'CONTENT',
{
  "response": {
    "code": "200",
    "message": "OK: The request was successful. See response body for additional data.",
    "data": {
      "shortcode": {
          "valid": 1,
          "sandbox": "0",
          "discount_value": "abc123",
          "first_name": "Jane",
          "last_name": "Doe",
          "email": "johndoe@example.com",
          "uid": "17296",
          "campaign_uid": "17",
          "campaign_name": "Username Reservations",
          "campaign_description": "Get 5 of your friends to reserve their Ambassador username and get an Ambassador t-shirt!",
          "custom1": "data1",
          "custom2": "data2",
          "custom3": "data3"
      }
    }
  }
}
CONTENT
        );

        my $result = $CLASS->new_from_response(\%response);
        is $result->code,    200;
        is $result->message, "OK: The request was successful. See response body for additional data.";
        ok $result->is_success;
        ok $result->data->{shortcode}{valid};
        is $result->data->{shortcode}{email}, 'johndoe@example.com';
    };
};

done_testing;
