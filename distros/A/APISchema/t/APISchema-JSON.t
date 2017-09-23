package t::APISchema::JSON;
use t::test;

sub _require : Test(startup => 1) {
    my ($self) = @_;

    BEGIN{ use_ok 'APISchema::JSON'; }
}

sub _encode_json_canonical : Tests {
    is APISchema::JSON::encode_json_canonical({b => 2, c => 3, a => 1}), '{"a":1,"b":2,"c":3}', 'keys are sorted';
    is APISchema::JSON::encode_json_canonical({nested => {b => 2, c => 3, a => 1}}), '{"nested":{"a":1,"b":2,"c":3}}', 'nested keys are sorted';
}
