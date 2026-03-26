use Test::More;

use Acme::AsciiEmoji qw/east_smile west_smile bat dollarbill wizard terrorist sword swag/;

is(east_smile, '))', 'a east smile test');
is(west_smile, ':)', 'a west smile test');
is(bat, '/|\ ^._.^ /|\\', 'bat');

like(dollarbill, qr/[̲̅$̲̅(̲̅ιο̲̅)̲̅$̲̅]/, 'dollarbill');

is(wizard, '╰( ͡° ͜ʖ ͡° )つ──☆*:・ﾟ', 'wizard');

is(terrorist, '୧༼ಠ益ಠ༽︻╦╤─', 'terrorist');

my @data = unpack('C*', '(̿▀̿‿ ̿▀̿ ̿)');

is(sword, 'o()xxxx[{::::::::::::::::::>', 'sword');

is(swag, '(̿▀̿‿ ̿▀̿ ̿)', 'swag');

done_testing();
