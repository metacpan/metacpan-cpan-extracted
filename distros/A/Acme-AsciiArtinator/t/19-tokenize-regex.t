use Acme::AsciiArtinator;
use Test::More tests => 10;

#################################
#
# test how things are tokenized
#
#################################

my $code = '$a=$b+$c;$d=$e**4';
my @tokens = Acme::AsciiArtinator::tokenize_code($code);
ok(@tokens == 16, "routine tokenize test");
ok($tokens[1] eq "a", "routine tokenize test");
ok($tokens[-2] eq "**", "operator dipthong captured");

$code = 's/fox/hound/';
@tokens = Acme::AsciiArtinator::tokenize_code($code);
ok(@tokens==1, "regexs are single expressions");

$code = 's#cat(s?)#dogs#g';
@tokens = Acme::AsciiArtinator::tokenize_code($code);
ok(@tokens == 2, "regex modifier is separate token");

$code = 's/(fox)/$hound.$1.$dog/ge';
@tokens = Acme::AsciiArtinator::tokenize_code($code);
ok(@tokens > 2, "s///e makes 2nd pattern flexible");

$code = 'm{C A T}';
@tokens = Acme::AsciiArtinator::tokenize_code($code);
ok(@tokens == 1, "whitespace in default regex is not flexible");

$code = 'm{C A T}gx';
@tokens = Acme::AsciiArtinator::tokenize_code($code);
ok(@tokens == 6, "whitespace in /regex/x is flexible");

$code = 's/C A T scanning machine/$&x17/gexms;$q+=4;';
@tokens = Acme::AsciiArtinator::tokenize_code($code);
ok(@tokens == 32, "whitespace,2nd expr in s///xe are flexible");

$code = 's{C A T}{$&x17}xe';
@tokens = Acme::AsciiArtinator::tokenize_code($code);
ok(@tokens == 12, "whitespace,2nd expr in s()()xe are flexible");
