use Test::Most 0.22;
use Crypt::TripleDES::CBC;

subtest "decryption using tripledes in cbc mode with nulls in iv" => sub {
    my $algorithm   = "tripledes";
    my $mode        = "cbc";
    my $iv          = pack( "H*", "0000000000000000" );
    my $key         = pack( "H*", "1234567890123456" . "7890123456789012" );
    my $cipher_text = pack( "H*",
            "E9FF3161EE05ABC9"
          . "7ea3cacb991318aa"
          . "585379599b0eaabb"
          . "c4e474ead1956f47"
          . "6755f13f1af5235d" );
    my $obj = Crypt::TripleDES::CBC->new( key => $key, );
    my $plain_text = $obj->decrypt($cipher_text);
    my $expected_plain_hex =
        "5231303000390006"
      . "3030303034370000"
      . "4700074d45465450"
      . "4f53004800093132"
      . "3334353637383900";
    is uc unpack( "H*", $plain_text ), uc $expected_plain_hex,
      "decrypted plaintext matched with expected plaintext";
};

subtest "decryption using tripledes in cbc mode with nulls in iv 2" => sub {
    my $algorithm   = "tripledes";
    my $mode        = "cbc";
    my $iv          = pack( "H*", "0000000000000000" );
    my $key         = pack( "H*", "1234567890123456" . "7890123456789012" );
    my $cipher_text = pack( "H*",
"07e2fe77b41d9a5df983d4ff6199d6e8b7ed076b0322bb81cac378370974c1d4f827e16f952829bb2d8488b7bb67e37af9b87c40184ee619de0aa921671d01ca15246afed93445cde350f595237e8100bf6f8591130ea7a2c6f88427e41e0bfb4ebac7ac3a5edfd6796f20eef963411a503318ef10c24ab15c1e8514cb8e275fe194494421bc504e6d920ab4ab1bf4c8bf50eb228c051aee7332e801f67d8143e31222bbc81cc09c9c78755e2454f771f38d956ce302d3991ecf78aa8fc2df820fea283fd60a5cb3cc97a1199e6d0cd6ac9f2fa01f985285ed202f7b51c25bee216da50964dee8334edda9e7d9a3500d021c219c8c0089aa53faba86522fe731c2bba1f8a8c3d870"
    );
    my $obj = Crypt::TripleDES::CBC->new( key => $key, );
    my $plain_text = $obj->decrypt($cipher_text);
    my $expected_plain_hex =
"5232303000020010585858585858585858585858383434360004000C3030303030303030313432300007000A31303233313431353236000E00045858585800160001430025000C33323936303630303030373400260006303035343931002700023030002900083337313131313837002A000C31363831363833333132383300340004444253480035003E303030303030383030304538303041303030303030303033313031302020444253205649534120202020202020203045363643453243323233373941423800360004564953410037000156003800014400390006303030303737003E0006303030303734004000063030303030320060000A3131303030303030303400";
    is uc unpack( "H*", $plain_text ), uc $expected_plain_hex,
      "decrypted plaintext matched with expected plaintext(test 2)";
};

subtest "encryption using tripledes in cbc mode with nulls in iv" => sub {
    my $algorithm  = "tripledes";
    my $mode       = "cbc";
    my $iv         = pack( "H*", "0000000000000000" );
    my $key        = pack( "H*", "1234567890123456" . "7890123456789012" );
    my $plain_text = pack( "H*",
            "5231303000390006"
          . "3030303034370000"
          . "4700074d45465450"
          . "4f53004800093132"
          . "3334353637383900" );
    my $obj = Crypt::TripleDES::CBC->new( key => $key, );
    my $cipher_text = $obj->encrypt($plain_text);
    my $expected_cipher_hex =
        "E9FF3161EE05ABC9"
      . "7ea3cacb991318aa"
      . "585379599b0eaabb"
      . "c4e474ead1956f47"
      . "6755f13f1af5235d";
    is uc unpack( "H*", $cipher_text ), uc $expected_cipher_hex,
      "encrypted ciphertext matched with expected ciphertext";
};

subtest "encryption using tripledes in cbc mode with nulls in iv 2" => sub {
    my $algorithm  = "tripledes";
    my $mode       = "cbc";
    my $iv         = pack( "H*", "0000000000000000" );
    my $key        = pack( "H*", "1234567890123456" . "7890123456789012" );
    my $plain_text = pack( "H*",
"5232303000020010585858585858585858585858383434360004000C3030303030303030313432300007000A31303233313431353236000E00045858585800160001430025000C33323936303630303030373400260006303035343931002700023030002900083337313131313837002A000C31363831363833333132383300340004444253480035003E303030303030383030304538303041303030303030303033313031302020444253205649534120202020202020203045363643453243323233373941423800360004564953410037000156003800014400390006303030303737003E0006303030303734004000063030303030320060000A3131303030303030303400"
    );
    my $obj = Crypt::TripleDES::CBC->new( key => $key, );
    my $cipher_text = $obj->encrypt($plain_text);
    my $expected_cipher_hex =
"07e2fe77b41d9a5df983d4ff6199d6e8b7ed076b0322bb81cac378370974c1d4f827e16f952829bb2d8488b7bb67e37af9b87c40184ee619de0aa921671d01ca15246afed93445cde350f595237e8100bf6f8591130ea7a2c6f88427e41e0bfb4ebac7ac3a5edfd6796f20eef963411a503318ef10c24ab15c1e8514cb8e275fe194494421bc504e6d920ab4ab1bf4c8bf50eb228c051aee7332e801f67d8143e31222bbc81cc09c9c78755e2454f771f38d956ce302d3991ecf78aa8fc2df820fea283fd60a5cb3cc97a1199e6d0cd6ac9f2fa01f985285ed202f7b51c25bee216da50964dee8334edda9e7d9a3500d021c219c8c0089aa53faba86522fe731c2bba1f8a8c3d870";
    is uc unpack( "H*", $cipher_text ), uc $expected_cipher_hex,
      "encrypted ciphertext matched with expected ciphertext(test 2)";
};
done_testing;
