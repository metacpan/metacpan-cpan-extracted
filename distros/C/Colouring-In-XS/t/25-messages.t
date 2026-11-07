use strict;
use warnings;
use Test::More;

use Colouring::In::XS qw/get_message set_messages/;

my $valid = 'The string passed to Colouring::In::XS::validate is a valid color';
my $invalid = 'The string passed to Colouring::In::XS::validate is not a valid color.';

is(get_message('VALIDATE'), undef, 'no message store, no message');

my $v = Colouring::In::XS->validate('#abc');
is(${$v->{valid}}, 1, 'a valid colour');
is($v->{message}, $valid, 'with the built in message');
is($v->{colour}->toHEX, '#abc', 'and the colour');

my $i = Colouring::In::XS->validate('nope');
is(${$i->{valid}}, 0, 'an invalid colour');
is($i->{message}, $invalid, 'with the built in message');
is($i->{color}, 'nope', 'and the string');

set_messages();
set_messages('text');
set_messages([]);
is(get_message('VALIDATE'), undef, 'only a hash reference is a message store');

set_messages({ VALIDATE => 'yes' });
is(get_message('VALIDATE'), 'yes', 'a message from the store');
is(get_message('OTHER'), undef, 'a key the store lacks');
is(Colouring::In::XS->validate('#abc')->{message}, 'yes', 'validate reads the store');
is(Colouring::In::XS->validate('nope')->{message}, $invalid, 'and falls back for a key it lacks');

set_messages({});
is(Colouring::In::XS->validate('#abc')->{message}, $valid, 'an empty store falls back');

done_testing;
