use strict;
use warnings;

use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8
use Test::More 0.88;
use utf8;
use Acme::Pi;

my $original_length = length(atan2(1,1) * 4);

my $length = length(π);
ok($length > 20, 'π has many digits of precision ('.$length.')');
ok($length > $original_length, '...which is more digits than the previous version of π ('.$original_length.')');

my $pi = π;
ok((3.14 < $pi) && ($pi < 3.15), 'local copy of π is between 3.14 and 3.15');

ok((0.78 < π/4) && (π/4 < 0.79), 'pi constant divided by 4 is correct value');

my $quarter_pi = $pi/4;
ok((0.78 < $quarter_pi) && ($quarter_pi < 0.79), 'local copy of π, divided by 4, is correct value');
ok((3.14 < $pi) && ($pi < 3.15), 'local copy of π is still between 3.14 and 3.15');
ok((3.14 < π) && (π < 3.15), 'constant π is still between 3.14 and 3.15');

ok((0.78 < π->bdiv(4)) && (π->bdiv(4) < 0.79), 'pi constant bdiv(4) is correct value');
ok((3.14 < π) && (π < 3.15), 'constant π is still between 3.14 and 3.15');

# note that Math::BigFloat's bdiv method mutates the invocant, and this is not yet documented:
# see https://rt.cpan.org/Ticket/Display.html?id=154105
ok((0.78 < $pi->bdiv(4)) && ($pi->bdiv(4) < 0.79), 'local pi bdiv(4) is correct value');
TODO: {
  local $TODO = 'Math::BigFloat::bdiv mutates its invocant - beware!';
  ok((3.14 < $pi) && ($pi < 3.15), 'local copy of π is still between 3.14 and 3.15');
};

done_testing;
