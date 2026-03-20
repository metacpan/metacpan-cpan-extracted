use Test::More;

use Acme::AsciiEmoji qw/east_smile west_smile bat dollarbill wizard/;

is(east_smile, '))', 'a east smile test');
is(west_smile, ':)', 'a west smile test');
is(bat, '/|\ ^._.^ /|\\', 'bat');

like(dollarbill, qr/[̲̅$̲̅(̲̅ιο̲̅)̲̅$̲̅]/, 'dollarbill');

is(wizard, '╰( ͡° ͜ʖ ͡° )つ──☆*:・ﾟ', 'wizard');

done_testing();
