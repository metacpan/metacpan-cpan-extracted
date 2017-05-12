#!perl -w

use strict;

# test empty data, non-2-d array data, empty descriptor
use Test::More;

use Array::To::Moose qw(:ALL);

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 3;

my $data = [1, 2, 3, 4];

my $desc = { Class => 'Person', age => 2 };

throws_ok { array_to_moose ( data => [],
                             desc => $desc,
                           )
          } qr/'data => ...' isn't a 2D array \(AoA\)/,
          "data isn't a 2-D array";

throws_ok { array_to_moose ( data => $data,
                             desc => $desc,
                           )
          } qr/'data => ...' isn't a 2D array \(AoA\)/,
          "data isn't a 2-D array";

throws_ok { array_to_moose ( data => [ $data ],
                             desc => {}
                           )
          } qr/empty descriptor/,
          "empty descriptor 'desc => ...'";
