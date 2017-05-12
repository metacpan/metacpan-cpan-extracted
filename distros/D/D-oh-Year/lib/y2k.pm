package y2k;

use D'oh::Year qw(:DIE);

use strict;
use vars qw($VERSION);
$VERSION = 0.10;

sub import {
	my $caller = caller;
	{
		no strict 'refs';
		*{$caller . '::localtime'} 	= \&localtime;
		*{$caller . '::gmtime'}		= \&gmtime;
	}
}

=pod

=head1 NAME

  y2k - A simple module to detect y2k bugs


=head1 SYNOPSIS

	use y2k;

	$year = (localtime)[5];
	print "19$year is a good year to die";
	

=head1 DESCRIPTION

Most Y2k bugs written in Perl are typically very easy to catch.  This module catches
them.  The idea is simple, it provides its own loaded versions of localtime()
and gmtime() which return trick years.  If this year is used in a manner which is
not "cross-decade compliant", your program will die with an error.

This is a thin legacy wrapper around D'oh::Year.  Use that instead.


=head1 SEE ALSO

L<D'oh::Year>


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=cut

return 19100;
