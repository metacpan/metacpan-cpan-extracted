use strict;
use warnings;

use Test::More 0.98 tests => 7;
use Test::More::UTF8;

use lib 'lib';

use_ok 'Acme::Text::Viceversa';                                     # 1
my $v = new_ok('Acme::Text::Viceversa');                            # 2

note "start to upset the echoes...";
sleep 1;
note "now => ʍou";

my $t = $v->ɐsɹǝʌǝɔᴉʌ('word');
is $t, 'pɹoʍ', 'pɹoʍ ɐ ʇǝsdn oʇ pǝǝɔɔns';                           # 3

$t = $v->ɐsɹǝʌǝɔᴉʌ('succeed to upset a paragragh');
is $t, 'ɥɓɐɹɓɐɹɐd ɐ ʇǝsdn oʇ pǝǝɔɔns', $t;                          # 4

my $pangram = 'Cwm fjord veg balks nth pyx quiz.';
my $upset = '˙zᴉnb xʎd ɥʇu sʞꞁɐq ɓǝʌ pɹoſ̣ɟ ɯʍↃ';
$t = $v->ɐsɹǝʌǝɔᴉʌ($pangram);
is $t, $upset, 'ɯɐɹɓuɐd ɐ ʇǝsdn oʇ pǝǝɔɔns';                        # 5

$t = $v->ɐsɹǝʌǝɔᴉʌ($upset);
is $t, $pangram, 'ɯɐɹɓuɐd ɐ ʇǝsdn-ǝɹ oʇ pǝǝɔɔns';                   # 6

$t = <<'END';

0123456789
ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
~`!@#$%^&*()-_=+[{]}\|;:'",<.>/?
END
# ɓuᴉʇɥɓᴉꞁɥɓᴉɥ xɐʇuʎs pᴉoʌɐ oʇ`

$t = $v->ɐsɹǝʌǝɔᴉʌ($t);
is $t, <<'END', 'sɓuᴉɹʇs pǝuᴉꞁ-ᴉʇꞁnɯ ʇǝsdn oʇ pǝǝɔɔns';               # 7
¿/<˙>‘„͵:⋅̕|\{[}]+=‾-()*⅋‿%$#@¡ ̖∼
zʎxʍʌnʇsɹbdouɯꞁʞſ̣ᴉɥɓɟǝpɔqɐ
Z⅄XMΛᑎ⊥SȢΌԀONWᒣ丬ᒋIH⅁ℲƎpↃᗺ∀
68L9ᔕ⇁⃓εᘔ⇂0
END

done_testing;
