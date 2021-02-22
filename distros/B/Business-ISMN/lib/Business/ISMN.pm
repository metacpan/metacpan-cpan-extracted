use 5.008;

package Business::ISMN;
use strict;

use subs qw(
	_common_format _checksum is_valid_checksum
	INVALID_PUBLISHER_CODE
	BAD_CHECKSUM
	GOOD_ISMN
	BAD_ISMN
	);
use vars qw( $debug %country_data $MAX_COUNTRY_CODE_LENGTH );

use Carp qw(carp);
use Exporter qw(import);
use List::Util qw(sum);
use Tie::Cycle;
use Business::ISMN::Data;

my $debug = 0;

our @EXPORT_OK = qw(is_valid_checksum ean_to_ismn ismn_to_ean
	INVALID_PUBLISHER_CODE BAD_CHECKSUM GOOD_ISMN BAD_ISMN);

our $VERSION = '1.202';

sub INVALID_PUBLISHER_CODE { -3 };
sub BAD_CHECKSUM           { -1 };
sub GOOD_ISMN              {  1 };
sub BAD_ISMN               {  0 };

my %Lengths = qw(
	0 3
	1 4
	2 4
	3 4
	4 5
	5 5
	6 5
	7 6
	8 6
	9 7
	);

sub new {
	my $class       = shift;
	my $common_data = _common_format shift;

	return unless defined $common_data;

	my $self  = {};
	bless $self, $class;

	$self->{'ismn'}      = $common_data;
	$self->{'positions'} = [1,undef,9];

	# we don't know if we have a valid publisher code,
	# so let's assume we don't
	$self->{'valid'} = INVALID_PUBLISHER_CODE;

	# let's check the publisher code.
	my $code_length = $Lengths{ substr( $self->{'ismn'}, 1, 1 ) };
	$self->{publisher_code} = substr(
		$self->{'ismn'},
		1,
		$code_length
		);

	my $code_end = $code_length + 1;

	$self->{'positions'}[1] = $code_end;

	return $self unless $self->is_valid_country_code;

	# we have a good publisher code, so
	# assume we have a bad checksum until we check
	$self->{'valid'} = BAD_CHECKSUM;

	$self->{'article_code'} = substr( $self->{'ismn'}, $code_end, 9 - $code_end );
	$self->{'checksum'}     = substr( $self->{'ismn'}, -1, 1 );

	$self->{'valid'} = is_valid_checksum( $self->{'ismn'} );

	return $self;
	}


#it's your fault if you muck with the internals yourself
# none of these take arguments
sub ismn ()             { my $self = shift; return $self->{'ismn'} }
sub is_valid ()         { my $self = shift; return $self->{'valid'} }
sub country ()          { my $self = shift; return $self->{'country'} }
sub publisher ()        { carp "publisher is deprecated. Use country instead."; &country }
sub publisher_code ()   { my $self = shift; return $self->{'publisher_code'} }
sub article_code ()     { my $self = shift; return $self->{'article_code'} }
sub checksum ()         { my $self = shift; return $self->{'checksum'} }
sub hyphen_positions () { my $self = shift; return @{$self->{'positions'}} }


sub fix_checksum {
	my $self = shift;

	my $last_char = substr($self->{'ismn'}, 9, 1);
	my $checksum = _checksum $self->ismn;

	substr($self->{'ismn'}, 9, 1) = $checksum;

	$self->_check_validity;

	return 0 if $last_char eq $checksum;
	return 1;
	}

sub as_string {
	my $self      = shift;
	my $array_ref = shift;

	#this allows one to override the positions settings from the
	#constructor
	$array_ref = $self->{'positions'} unless ref $array_ref eq 'ARRAY';

	return unless $self->is_valid eq GOOD_ISMN;
	my $ismn = $self->ismn;

	foreach my $position ( sort { $b <=> $a } @$array_ref )
		{
		next if $position > 9 or $position < 1;
		substr($ismn, $position, 0) = '-';
		}

	return $ismn;
	}

sub as_ean {
	my $self = shift;

	my $ismn = ref $self ? $self->as_string([]) : _common_format $self;

	return unless ( defined $ismn and length $ismn == 10 );

	# the M becomes a zero in bookland
	substr( $ismn, 0, 1 ) = '0';

	my $ean = '979' . substr($ismn, 0, 9);

	my $sum = 0;
	foreach my $index ( 0, 2, 4, 6, 8, 10 ) {
		$sum +=     substr($ean, $index, 1);
		$sum += 3 * substr($ean, $index + 1, 1);
		}

	#take the next higher multiple of 10 and subtract the sum.
	#if $sum is 37, the next highest multiple of ten is 40. the
	#check digit would be 40 - 37 => 3.
	$ean .= ( 10 * ( int( $sum / 10 ) + 1 ) - $sum ) % 10;

	return $ean;
	}

sub is_valid_country_code {
	my $self = shift;
	my $code = $self->publisher_code;

	my $success = 0;

	foreach my $tuple ( @publisher_tuples ) {
		no warnings;
		next if( defined $tuple->[2] and $code > $tuple->[2] );
		last if $code < $tuple->[1];
		if( $code >= $tuple->[1] and $code <= $tuple->[2] ) {
			$success = 1;
			$self->{'country'} = $tuple->[0];
			last;
			}
		}

	return $success;
	}

