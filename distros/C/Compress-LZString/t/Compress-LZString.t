use 5.006;
use strict;
use warnings;

use Test;
use Compress::LZString qw/:all/;

BEGIN { plan tests => 6 };

# ascii
my $ascii = `$^X -V`;
$ascii =~ s/[^\x00-\x7f]//gs;

skip($]<5.010, $ascii, decompress(compress($ascii)));
ok  (          $ascii, decompress_b64(compress_b64($ascii)));
ok  (          $ascii, decompress_b64_safe(compress_b64_safe($ascii)));

# unicode
local $/ = undef;
my $unicode = <DATA>;

skip($]<5.010, $unicode, decompress(compress($unicode)));
skip($]<5.008, $unicode, decompress_b64(compress_b64($unicode)));
skip($]<5.008, $unicode, decompress_b64_safe(compress_b64_safe($unicode)));

__DATA__
Měsíčku na nebi hlubokém,
světlo tvé daleko vidí,
po světě bloudíš širokém,
díváš se v příbytky lidí.
Měsíčku, postůj chvíli,
řekni mi, kde je můj milý?
Řekni mu, stříbrný měsíčku,
mé že jej objímá rámě,
aby si alespoň chviličku,
vzpomenul ve snění na mě.
Zasvěť mu do daleka,
řekni mu, kdo tu naň čeká!
O mně-li duše lidská sní,
ať se tou vzpomínkou vzbudí!
Měsíčku, nezasni!
Ta voda studí!
Ježibabo, Ježibabo!
