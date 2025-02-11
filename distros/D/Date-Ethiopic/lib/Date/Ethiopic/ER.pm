package Date::Ethiopic::ER;
use utf8;

BEGIN
{
	require 5.000;

	use strict;
	use warnings;
	use vars qw(
		%EritreanHolidays
		%EritreanHolidaysTranscribed
	);

	$VERSION = "0.15";

	#
	# Legal Holidays, this will be localized later.
	# Some verification is also needed.
	#
	# double check how leap year impacts christmas, my memory
	# is that is moves backwars 29->28 following leap year
	# such that it fixes on Jan. 7.
	#
	%EritreanHolidays =(
		"ርእስ ዓመት"		=>   [1,1],  #  መስከረም  1
		"መስቀል ክቡር"		=>  [17,1],  #  መስከረም 17
		"ሓዲሽ ዓመት"		=>  [22,4],  #  ታህሳስ  22/23  23 on leap year
		"ልደተ ክርስቶስ"		=>  [29,4],  #  ታኅሣሥ  29
		"በዓል ጥምቀት"		=>  [11,5],  #  ጥሪ    11 
		"መዓልቲ ደቀንስትዮ" 		=>  [29,6],  #  ለካቲት  29 
		"በዓል ሰራሕተኛ" 		=>  [24,8],  #  ሚያዝያ  24 
		"ሆሳዕና"			=> ['?',8],  #  ሚያዝያ - Palm Sunday
		"የስቅለት በዓል"		=> ['?',8],  #  ሚያዝያ -Final Friday
		"ትንሣኤ"			=> ['?',8],  #  ሚያዝያ -Final Sunday
		"መዓልቲ ሓርነት (ዮሃና)"	=>  [16,9],  #  ግንቦት  16 
		"መዓልቲ ስውኣት"		=> [23,10],  #  ሰነ    24/23 check this
		"ም. ብረታዊ ቃልሲ"		=> [26,12],  #  ነሓሰ   26
	);
	%EritreanHolidaysTranscribed =(
	);
}


sub _sep
{
	($_[0]->{_trans}) ? ", " : "፡ ";
}


sub bc
{
	($_[0]->{_trans}) ? "A/A" : "ዓ/ዓ";
}


sub ad
{
	($_[0]->{_trans}) ? "A/M" : "ዓ/ም";
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Date::Ethiopic::ER - Eritrean Calendar Data for L<Date::Ethiopic>.

=head1 DESCRIPTION

The Date::Ethiopic::ER module is a base class for modules under
the Date::Ethiopic::ER namespace, it is not intended for independent use.

=head1 CREDITS

Yeha: L<http://yeha.sourceforge.net>

=head1 REQUIRES

Date::Ethiopic, which is distributed in the same package with
this file.

=head1 BUGS

The use of "use utf8" will break for older versions of Perl.  Feel free
to comment out this line.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