sub is_valid_publisher_code {
	carp "is_valid_publisher_code is deprecated. Use is_valid_country_code";
	&is_valid_country_code
	}

sub is_valid_checksum {
	my $data = _common_format shift;

	return BAD_ISMN unless defined $data;

	return GOOD_ISMN if substr($data, 9, 1) eq _checksum $data;

	return BAD_CHECKSUM;
	}

sub ean_to_ismn {
	my $ean = shift;

	$ean =~ s/[^0-9]//g;

	return unless length $ean == 13;
	return unless substr($ean, 0, 3) eq 979;

	#XXX: fix to change leading 0 back to M
	my $ismn = Business::ISMN->new( substr($ean, 3, 9) . '1' );

	$ismn->fix_checksum;

	return $ismn->as_string([]) if $ismn->is_valid;

	return;
	}


sub ismn_to_ean {
	my $ismn = _common_format shift;

	return unless (defined $ismn and is_valid_checksum($ismn) eq GOOD_ISMN);

	return as_ean($ismn);
	}

sub png_barcode {
	my $self = shift;

	my $ean = ismn_to_ean( $self->as_string([]) );

	eval "use GD::Barcode::EAN13";
	if( $@ ) {
		carp "GD::Barcode::EAN13 required to make PNG barcodes";
		return;
		}

	my $image = GD::Barcode::EAN13->new($ean)->plot->png;

	return $image;
	}

#internal function.  you don't get to use this one.
sub _check_validity {
	my $self = shift;

	if( is_valid_checksum $self->{'ismn'} eq GOOD_ISMN
	    and defined $self->{'publisher_code'} ) {
	    $self->{'valid'} = GOOD_ISMN;
	    }
	else {
		$self->{'valid'} = INVALID_PUBLISHER_CODE
			unless defined $self->{'publisher_code'};
		$self->{'valid'} = GOOD_ISMN
			 unless is_valid_checksum $self->{'ismn'} ne GOOD_ISMN;
		}
	}

#internal function.  you don't get to use this one.
sub _checksum {
	my $data = _common_format shift;

	tie my $factor, 'Tie::Cycle', [ 1, 3 ];
	return unless defined $data;

	my $sum = 9;

	foreach my $digit ( split //, substr( $data, 1, 8 ) ) {
		my $mult = $factor;
		$sum += $digit * $mult;
		}

	#return what the check digit should be
	# the extra mod 10 turns 10 into 0.
	my $checksum = ( 10 - ($sum % 10) ) % 10;

	return $checksum;
	}

#internal function.  you don't get to use this one.
sub _common_format {
	no warnings qw(uninitialized);
	#we want uppercase X's
	my $data = uc shift;

	# get rid of everything except decimal digits and X
	# and leading M
	$data =~ s/[^0-9M]//g;

	return $1 if $data =~ m/
						^
						(
						M
						\d{9}
						)
						$
						/x;

	return;
	}

1;

__END__

=encoding utf8

=head1 NAME

Business::ISMN - work with International Standard Music Numbers

=head1 SYNOPSIS

	use Business::ISMN;

	$ismn_object = new Business::ISMN('M021765430');
	$ismn_object = new Business::ISMN('M-021-76543-0');

	#print the ISMN with hyphens at positions specified
	#by constructor
	print $ismn_object->as_string;

	#print the ISMN with hyphens at specified positions.
	#this not does affect the default positions
	print $ismn_object->as_string([]);

	#print the publication country or publisher code
	print $ismn->country;         # two letter country string
	print $ismn->publisher_code;  # digits

	#check to see if the ISMN is valid
	$ismn_object->is_valid;

	#fix the ISMN checksum.  BEWARE:  the error might not be
	#in the checksum!
	$ismn_object->fix_checksum;

	# create an EAN13 barcode in PNG format
	$ismn_object->png_barcode;

	#EXPORTABLE FUNCTIONS

	use Business::ISMN qw( is_valid_checksum
		ismn_to_ean ean_to_ismn );

	#verify the checksum
	if( is_valid_checksum('0123456789')
		eq Business::ISMN::GOOD_ISMN )
		{ ... }

	#convert to EAN (European Article Number)
	$ean = ismn_to_ean('1565921496');

	#convert from EAN (European Article Number)
	$ismn = ean_to_ismn('9781565921498');

=head1 DESCRIPTION

=head2 Methods

=over 4

=item new($ismn)

The constructor accepts a scalar representing the ISMN.

The string representing the ISMN may contain characters
other than C<[0-9mM]>, although these will be removed in the
internal representation.  The resulting string must look
like an ISMN - the first character is an 'M' and the
following nine characters must be digits.

