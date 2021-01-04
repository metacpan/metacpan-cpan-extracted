
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Crypt/OpenToken.pm',
    'lib/Crypt/OpenToken/Cipher.pm',
    'lib/Crypt/OpenToken/Cipher/AES128.pm',
    'lib/Crypt/OpenToken/Cipher/AES256.pm',
    'lib/Crypt/OpenToken/Cipher/DES3.pm',
    'lib/Crypt/OpenToken/Cipher/null.pm',
    'lib/Crypt/OpenToken/KeyGenerator.pm',
    'lib/Crypt/OpenToken/Serializer.pm',
    'lib/Crypt/OpenToken/Token.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/crypto-3des168.t',
    't/crypto-aes128.t',
    't/crypto-aes256.t',
    't/crypto-null.t',
    't/crypto.t',
    't/keygenerator.t',
    't/opentoken.t',
    't/serializer.t',
    't/token.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
