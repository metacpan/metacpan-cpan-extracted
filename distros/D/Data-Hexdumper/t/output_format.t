#!perl -w

use strict;
use warnings;

use Test::More tests => 7;

use Data::Hexdumper qw(hexdump);

eval { hexdump(data => '0123456789ABCDEF', number_format => 'C', output_format => '%C'); };
ok($@, "number_format with output_format is fatal");

is(
  hexdump(data => 'abcdefghijklmno', output_format => '%4a %C %S %L< %Q> %d'),
  Data::Hexdumper::LITTLEENDIAN ?
    "0x0000 61 6362 67666564 68696A6B6C6D6E6F abcdefghijklmno\n" :
    "0x0000 61 6263 67666564 68696A6B6C6D6E6F abcdefghijklmno\n",
  "mixed formats work"
);

is(
  hexdump(data => 'abcdefghijklmno', output_format => '%4a %%C % < > %C %S%> %L%< %Q%% %d'),
  Data::Hexdumper::LITTLEENDIAN ?
    "0x0000 %C % < > 61 6362> 67666564< 6F6E6D6C6B6A6968% abcdefghijklmno\n" :
    "0x0000 %C % < > 61 6263> 64656667< 68696A6B6C6D6E6F% abcdefghijklmno\n",
  "%{%,<,>} work"
);

is(
  hexdump(data => 'abcdefgh', output_format => '%4a %L< %L<'),
  hexdump(data => 'abcdefgh', output_format => '%a %L< %L<'),
  '%4a == %a'
);

is(
  hexdump(data => 'abcdefgh', output_format => '%8a %L< %L<'),
  "0x00000000 64636261 68676665\n",
  '%8a works'
);
is(
  hexdump(data => 'abcdefghabcdefgh', output_format => '%11a %L< %L<'),
  "0x00000000000 64636261 68676665\n0x00000000008 64636261 68676665\n",
  '%11a works'
);

is(
  hexdump(data => 'abcdefgh', suppress_warnings => 1, output_format => '%a %2Q %3C %4S< %1L'),
  hexdump(data => 'abcdefgh', suppress_warnings => 1, output_format => '%a %Q %Q %C %C %C %S< %S< %S< %S< %L'),
  '%2Q %3C %4S< %1L == %Q %Q %C %C %C %S< %S< %S< %S< %L'
);

