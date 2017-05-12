#
#   Copyright (c) 2005, Presicient Corp., USA
#
# Permission is granted to use this software according to the terms of the
# Artistic License, as specified in the Perl README file,
# with the exception that commercial redistribution, either 
# electronic or via physical media, as either a standalone package, 
# or incorporated into a third party product, requires prior 
# written approval of the author.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Presicient Corp. reserves the right to provide support for this software
# to individual sites under a separate (possibly fee-based)
# agreement.
#
#	History:
#
#		2005-Jan-27		D. Arnold
#			Coded.
#
package SQL::Amazon::Functions;
use strict;

our $VERSION = '0.10';
sub SQL_FUNCTION_AMZN_MATCH_ANY { return undef; }

sub SQL_FUNCTION_AMZN_MATCH_ALL { return undef; }

sub SQL_FUNCTION_AMZN_MATCH_TEXT { return undef; }

sub SQL_FUNCTION_AMZN_POWER_SEARCH { return undef; }
sub SQL_FUNCTION_AMZN_IN_ANY {
	my ($obj, $sth, $rowhash, $expr, @list) = @_;
	return join(',', @list)
		unless (defined($rowhash) && 
			(scalar keys %$rowhash));
	return undef 
		unless defined($expr);

	foreach (@list) {
		next unless defined($_);
		return 1
			if ((is_number($expr) && is_number($_) && ($expr == $_)) ||
				($expr eq $_));
	}
	return undef;
}

sub SQL_FUNCTION_AMZN_NOT_IN_ANY {
	my ($obj, $sth, $rowhash, $expr, @list) = @_;
	return 1 unless defined($expr);

	foreach (@list) {
		next unless defined($_);
		return undef 
			if ((is_number($expr) && is_number($_) && ($expr == $_)) ||
				($expr eq $_));
	}
	return 1;
}

sub is_number {
	my $v = shift;
    return ($v=~/^([+-]?|\s+)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
}
1;
