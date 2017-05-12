package Business::AU::TFN;
use vars qw/$VERSION/;
$VERSION = "0.1";

=head1 NAME

Business::AU::TFN - Validate TFN - Australian Tax File Name

=head1 SYNOPSIS

    use Business::AU::TFN;
 
    print Business::AU::TFN::validate("123 456 782");

=head1 DESCRIPTION

=head1 NOTES

Details come from http://bioinf.wehi.edu.au/folders/fred/tfn.html

=head1 METHODS

Currently these are package methods which must be called explicitly.
Although I am considering making this better.

=head1 METHODS

=cut

use constant WEIGHT => qw/1 4 3 7 5 8 6 9 10/;

=head2 validate($tfn)

Validate a tax file number. Return value is one of

'valid' - yep, completely valid

'invalid length' - Must be 9 characteres (spaces accepted)

'invalid sum' - does not match

=cut

sub validate {
	my ($tfn) = @_;
	my @tfn = _split($tfn);
	
	# check length is 9
	unless (@tfn == 9) {
		return "invalid length (must be 9)";
	}

	# add accumulation
	my $acc = 0;
	for (my $i = 0; $i < 9; $i++) {
		$acc += $tfn[$i] * (WEIGHT)[$i]
	}

	# check it is valid
	if (($acc % 11) == 0) {
		return "valid";
	}

	return "invalid sum";
}

sub _split {
	my ($tfn) = @_;
	$tfn =~ s/\s//g;
	return split(//, $tfn);
}

=head2 pretty($tfn)

This prints out a valid pretty print of an TFN The standards says that it must
be showed in groups of three (nnn nnn nnn).

=cut

sub pretty {
	my ($tfn) = @_;
	my @tfn = _split($tfn);
	if (validate($tfn) eq "valid") {
		return join('', @tfn[0..2], ' ', @tfn[3..5], ' ', @tfn[6..8]);
	} else {
		return "invalid";
	}
}

=head1 AUTHOR

Scott Penrose <scottp@dd.com.au>

=head1 SEE ALSO

L<Business::AU::ACN>, L<Business::AU::ABN>

=cut

1;
