package DateTime::Format::WindowsFileTime;
use DateTime;
use Math::BigInt;

use 5.008005;
use strict;
use warnings;
our $VERSION = '0.02';

sub parse_datetime {
	my($class, $winfiletime) = @_;
	$winfiletime =~ /[a-fA-F0-9]{16}/ 
		or die "Must pass 16 character hex string to parse_datetime";

	$winfiletime = "0x$winfiletime"; # prepend 0x so perl sees it as hex value
	my $bint = Math::BigInt->new( $winfiletime );
	$bint = $bint / 10000;           # was centi-nanoseconds, now it's not
	$bint -= 11644473600000;         # the difference between epochs    
	my $seconds = $bint / 1000;      
	my $dt = DateTime->from_epoch( epoch => $seconds->numify );
	return $dt;
}

1;

__END__
=head1 NAME

DateTime::Format::WindowsFileTime - make a nice DateTime object from the "Windows File Time" hex string. 

=head1 SYNOPSIS

  use DateTime::Format::WindowsFileTime;
  my $dt = DateTime::Format::WindowsFileTime->parse_datetime( '01C4FA8464623000' );
  # $dt is a regular DateTime object
  print "$dt\n";  # yields '2005-01-15T03:00:00'

=head1 DESCRIPTION

Converts a Windows FILETIME into a DateTime object. The Windows
FILETIME structure holds a date and time associated with a
file. The structure identifies a 64-bit integer specifying the
number of 100-nanosecond intervals which have passed since
January 1, 1601.

=head2 EXPORT

None by default.

=head1 METHODS

=head2 parse_datetime

Is called as a class method (use the arrow) and takes a string representing 
the windows filetime hex value as it's sole argument.  Returns a DateTime object.

Note:  don't pass it a hex number in perl (eg. 0x01c4fa8464623000).  Just a string.

=head1 SEE ALSO

L<DateTime>

=head1 THANKS

Doug wrote the guts to the method, Jim just surrounded it with what h2xs pukes out, and published it.

Thanks to Robert A. Lerche for finding a bug and recommending the fix.

=head1 AUTHOR

Jim, E<lt>jg.perl@thegarvin.comE<gt>, Doug, E<lt>df.cpan@feuerbach.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Jim

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
