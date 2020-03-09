use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use AWS::XRay ();
use Test::More;
use IO::Scalar;
use Encode qw/decode_utf8/;

subtest "valid", sub {
    my @names = (
        "foo",
        "foo bar 3",
        "foo/_bar:",
        "foo%bar",
        "foo&bar#=baz",
        "foo\@bar+\\baz",
        " foo - bar ",
        "x" x 200,
        decode_utf8("あああ"),
    );
    for my $name (@names) {
        ok AWS::XRay::is_valid_name($name), "valid name: $name";
    }
};

subtest "invalid", sub {
    my @names = (
        "あああ",
        "^",
        "(xxx)",
        "'**'",
        "[]",
        "{}",
        "\$xxx",
        "foo;bar",
        " foo ? ",
        "x" x 201,
    );
    for my $name (@names) {
        ok !AWS::XRay::is_valid_name($name), "invalid name: $name";
    }
};

done_testing;
