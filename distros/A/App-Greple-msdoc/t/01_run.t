use v5.14;
use warnings;
use Encode;
use utf8;

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

is(greple(qw(-Mmsdoc --dump /dev/null))->run->{result}, 0, "--dump exit 0");

is(greple(qw(-Mmsdoc --nocolor -o クリエイティブ t/data_shishin.docx))->run->{stdout},
   "クリエイティブ\n" x 2,
   "-o");

like(greple(qw(-Mmsdoc --dump t/data_shishin.docx))->run->{stdout},
   qr/\A(.*\n){183}\z/,
   "--dump docx");

done_testing;
