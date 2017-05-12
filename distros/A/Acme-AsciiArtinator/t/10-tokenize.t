use Acme::AsciiArtinator;
use Test::More tests => 14;

# test some tokenizations

my @tokens = Acme::AsciiArtinator::tokenize_code('$A$B$CDE');
ok(@tokens == 6);
ok($tokens[5] eq "CDE");

@tokens = Acme::AsciiArtinator::tokenize_code('"$A$B$CDE"');
ok(@tokens == 1, "quoted string is one token");

@tokens = Acme::AsciiArtinator::tokenize_code('qq{$A$B;$CDE}');
ok(@tokens == 1, "qq{string} is one token");

@tokens = Acme::AsciiArtinator::tokenize_code('$".Hello.world."$/$/"');
ok(@tokens == 8, "\$\" does not start a quoted string");

@tokens = Acme::AsciiArtinator::tokenize_code('$z=$r//$s//($t||=$u)');
ok(@tokens == 16, "dipthongs are tokenized correctly");
ok($tokens[5] eq "//", "perl5.10 dipthongs are tokenized");
ok($tokens[12] eq "||=", "3 character dipthongs are tokenized");

ok(1);ok(1);ok(1);ok(1);ok(1);ok(1);

