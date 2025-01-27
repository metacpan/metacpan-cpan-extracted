use strict;
use warnings;
use Test::More;
use Crypt::Komihash qw(komihash_hex komihash);
use Config;

my $is_64bit = ($Config{use64bitint} || $Config{use64bitall});

cmp_ok(komihash("9999"           , 464811255086396864) , '==', 1724033458080874576);
cmp_ok(komihash("%%%%%%%%%%%%"   , 6973412667780447232), '==', 5298088715392171192);
cmp_ok(komihash("!!!!!!!!!!!"    , 5373848608311614464), '==', 9528452195980223232);
cmp_ok(komihash("Jason Doolis"   , 1571798247194930432), '==', 4075267677533608411);
cmp_ok(komihash("Tab\tTab"       , 39542889634456848)  , '==', 2473314477071936501);
cmp_ok(komihash("Captain\nPicard", 1486715439267347712), '==', 14729104576727466088);
cmp_ok(komihash("____________"   , 1931211277984306176), '==', 7146112379868711646);
cmp_ok(komihash("\0\0\0\0"       , 0)                  , '==', 204526195655617521);

# Test vectors from the docs: https://github.com/avaneev/komihash/blob/main/README.md
cmp_ok(komihash("A 16-byte string", 0)                , '==', 5079121572472399782);
cmp_ok(komihash("The new string"  , 0)                , '==', 17405963669413835315);
cmp_ok(komihash(      "7 chars"   , 0)                , '==', 3193420946220978635);
cmp_ok(komihash("A 16-byte string", 256)              , '==', 1279898376143709425);
cmp_ok(komihash("The new string"  , 256)              , '==', 4198401542723846697);
cmp_ok(komihash(      "7 chars"   , 256)              , '==', 14986021348583138210);
cmp_ok(komihash("A 16-byte string", 81985529216486895), '==', 2787606407351945493);
cmp_ok(komihash("The new string"  , 81985529216486895), '==', 7122946504907885749);
cmp_ok(komihash(      "7 chars"   , 81985529216486895), '==', 10424562787020495168);

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
