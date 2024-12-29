use v5.20;
use strict;
use utf8;
use Test::More;
use Test::Exception;

use_ok("Crypt::URandom::Token" => qw(urandom_token));

isnt urandom_token(), urandom_token(), "two tokens are not the same";

like urandom_token(),                    qr/^[A-Za-z0-9]{44}$/,   "44 alphanumeric chars (default)";
like urandom_token(16),                  qr/^[A-Za-z0-9]{16}$/,   "16 alphanumeric chars";
like urandom_token(4096),                qr/^[A-Za-z0-9]{4096}$/, "4096 alphanumeric chars";

like urandom_token(128, [qw/⚀ ⚁ ⚂ ⚃ ⚄ ⚅/]), qr/^[⚀⚁⚂⚃⚄⚅]{128}$/,       "128 chars, alphabet as arrayref";
like urandom_token(128, "⚀⚁⚂⚃⚄⚅"),          qr/^[⚀⚁⚂⚃⚄⚅]{128}$/,       "128 chars, alphabet as string";

throws_ok sub { urandom_token(16, "a" x 1) },    qr/alphabet size must be between 2 and 256/, 'throws when alphabet is too small';
throws_ok sub { urandom_token(16, "a" x 257 ) }, qr/alphabet size must be between 2 and 256/, 'throws when alphabet is too large';

lives_ok( sub { urandom_token(16, "a" x 2 ) },   'lives when alphabet is 2');
lives_ok( sub { urandom_token(16, "a" x 256 ) }, 'lives when alphabet is 256');

done_testing();
