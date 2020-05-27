use utf8;

use Test::Most;
use Test::Warnings;

use Encode qw/ encode /;

use_ok('Data::AnyXfer::JSON');

lives_ok {
    my $json = "{\"price\":\"GBP 185pcm\"}";
    my $hash = decode_json($json);
    my $enc  = encode_json($hash);
    is( $enc, encode( 'utf-8', $json ), "encode_json == original" );
}
"decode_json doesn't die (plain text)";

lives_ok {
    my $json = "{\"price\":\"\x{3c78}185pcm\"}";
    my $hash = decode_json($json);
    my $enc  = encode_json($hash);
    is( $enc, encode( 'utf-8', $json ), "encode_json == original" );
}
"decode_json doesn't die on pound signs";

lives_ok {
    my $json = "{\"price\":\"£185pcm\"}";
    my $hash = decode_json($json);
    my $enc  = encode_json($hash);
    is( $enc, encode( 'utf-8', $json ), "encode_json == original" );
}
"decode_json doesn't die on pound signs";

done_testing;
