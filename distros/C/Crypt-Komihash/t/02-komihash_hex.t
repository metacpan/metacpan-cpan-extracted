use strict;
use warnings;
use Test::More;
use Crypt::Komihash qw(komihash_hex komihash);
use Config;

my $is_64bit = ($Config{use64bitint} || $Config{use64bitall});

cmp_ok(komihash_hex('Hello World'          , 0)                  , 'eq', '89580d61bffb6273');
cmp_ok(komihash_hex('Hello World'          , 1)                  , 'eq', '82faf80068a573dd');
cmp_ok(komihash_hex('Hello World'          , 999)                , 'eq', '07a927b31ca90626');
cmp_ok(komihash_hex('JasonDoolis!'         , 192)                , 'eq', '7a26761c35cc6026');
cmp_ok(komihash_hex('  Spaces  '           , 1024)               , 'eq', '85dfe37d7fe788a4');
cmp_ok(komihash_hex("Hello World"          , 2066618754185049600), 'eq', 'ce7a901dc6d7c759');
cmp_ok(komihash_hex("JasonDoolis!"         , 7558871097036047360), 'eq', '8df1af1a32e66354');
cmp_ok(komihash_hex("  Spaces  "           , 998437132072014464) , 'eq', '1e3b79252d0221c1');
cmp_ok(komihash_hex("Foobar"               , 7637702908950946816), 'eq', '9f82dad444581d22');
cmp_ok(komihash_hex("!@#!\$!%\$\@^@%^&&"   , 4921886380803234816), 'eq', '62e887f0b9a09f10');
cmp_ok(komihash_hex("Donk_Donk"            , 5883318983021264896), 'eq', 'b309ff918ffc9361');
cmp_ok(komihash_hex("monkey1234"           , 3185171366221971456), 'eq', '081b3bb63a7aa714');
cmp_ok(komihash_hex("Charlie\nChaplin"     , 4558538572663512576), 'eq', '1e91f249bcd28a99');
cmp_ok(komihash_hex("Captain\rPicard"      , 6181434651745303552), 'eq', '519efbff80a59ca5');
cmp_ok(komihash_hex("tab\ttab"             , 9181434651745303552), 'eq', 'cade224d5eec4bd7');
cmp_ok(komihash_hex("\0"                   , 0)                  , 'eq', 'd5b6bb48fef4dfe0');
cmp_ok(komihash_hex("\0\0\0\0"             , 0)                  , 'eq', '02d69f7dc750abf1');
cmp_ok(komihash_hex("ONE"                  , 3748582144126699520), 'eq', '4fffa07bf038c82d');
cmp_ok(komihash_hex("Ten"                  , 3374046667730193408), 'eq', 'f91c59acbbb2216a');
cmp_ok(komihash_hex("Dinosaur"             , 9118555814520896512), 'eq', 'a8f3b397e7f8659a');
cmp_ok(komihash_hex("undef"                , 6150537732892800000), 'eq', '49ca286a6c1ab59a');
cmp_ok(komihash_hex("0"                    , 1416132966774356736), 'eq', '13bc914f8a9b646e');
cmp_ok(komihash_hex("-1"                   , 5932847008303507456), 'eq', 'f051b669241ebc9d');
cmp_ok(komihash_hex("true"                 , 1636170714898346240), 'eq', 'ed02aa77bd3a33fc');
cmp_ok(komihash_hex("false"                , 4679600326265966592), 'eq', '91a1fe00f115d270');
cmp_ok(komihash_hex("9999"                 , 215344578052703904) , 'eq', '3f4f81d845cf90e7');
cmp_ok(komihash_hex("%%%%%%%%%%%%%%%%%%%%%", 3338573099725674496), 'eq', 'afa15284157cf01a');
cmp_ok(komihash_hex("!!!!!!!!!!!"          , 377478480569193088) , 'eq', '5843ef32b3dda032');

# Test vectors from the docs: https://github.com/avaneev/komihash/blob/main/README.md
cmp_ok(komihash_hex("A 16-byte string", 0)                , 'eq', '467caa28ea3da7a6');
cmp_ok(komihash_hex("The new string"  , 0)                , 'eq', 'f18e67bc90c43233');
cmp_ok(komihash_hex(      "7 chars"   , 0)                , 'eq', '2c514f6e5dcb11cb');
cmp_ok(komihash_hex("A 16-byte string", 256)              , 'eq', '11c31ccabaa524f1');
cmp_ok(komihash_hex("The new string"  , 256)              , 'eq', '3a43b7f58281c229');
cmp_ok(komihash_hex(      "7 chars"   , 256)              , 'eq', 'cff90b0466b7e3a2');
cmp_ok(komihash_hex("A 16-byte string", 81985529216486895), 'eq', '26af914213d0c915');
cmp_ok(komihash_hex("The new string"  , 81985529216486895), 'eq', '62d9ca1b73250cb5');
cmp_ok(komihash_hex(      "7 chars"   , 81985529216486895), 'eq', '90ab7c9f831cd940');

done_testing();

#############################################################

sub trim {
	my ($s) = (@_, $_); # Passed in var, or default to $_
	if (!defined($s) || length($s) == 0) { return ""; }
	$s =~ s/^\s*//;
	$s =~ s/\s*$//;

	return $s;
}

sub get_data {
	my @ret;

	while (my $line = readline(DATA)) {
		$line = trim($line);

		if ($line) {
			push(@ret, $line);
		}
	}

	return @ret;
}
