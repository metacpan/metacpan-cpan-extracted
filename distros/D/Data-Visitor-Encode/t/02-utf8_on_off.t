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
    utf8_on_ok( { "日本語" => "あいうえお" }, "utf8_on on hashref" );

    # arrayref
    utf8_on_ok( [ "日本語", "あいうえお" ], "utf8_on on arrayref" );

    # scalarref
    utf8_on_ok( \"日本語", "utf8_on on scalarref" );

    utf8_on_ok( bless({ "日本語" => "あいえうお" }, "Hoge"), "utf8_on on object" );
}

{
    # hashref 
    utf8_off_ok( { "日本語" => "あいうえお" }, "utf8_off on hashref" );

    # arrayref
    utf8_off_ok( [ "日本語", "あいうえお" ], "utf8_off on arrayref" );

    # scalarref
    utf8_off_ok( \"日本語", "utf8_off on scalarref" );

    utf8_off_ok( bless({ "日本語" => "あいえうお" }, "Hoge"), "utf8_off on object" );
}

