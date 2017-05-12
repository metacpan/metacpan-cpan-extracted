# This tests the function "grade" using the file "kanjidic-sample". It
# assumes that there is only one grade 3 character, 悪, in the file.

use warnings;
use strict;
use utf8;
use FindBin;
use Test::More;
use Data::Kanji::Kanjidic qw/parse_kanjidic grade/;
my $kanjidic = parse_kanjidic ("$FindBin::Bin/kanjidic-sample");
my $grade_kanjis = grade ($kanjidic, 3);
ok (@$grade_kanjis == 1);
ok ($grade_kanjis->[0] eq '悪');
done_testing ();


