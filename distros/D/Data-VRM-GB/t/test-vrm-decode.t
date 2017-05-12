use Test::Most tests => 29;

use DateTime;
use Data::VRM::GB qw/decode_vrm/;

my $trunc = sub { shift->truncate(to => 'day') };

# Current Style Marks

is(decode_vrm('AA51 AAA')->{start_date}->$trunc, DateTime->new(year => 2001, month => 9, day => 1), 'AA51 AAA start_date');
is(decode_vrm('AA51 AAA')->{end_date}->$trunc, DateTime->new(year => 2002, month => 2, day => 28), 'AA51 AAA end_date');


is(decode_vrm('AA02 AAA')->{start_date}->$trunc, DateTime->new(year => 2002, month => 3, day => 1), 'AA02 AAA start_date');
is(decode_vrm('AA02 AAA')->{end_date}->$trunc, DateTime->new(year => 2002, month => 8, day => 31), 'AA02 AAA end_date');


is(decode_vrm('AA14 AAA')->{start_date}->$trunc, DateTime->new(year => 2014, month => 3, day => 1), 'AA14 AAA start_date');
is(decode_vrm('AA14 AAA')->{end_date}->$trunc, DateTime->new(year => 2014, month => 8, day => 31), 'AA14 AAA end_date');


is(decode_vrm('AA65 AAA')->{start_date}->$trunc, DateTime->new(year => 2015, month => 9, day => 1), 'AA65 AAA start_date');
is(decode_vrm('AA65 AAA')->{end_date}->$trunc, DateTime->new(year => 2016, month => 2, day => 29), 'AA65 AAA end_date');

is(decode_vrm('AA67 AAA')->{start_date}->$trunc, DateTime->new(year => 2017, month => 9, day => 1), 'AA67 AAA start_date');
is(decode_vrm('AA67 AAA')->{end_date}->$trunc, DateTime->new(year => 2018, month => 2, day => 28), 'AA67 AAA end_date');

is(decode_vrm('AA99 AAA')->{start_date}->$trunc, DateTime->new(year => 2049, month => 9, day => 1), 'AA99 AAA start_date');
is(decode_vrm('AA99 AAA')->{end_date}->$trunc, DateTime->new(year => 2050, month => 2, day => 28), 'AA99 AAA end_date');

# It doesn't look like a 01 plate will be issued

ok( ! defined decode_vrm('AA01 AAA'), "AA01 AAA won't be issued");

# 50 and 00 are edge cases, and will be used in 2050-2051

is(decode_vrm('AA50 AAA')->{start_date}->$trunc, DateTime->new(year => 2050, month => 3, day => 1), 'AA50 AAA start_date');
is(decode_vrm('AA50 AAA')->{end_date}->$trunc, DateTime->new(year => 2050, month => 8, day => 31), 'AA50 AAA end_date');

is(decode_vrm('AA00 AAA')->{start_date}->$trunc, DateTime->new(year => 2050, month => 9, day => 1), 'AA00 AAA start_date');
is(decode_vrm('AA00 AAA')->{end_date}->$trunc, DateTime->new(year => 2051, month => 2, day => 28), 'AA00 AAA end_date');

# Year-prefix Marks

ok(defined decode_vrm('A1 AAA'), 'A1 AAA should be defined');
is(decode_vrm('A1 AAA')->{start_date}->$trunc, DateTime->new(year => 1983, month => 8, day => 1), 'A1 AAA start_date');
is(decode_vrm('A1 AAA')->{end_date}->$trunc, DateTime->new(year => 1984, month => 7, day => 31), 'A1 AAA end_date');

is(decode_vrm('Y123 AYX')->{start_date}->$trunc, DateTime->new(year => 2001, month => 3, day => 1), 'Y123 AYX start_date');
is(decode_vrm('Y123 AYX')->{end_date}->$trunc, DateTime->new(year => 2001, month => 8, day => 31), 'Y123 AYX end_date');

ok( ! defined decode_vrm('I2 AAA'), 'I2 AAA should be undef because no "I" prefix plates were issued');

# Suffix Marks

ok(defined decode_vrm('AAA 1A'), 'AAA 1A should be defined');

is(decode_vrm('AAA 1A')->{start_date}->$trunc, DateTime->new(year => 1963, month => 2, day => 1), 'AAA 1A start_date');
is(decode_vrm('AAA 1A')->{end_date}->$trunc, DateTime->new(year => 1963, month => 12, day => 31), 'AAA 1A end_date');

is(decode_vrm('AAA 1Y')->{start_date}->$trunc, DateTime->new(year => 1982, month => 8, day => 1), 'AAA 1Y start_date');
is(decode_vrm('AAA 1Y')->{end_date}->$trunc, DateTime->new(year => 1983, month => 7, day => 31), 'AAA 1Y end_date');

# Test handling of unknown formats
ok( ! defined decode_vrm('RUBB ISH'), 'Passing in RUBB ISH should return undef');
