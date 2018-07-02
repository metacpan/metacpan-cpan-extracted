use strict;
use warnings;
use Test::More;
use Algorithm::Networksort;
use Algorithm::Networksort::Best qw(:all);

require "t/zero_one.pl";

my @names;

our $author_testing = $ENV{AUTHOR_TESTING};
@names= sort sizename_cmp nw_best_names();

#
# Spare the CPAN testers from testing networks greater
# than 15 inputs.
#
unless ($author_testing)
{
	@names = grep{/^[a-z]+0[0-9]$|^[a-z]+1[0-5]$/} @names;
}

diag("Networks to test: " . join(", ", @names));

plan tests => 1 + scalar @names;
ok(scalar @names > 0, "@names");

for (@names)
{
	my $nw = nwsrt_best(name => $_);

	my $status = zero_one($nw);
	is($status, "pass", "$_, $status, " . $nw->title());
}

sub sizename_cmp
{
	my($aname, $asize, $bname, $bsize) = ($a, 999, $b, 999);
	if ($a =~ /^([a-z]+)(\d+)$/)
	{
		$aname = $1; $asize = $2;
	}
	if ($b =~ /^([a-z]+)(\d+)$/)
	{
		$bname = $1; $bsize = $2;
	}
	return ($asize <=> $bsize || $aname cmp $bname);
}

1;
