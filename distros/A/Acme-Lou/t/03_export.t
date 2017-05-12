use strict;
use warnings;
use utf8;
use Test::More;

use Acme::Lou qw/lou/;
    
my $input = <<'...';
祇園精舎の鐘の声、諸行無常の響きあり。
沙羅双樹の花の色、盛者必衰の理を現す。
奢れる人も久しからず、唯春の夜の夢のごとし。
- 「平家物語」
...

my $expected = <<'...';
祇園テンプルのベルのボイス、諸行無常のエコーあり。
沙羅双樹のフラワーのカラー、盛者必衰のリーズンをショーする。
プラウドすれるヒューマンも久しからず、オンリースプリングのイーブニングのドリームのごとし。
- 「平家ストーリー」
...

is(lou($input), $expected);

done_testing();
