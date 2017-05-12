use strict;
use utf8;
use lib "t/lib";
use Test::More tests => 19;
use Test::Data::Visitor::Encode;
use Encode;

BEGIN
{
    use_ok("Data::Visitor::Encode");
}

{
    my $euc_nihongo = encode('euc-jp', "日本語");
    my $euc_aiueo   = encode('euc-jp', "あいうえお");
    # hashref 
    decode_ok( 'euc-jp', { $euc_nihongo => $euc_aiueo }, "encode on hashref" );

    # arrayref
    decode_ok( 'euc-jp', [ $euc_nihongo, $euc_aiueo ], "encode on arrayref" );

    # scalarref
    decode_ok( 'euc-jp', \$euc_nihongo, "encode on scalarref" );

    decode_ok( 'euc-jp', bless({ $euc_nihongo => $euc_aiueo}, "Hoge"), "encode on object" );
}

{
    # hashref 
    encode_ok( 'euc-jp', { "日本語" => "あいうえお" }, "decode on hashref" );

    # arrayref
    encode_ok( 'euc-jp', [ "日本語", "あいうえお" ], "decode on arrayref" );

    # scalarref
    encode_ok( 'euc-jp', \"日本語", "decode on scalarref" );

    encode_ok( 'euc-jp', bless({ "日本語" => "あいえうお" }, "Hoge"), "decode on object" );
}

