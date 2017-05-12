use strict;
use warnings;

use Crypt::PasswdMD5 'random_md5_salt';

use Test::More;

# ------------------------------------------------

sub length_is
{
	my $in   = shift;
	my $out  = shift;
	my $salt = random_md5_salt($in);

	ok($out == length($salt), "random_md5_salt(). Input: $in. Output length: $out");

} # End of length_is.

# ------------------------------------------------

length_is($_, $_) for (1..8);
length_is(0, 8);
length_is(9, 8);

done_testing;
