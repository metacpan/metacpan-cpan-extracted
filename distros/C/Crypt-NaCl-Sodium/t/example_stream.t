
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

# generate secret key

my $crypto_stream = Crypt::NaCl::Sodium->stream();

my $msg = "Secret message";

{
    ## XSalsa20
    ########

    my ($key, $nonce, $random_bytes, $secret, $decrypted_msg);

    # generate secret key
    $key = '1' x $crypto_stream->KEYBYTES;

    # generate nonce
    $nonce = '1' x $crypto_stream->NONCEBYTES;

    # generate 256 bytes from $nonce and $key
    $random_bytes = $crypto_stream->bytes( 256, $nonce, $key );
    is($random_bytes->to_hex,
        "3b6096f326ebb02af53fd5f5a0c2f8e35ee8c4d7d2bbfbc04838140b1ed9c3db294813f4816f58a3e37509606d6b0ada29276bfc647bba31742b41e964cdc4a41b9470bf6fd0e493933368e1398442d1ae3f6d7210da10cf54428d15836bf16563eeb3ba430d5999dc10cfb70bbdeb269a8fc0f67811fc376660b2ebe1c56a9de2d2dcf1a7fcb8c3e5fe33fa796e47abd0888d4fed4c45be7d87434957c234aa9b33186a1867b170875ce38e1c922ae8c7c72d24b713617a57e82216b3e25b33da67d826d766ae571bfa40de54f1592ae2f6201544a192f5eeeb9001feb74650cfa7c062f5c59a500cc00ccf80dfe0cfe208ded6b2b08b06d5c37ae83fbd7776",
        "random_bytes");

    # encrypt
    $secret = $crypto_stream->xor($msg, $nonce, $key);
    ok($secret, "msg encrypted");

    # decrypt
    $decrypted_msg = $crypto_stream->xor($secret, $nonce, $key);
    is($decrypted_msg->to_hex, bin2hex($msg), "msg decrypted");
}

{
    ## ChaCha20
    ########

    my ($key, $nonce, $random_bytes, $secret, $decrypted_msg);

    # generate secret key
    $key = '1' x $crypto_stream->CHACHA20_KEYBYTES;

    # generate nonce
    $nonce = '1' x $crypto_stream->CHACHA20_NONCEBYTES;

    # generate 256 bytes from $nonce and $key
    $random_bytes = $crypto_stream->chacha20_bytes( 256, $nonce, $key );
    is($random_bytes->to_hex,
        "52753eeeb9d813b2706acaf970c24839f5fe8b73aa3c8709f2c7fab6fdecbe4707d9bddb90f13f28c96b08e686ff6000b00a6bae9d8167c582957ef9ab5db273f191eadbd1911a6453ff0e42a319befb7bb0d7f34c063cc86a67073a1fd6aba99dc5f5b1ec8ebacf3502c8743dfa1f211790f50f52124e4715e2c7d56ded82c9adba5d79c58e5f0c8fcd4eddf916619355383c01cbff669d8b3c9e49e5af8a0773a4d109020d6734d55640501e3999925407b988998578356918c213138d0c768e79b68c80173455638c4c9c1e2927f0a1323d006cb84ffbb204118d5ae442a503f6d8fe679130d4420b508593ee96f57841718252523460ec92c92e83b32b51",
        "random_bytes");

    # encrypt
    $secret = $crypto_stream->chacha20_xor($msg, $nonce, $key);
    ok($secret, "msg encrypted");

    # decrypt
    $decrypted_msg = $crypto_stream->chacha20_xor($secret, $nonce, $key);
    is($decrypted_msg->to_hex, bin2hex($msg), "msg decrypted");
}

{
    ## Salsa20
    ########

    my ($key, $nonce, $random_bytes, $secret, $decrypted_msg);

    # generate secret key
    $key = '1' x $crypto_stream->SALSA20_KEYBYTES;

    # generate nonce
    $nonce = '1' x $crypto_stream->SALSA20_NONCEBYTES;

    # generate 256 bytes from $nonce and $key
    $random_bytes = $crypto_stream->salsa20_bytes( 256, $nonce, $key );
    is($random_bytes->to_hex,
        "86476988cc5fcd0d319e7826f3969795fbdd5687cb219a00d7c6003f1a24265651b60842734b77ff8d21052b50f6ca1608b15ef0f10c3c2565014504c1f7a9f9c48f847799ad6dc437a7db5e69c094e5fe72b3b37cd73a04062493882d1e2ae0fa2f1ee91338b20ab4ee60f6601f5a6a98ec57575d488c148aa704c739d68a62d9f914aefb572c1e3818f7a47510c49e80b33b3a6aa520c178f6a899033f9a23f121c6d619cc019461d73a403f91abd611b7d0b8133bbd158d168d7de261d651bc0a2f54b9b099647d61bca01d468c6319f1b2d07226edb0e7574ae69b261d4a2fc51b4d1591d0a050fed0605545ff8bd1ae8c56ad42155a066f600306539245",
        "random_bytes");

    # encrypt
    $secret = $crypto_stream->salsa20_xor($msg, $nonce, $key);
    ok($secret, "msg encrypted");

    # decrypt
    $decrypted_msg = $crypto_stream->salsa20_xor($secret, $nonce, $key);
    is($decrypted_msg->to_hex, bin2hex($msg), "msg decrypted");
}

{
    ## AES-128-CTR
    ########

    my ($key, $nonce, $random_bytes, $secret, $decrypted_msg);

    # generate secret key
    $key = '1' x $crypto_stream->AES128CTR_KEYBYTES;

    # generate nonce
    $nonce = '1' x $crypto_stream->AES128CTR_NONCEBYTES;

    # generate 256 bytes from $nonce and $key
    $random_bytes = $crypto_stream->aes128ctr_bytes( 256, $nonce, $key );
    is($random_bytes->to_hex,
        "ad0110483d0559d12e8cb97203e6c9083bb4e887d0c49ba742115543f30cd22521ea9f2b57c22fb50013e28fa0d7df2258b77feb379e5f7ae02534a14665e6cd6669237c67743c3295fe566b0ba1b23eb9ba12bbdf3ef56b871daa7cb0e7d60c14a1dda08fe9034a876454f994823968bfe4a8d05b8286e7deb9bf3146e30c2a2fc1051db5bdf17dc39af8c14fc23988fcb2b7fd9d7b1c22cc1eab365120248bc653947bf8b62501044ed75148dfb77cd1ee405ee2cbbf5beeaf147cfb8e0dd484cd298676d1fd64f67980441cbab86a7f335c84bb49bda96e0a48d62bb1639e7d21a2730f1ef35578aa43398441e61b800b6ff1314f2aaa376520d06bcccf5b",
        "random_bytes");

    # encrypt
    $secret = $crypto_stream->aes128ctr_xor($msg, $nonce, $key);
    ok($secret, "msg encrypted");

    # decrypt
    $decrypted_msg = $crypto_stream->aes128ctr_xor($secret, $nonce, $key);
    is($decrypted_msg->to_hex, bin2hex($msg), "msg decrypted");
}

done_testing();

