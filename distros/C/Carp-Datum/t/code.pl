#
# $Id: code.pl,v 0.1 2001/03/31 10:04:37 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: code.pl,v $
# Revision 0.1  2001/03/31 10:04:37  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

sub ok {
	my ($num, $ok) = @_;
	print "not " unless $ok;
	print "ok $num\n";
}

sub contains {
	my ($file, $pattern) = @_;
	local *FILE;
	local $_;
	open(FILE, $file) || die "can't open $file: $!\n";
	my $found = 0;
	my $line = 0;
	while (<FILE>) {
		$line++;
		if (/$pattern/) {
			$found = 1;
			last;
		}
	}
	close FILE;
	return $found ? $line : 0;
}

1;

