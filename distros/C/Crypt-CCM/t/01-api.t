use Test::More tests => 7;
use strict;
use warnings;

use Crypt::CCM;

can_ok('Crypt::CCM', 'new');
can_ok('Crypt::CCM', 'encrypt');
can_ok('Crypt::CCM', 'decrypt');

can_ok('Crypt::CCM', 'set_nonce');
can_ok('Crypt::CCM', 'set_iv');
can_ok('Crypt::CCM', 'set_aad');
can_ok('Crypt::CCM', 'set_tag_length');


