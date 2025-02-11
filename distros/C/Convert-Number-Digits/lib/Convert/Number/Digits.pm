package Convert::Number::Digits;

use utf8;
binmode(STDERR, ":utf8");
binmode(STDOUT, ":utf8");

BEGIN
{
use strict;
use warnings;
use vars qw( %Digits $VERSION );

$VERSION = "0.06";

%Digits =(
	toWestern	=> "0-9",
	toArabic	=> "\x{0660}-\x{0669}",
	toArabicIndic	=> "\x{06F0}-\x{06F9}",
	toDevanagari	=> "\x{0966}-\x{096F}",
	toBengali	=> "\x{09E6}-\x{09EF}",
	toGurmukhi	=> "\x{0A66}-\x{0A6F}",
	toGujarati	=> "\x{0AE6}-\x{0AEF}",
	toOriya		=> "\x{0B66}-\x{0B6F}",
	toTamil		=> "0\x{0BE7}-\x{0BEF}",
	toTelugu	=> "\x{0C66}-\x{0C6F}",
	toKannada	=> "\x{0CE6}-\x{0CEF}",
	toMalayalam	=> "\x{0D66}-\x{0D6F}",
	toThai		=> "\x{0E50}-\x{0E59}",
	toLao		=> "\x{0ED0}-\x{0ED9}",
	toTibetan	=> "\x{0F20}-\x{0F29}",
	toMyanmar	=> "\x{1040}-\x{1049}",
	toEthiopic 	=> "0\x{1369}-\x{1371}",
	toKhmer		=> "\x{17E0}-\x{17E9}",
	toMongolian	=> "\x{1810}-\x{1819}",
	toLimbu    	=> "\x{1946}-\x{194F}",
	toRomanUpper	=> "0\x{2160}-\x{2168}",
	toRomanLower	=> "0\x{2170}-\x{2178}",
	toFullWidth	=> "\x{FF10}-\x{FF19}",
	toOsmanya	=> "\x{104A0}-\x{104A9}",
	toBold		=> "\x{1D7CE}-\x{1D7D7}",
	toDoubleStruck 	=> "\x{1D7D8}-\x{1D7E1}",
	toSansSerif	=> "\x{1D7E2}-\x{1D7EB}",
	toSansSerifBold	=> "\x{1D7EC}-\x{1D7F5}",
	toMonoSpace	=> "\x{1D7F6}-\x{1D7FF}"
);

}


sub _setArgs
{
my ($self, $number) = @_;

	if ( $#_ > 1 ) {
		warn (  "too many arguments." );
		return;
	}
	unless ( $number =~ /^\d+$/ || ($number =~ /[$Digits{toRomanUpper}]/) || ($number =~ /[$Digits{toRomanLower}]/) || ($number =~ /[$Digits{toEthiopic}]/) ) {
		warn (  "$number is not a digit." );
		return;
	}

	$self->{number} = $number;

1;
}


sub new
{
my $class = shift;
my $self  = {};

	my $blessing = bless ( $self, $class );

	$self->{number} = undef;

	$self->_setArgs ( @_ ) || return if ( @_ );

	$blessing;
}


sub number
{
my $self = shift;

	$self->_setArgs ( @_ ) || return
		if ( @_ );

	$self->{number};
}


sub convert
{
my $self = shift;

	#
	# reset string if we've been passed one:
	#
	$self->number ( @_ ) if ( @_ );

	my $number = $self->number;
	return $number if ( $number =~ /^[0-9]+$/ );

	my $method = "toWestern";
	foreach my $script (keys %Digits) {
		next if ( $script eq $method );
		eval "\$number =~ tr/$Digits{$script}/$Digits{$method}/";
	}

	$number;
}


sub toMethods
{
	sort keys %Digits;
}


