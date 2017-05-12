use Bubblegum::Wrapper::Digest;
use Test::More;

can_ok 'Bubblegum::Wrapper::Digest', 'new';
can_ok 'Bubblegum::Wrapper::Digest', 'data';
can_ok 'Bubblegum::Wrapper::Digest', 'encode';

my $digest = Bubblegum::Wrapper::Digest->new(
    data => join ',', (1..26)
);

is $digest->encode,
    'be65a4d6324659481d2880e13e6dcdc6',
        'default md5_hex returns the correct value';

is $digest->encode('md5_hex'),
    'be65a4d6324659481d2880e13e6dcdc6',
        'default md5_hex returns the correct value';

is $digest->encode('md5_hex'),
    'be65a4d6324659481d2880e13e6dcdc6',
        'md5_hex returns the correct value';

is $digest->encode('sha1'),
    pack("H*", "ebb84530763fcb60a6ca23f6386b95199c78921d"),
        'sha1 returns the correct value';

is $digest->encode('sha1_hex'),
    'ebb84530763fcb60a6ca23f6386b95199c78921d',
        'sha1_hex returns the correct value';

is $digest->encode('sha1_base64'),
    '67hFMHY/y2CmyiP2OGuVGZx4kh0',
        'sha1_base64 returns the correct value';

is $digest->encode('hmac_sha1_hex'),
    '59a9a725385071ff0b522582915b69167b7d07b4',
        'hmac_sha1_hex returns the correct value';

is $digest->encode('hmac_sha1'),
    pack("H*", '59a9a725385071ff0b522582915b69167b7d07b4'),
        'hmac_sha1 returns the correct value';

done_testing;