The constructor attempts to determine the country
code and the publisher code.  If these data cannot
be determined, the constructor sets C<$obj-E<gt>is_valid>
to something other than C<GOOD_ISMN>.
An object is still returned and it is up to the program
to check C<$obj-E<gt>is_valid> for one of five values (which
may be exported on demand). The actual values of these
symbolic versions are the same as those from previous
versions of this module which used literal values.

	Business::ISMN::INVALID_PUBLISHER_CODE
	Business::ISMN::BAD_CHECKSUM
	Business::ISMN::GOOD_ISMN
	Business::ISMN::BAD_ISMN

The string passed as the ISMN need not be a valid ISMN as
long as it superficially looks like one.  This allows one to
use the C<fix_checksum()> method.  Despite the disclaimer in
the discussion of that method, the author has found it
extremely useful.  One should check the validity of the ISMN
with C<is_valid()> rather than relying on the return value
of the constructor.  If all one wants to do is check the
validity of an ISMN, one can skip the object-oriented
interface and use the C<is_valid_checksum()> function
which is exportable on demand.

If the constructor decides it cannot create an object, it
returns C<undef>.  It may do this if the string passed as the
ISMN cannot be munged to the internal format meaning that it
does not even come close to looking like an ISMN.

=item ismn

Returns the ISMN as a string

=item country

=item publisher

Returns the country associated with the publisher code. This method was
formerly called C<publisher> (and that still works), but it's really
returns a two letter country code.

=item publisher_code

Returns the publisher code or C<undef> if no publisher code was found.

=item article_code

Returns the article code or C<undef> if no article
code was found.

=item checksum

Returns the checksum or C<undef> if no publisher
code was found.

=item hyphen_positions

Returns the list of hyphen positions as determined from the
country and publisher codes.  the C<as_string> method provides
a way to temporarily override these positions and to even
forego them altogether.

=item as_string(),  as_string([])

Return the ISMN as a string.  This function takes an
optional anonymous array (or array reference) that specifies
the placement of hyphens in the string.  An empty anonymous array
produces a string with no hyphens. An empty argument list
automatically hyphenates the ISMN based on the discovered
publisher code.  An ISMN that is not valid may
produce strange results.

The positions specified in the passed anonymous array
are only used for one method use and do not replace
the values specified by the constructor. The method
assumes that you know what you are doing and will attempt
to use the least three positions specified.  If you pass
an anonymous array of several positions, the list will
be sorted and the lowest three positions will be used.
Positions less than 1 and greater than 9 are silently
ignored.

=item  is_valid

Returns C<Business::ISMN::GOOD_ISMN> if the checksum is valid and the
country and publisher codes are defined.

Returns C<Business::ISMN::BAD_CHECKSUM> if the ISMN does not pass
the checksum test. The constructor accepts invalid ISMN's so that
they might be fixed with C<fix_checksum>.

Returns C<Business::ISMN::INVALID_PUBLISHER_CODE> if a publisher code
could not be determined.

Returns C<Business::ISMN::BAD_ISMN> if the string has no hope of ever
looking like a valid ISMN.  This might include strings such as C<"abc">,
C<"123456">, and so on.

=item is_valid_country_code

=item is_valid_publisher_code

Returns true if the country code is valid, and false otherwise.

This method was formerly called C<is_valid_publisher_code>. That's
deprecated but still there.

=item  fix_checksum()

Replace the tenth character with the checksum the
corresponds to the previous nine digits.  This does not
guarantee that the ISMN corresponds to the product one
thinks it does, or that the ISMN corresponds to any product
at all.  It only produces a string that passes the checksum
routine.  If the ISMN passed to the constructor was invalid,
the error might have been in any of the other nine positions.

=item  $obj-E<gt>as_ean()

Converts the ISMN to the equivalent EAN (European Article Number).
No pricing extension is added.  Returns the EAN as a string.  This
method can also be used as an exportable function since it checks
its argument list to determine what to do.

=item png_barcode()

Creates a PNG image of the EAN13 barcode which corresponds to the
ISMN. Returns the image as a string.

=back

=head2 EXPORTABLE FUNCTIONS

Some functions can be used without the object interface.  These
do not use object technology behind the scenes.

=over 4

=item is_valid_checksum('M021765430')

Takes the ISMN string and runs it through the checksum
comparison routine.  Returns C<Business::ISMN::GOOD_ISMN>
if the ISMN is valid, C<Business::ISMN::BAD_CHECKSUM> if the
string looks like an ISMN but has an invalid checksum, and
C<Business::ISMN::BAD_ISMN> if the string does not look like
an ISMN.

=item ismn_to_ean('M021765430')

Takes the ISMN string and converts it to the equivalent
EAN string.  This function checks for a valid ISMN and will return
undef for invalid ISMNs, otherwise it returns the EAN as a string.
Uses as_ean internally, which checks its arguments to determine
what to do.

=item ean_to_ismn('9790021765439')

Takes the EAN string and converts it to the equivalent
ISMN string.  This function checks for a valid ISMN and will return
undef for invalid ISMNs, otherwise it returns the EAN as a string.
Uses as_ean internally, which checks its arguments to determine
what to do.

=back

=head1 TO DO

* i need more ISMN numbers for tests

=head1 SOURCE AVAILABILITY

This source is in Github:

    https://github.com/briandfoy/business-ismn/

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2001-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut
