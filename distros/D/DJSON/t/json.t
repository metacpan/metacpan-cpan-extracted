use lib 'inc';

use TestML;

TestML->new(
    testml => join('', <DATA>),
)->run;

{
    package TestML::Bridge;
    use TestML::Util;
    use DJSON;
    use JSON;
    use YAML;

    sub djson_decode {
        my ($self, $string) = @_;
        native decode_djson($string->value);
    }

    sub json_decode {
        my ($self, $string) = @_;
        native decode_json($string->value);
    }

    sub yaml {
        my ($self, $string) = @_;
        my $yaml = YAML::Dump $string->value;
        $yaml =~
            s{!!perl/scalar:JSON::(?:XS|PP)::Boolean}
            {!!perl/scalar:boolean}g;
        return str $yaml;
    }
}

__DATA__
%TestML 0.1.0

# Test various json streams, to make sure DJSON can parse it properly.
*json.djson_decode.yaml == *json.json_decode.yaml;

=== Various Numbers
--- json: [1,-2,3,4.5,67,0.8e-9]

=== Object with no space
--- json: {"a":"b","c":{"d":"e"},"f":["g","h"],"i":[{},[],[[]]]}
