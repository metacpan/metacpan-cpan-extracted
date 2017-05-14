package Carrot::Meta::Greenhouse::Narrowed_RE
# /type class
# /instances singular
# /capability "Maintains a library of commonly used REs"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Narrowed_RE./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub substitute_softspace_line
# /type method
# /effect ""
# //parameters
#	pattern
#	region
# //returns
{
	my ($this, $pattern, $region) = @ARGUMENTS;

	unless (length($pattern) == length($region))
	{
		die("Pattern and region differ in length\n'$pattern'\n'region'\n");
	}
	my $sectors = [$region =~ m{\A(_*)(\^-+\^|^^|^)(_*)\z}s];
	unless (@$sectors)
	{
		die("No ^ sector in region '$region'.");
	}
	my $lengths = [map(length($_), @$sectors)];

	$sectors = [];
	my $offset = 0;
	foreach my $l (@$lengths)
	{
		my $s = substr($pattern, $offset, $l);
		$s =~ s{\h}{\\h+}saag;
		$s =~ s{#}{\\#}saag;
		push($sectors, $s);
		$offset += $l;
	}

	my $re = sub { return(${$_[0]} =~ s
		{(?:\012|\015\012?)\h*$sectors->[0]\K$sectors->[1]($sectors->[2])}
		{$_[1]$1}sx) };

	return($re);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.4
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
