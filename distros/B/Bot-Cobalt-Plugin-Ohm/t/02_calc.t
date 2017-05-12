use Test::More;
use strict; use warnings;

use Bot::Cobalt::Plugin::Ohm;
my $calc = Bot::Cobalt::Plugin::Ohm->new;

# _parse_values
my %parsed = $calc->_parse_values('1o 2w 3a 4v');
is_deeply \%parsed, +{ o => 1, w => 2, a => 3, v => 4 },
  'parsing all values seems ok';
%parsed = $calc->_parse_values('1o 2w');
is_deeply \%parsed, +{ o => 1, w => 2 },
  'parsing a few values seems ok';
%parsed = $calc->_parse_values('5V 0.5O');
is_deeply \%parsed, +{ v => 5, o => 0.5 },
  'uppercase ok';

%parsed = $calc->_parse_values('some nonsense');
ok ! keys %parsed, 'bad string returned no values';

# _calc
%parsed = $calc->_parse_values('5.5v 0.5o');
my $str = $calc->_calc(%parsed);
cmp_ok $str, 'eq', '60.50w/5.50v @ 11.00amps against 0.50ohm',
  'voltage + resistance calc ok';

%parsed = $calc->_parse_values('5.5v .5o');
$str = $calc->_calc(%parsed);
cmp_ok $str, 'eq', '60.50w/5.50v @ 11.00amps against 0.50ohm',
  'voltage + resistance calc (no leading zero) ok';

eval {; $calc->_calc() };
like $@, qr/Not enough information/, '_calc exception looks ok';

done_testing
