use lib 'inc';

use TestML;

TestML->new(
    testml => join('', <DATA>),
)->run;

{
    package TestML::Bridge;
    use TestML::Util;
    use DJSON;

    sub djson_decode {
        my ($self, $string) = @_;
        native decode_djson($string->value);
    }
}

__DATA__
%TestML 0.1.0

# Make sure these strings do not parse as DJSON.
*djson.djson_decode.Catch.OK;

=== Comma in bareword
--- djson: { url: http://foo.com,2012 }

=== Unmatched [
--- djson: foo[bar
