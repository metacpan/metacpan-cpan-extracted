use strict;
# use utf8;
use lib "t/lib";
use Test::More tests => 23;
use Test::Data::Visitor::Encode;
use Encode;

BEGIN
{
    use_ok("Data::Visitor::Encode");
}

{
    use utf8;

    # hashref 
    encode_utf8_ok( { "日本語" => "あいうえお" }, "encode_utf8 on hashref" );

    # arrayref
    encode_utf8_ok( [ "日本語", "あいうえお" ], "encode_utf8 on arrayref" );

    # scalarref
    encode_utf8_ok( \"日本語", "encode_utf8 on scalarref" );

    encode_utf8_ok( bless({ "日本語" => "あいえうお" }, "Hoge"), "encode_utf8 on object" );
}

{
    # hashref 
    decode_utf8_ok( { "日本語" => "あいうえお" }, "decode_utf8 on hashref" );

    # arrayref
    decode_utf8_ok( [ "日本語", "あいうえお" ], "decode_utf8 on arrayref" );

    # scalarref
    decode_utf8_ok( \"日本語", "decode_utf8 on scalarref" );

    decode_utf8_ok( bless({ "日本語" => "あいえうお" }, "Hoge"), "decode_utf8 on object" );
}

