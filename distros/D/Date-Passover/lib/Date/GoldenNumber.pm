#$Header: /cvsroot/date-passover/lib/Date/GoldenNumber.pm,v 1.1 2001/08/05 11:52:46 rbowen Exp $
package Date::GoldenNumber;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = (qw'$Revision')[1];
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw (golden);
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

=head1 NAME

Date::GoldenNumber - Calculates the golden number used in John Conway's date calculations

=head1 SYNOPSIS

  use Date::GoldenNumber;
  $g = golden( 1992 );

=head1 DESCRIPTION

Most of John Conway's date calculation algorithms need the golden
number, which is Remainder(Y/19) + 1. Yes, this is very simple, but it
is inconvenient to have to rember this.

=head1 SUPPORT

datetime@perl.org

=head1 AUTHOR

	Rich Bowen
	CPAN ID: RBOW
	rbowen@rcbowen.com
	http://www.rcbowen.com

=head1 COPYRIGHT

Copyright (c) 2001 Rich Bowen. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

 perl
 Date::Easter
 Date::Passover

=cut

sub golden {
    my $year = shift;
    my $g = ( $year % 19 ) + 1;
    return $g;
}

1;