sub AUTOLOAD
{
my ($self, $number) = @_;


	my ($method) = ( $AUTOLOAD =~ /::([^:]+)$/ );
	return unless ( $method && ($method ne "DESTROY") );

	return unless ( $Digits{$method} );

	$number = $self->{number} unless ( defined($number) );

	foreach my $script (keys %Digits) {
		next if ( $script eq $method );
		eval "\$number =~ tr/$Digits{$script}/$Digits{$method}/";
	}

	$number;
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=encoding utf8

=head1 NAME

Convert::Number::Digits - Convert Digits Between the Scripts of Unicode.


=head1 SYNOPSIS

 use utf8;
 require Convert::Number::Digits;

 my $number = 12345;
 my $d = new Convert::Number::Digits ( $number );
 print "$number => ", $d->toArabic, "\n";

 my $gujarti = $d->toGujarti;
 my $khmer = reverse ( $d->toKhmer );
 $d->number ( $khmer );  # reset the number
 print "$number => $gujarti => ", $d->number, " => ", $n->convert, "\n";


=head1 DESCRIPTION

The C<Convert::Number::Digits> will convert a sequence of digits from one
script supported in Unicode, into another.  UTF-8 encoding is used
for all scripts.


=head2 METHODS

=over 4

=item C<convert> - outputs digits in Western script (0-9).

=item C<toMethods> - get a list of the following conversion methods:

=over 4

=item C<toArabic> - output digits in Arabic script (١-٢).

=item C<toArabicIndic> - output digits in ArabicIndic script (۱-۲).

=item C<toBengali> - output digits in Bengali script (১-২).

=item C<toBold> - output digits in Bold script (𝟏-𝟐).

=item C<toDevanagari> - output digits in Devanagari script (१-२).

=item C<toDoubleStruck> - output digits in DoubleStruck script (𝟙-𝟚).

=item C<toEthiopic> - output digits in Ethiopic script (፩-፪).

=item C<toFullWidth> - output digits in FullWidth script (１-２).

=item C<toGujarati> - output digits in Gujarati script (૧-૨).

=item C<toGurmukhi> - output digits in Gurmukhi script (੧-੨).

=item C<toKannada> - output digits in Kannada script (೧-೨).

=item C<toKhmer> - output digits in Khmer script (១-២).

=item C<toLao> - output digits in Lao script (໑-໒).

=item C<toLimbu> - output digits in Limbu script (᥆-᥏).

=item C<toMalayalam> - output digits in Malayalam script (൧-൨).

=item C<toMongolian> - output digits in Mongolian script (᠑-᠒).

=item C<toMonoSpace> - output digits in MonoSpace script (𝟷-𝟸).

=item C<toMyanmar> - output digits in Myanmar script (၁-၂).

=item C<toOriya> - output digits in Oriya script (୧-୨).

=item C<toOsmanya> - output digits in Osmanya script (𐒠-𐒩).

=item C<toRomanLower> - output digits in lowercase Roman numerals (ⅰ-ⅸ).

=item C<toRomanUpper> - output digits in uppercase Roman numerals (Ⅰ-Ⅸ).

=item C<toSansSerif> - output digits in SansSerif script (𝟣-𝟤).

=item C<toSansSerifBold> - output digits in SansSerifBold script (𝟭-𝟮).

=item C<toTamil> - output digits in Tamil script (௧-௨).

=item C<toTelugu> - output digits in Telugu script (౧-౨).

=item C<toThai> - output digits in Thai script (๑-๒).

=item C<toTibetan> - output digits in Tibetan script (༡-༢).

=back

=back


=head1 CAVAETS

Ethiopic, Roman and Tamil scripts do not have a zero.  Western 0 is used instead.

Though a script has digits its numeral system is not necessarily digital.
For example, Roman, Coptic, Ethiopic, Greek and Hebrew.  If you convert
digits into these systems it is assumed that you know what you are doing
(and your starting number is an applicable sequence).  The C<Convert::Number::Digits>
package converts digits and not numbers.


=head1 REQUIRES

The package is known to work on Perl 5.6.1 and 5.8.0 but has not been tested on
other versions of Perl by the author. 

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

L<Convert::Number::Coptic>    L<Convert::Number::Ethiopic>

Included with this package:

  examples/digits.pl

=cut
