use strict;
use Test::More;

use_ok "DateTime::Astro", "polynomial";

like polynomial(1, 3, 2, 1), qr/^6(\.0+)?$/;
like polynomial(2, 3, 2, 1), qr/^11(\.0+)?$/;
like polynomial(3, 3, 2, 1), qr/^18(\.0+)?$/;
like polynomial(4, 3, 2, 1), qr/^27(\.0+)?$/;

done_testing;
