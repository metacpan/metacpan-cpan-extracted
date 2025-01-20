use strict;
use warnings;
use Test::More;
use Crypt::Komihash qw(komihash_hex komihash);
use Config;

my $is_64bit = ($Config{use64bitint} || $Config{use64bitall});

cmp_ok(komihash("9999"           , 464811255086396864) , 'eq', '1724033458080874576');
cmp_ok(komihash("%%%%%%%%%%%%"   , 6973412667780447232), 'eq', '5298088715392171192');
cmp_ok(komihash("!!!!!!!!!!!"    , 5373848608311614464), 'eq', '9528452195980223232');
cmp_ok(komihash("Jason Doolis"   , 1571798247194930432), 'eq', '4075267677533608411');
cmp_ok(komihash("Tab\tTab"       , 39542889634456848)  , 'eq', '2473314477071936501');
cmp_ok(komihash("Captain\nPicard", 1486715439267347712), 'eq', '14729104576727466088');
cmp_ok(komihash("____________"   , 1931211277984306176), 'eq', '7146112379868711646');
cmp_ok(komihash("\0\0\0\0"       , 0)                  , 'eq', '204526195655617521');

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
