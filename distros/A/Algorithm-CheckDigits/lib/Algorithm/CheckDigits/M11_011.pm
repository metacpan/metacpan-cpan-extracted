package Algorithm::CheckDigits::M11_011;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.6';

our @ISA = qw(Algorithm::CheckDigits);

sub new {
	my $proto = shift;
	my $type  = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless({}, $class);
	$self->{type} = lc($type);
	return $self;
} # new()

sub is_valid {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9]+)(\d)(B\d\d)?$/i) {
		return $2 == $self->_compute_checkdigits($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9]+)(?:.(B\d\d))?$/
	   and (my $cd = $self->_compute_checkdigits($1)) ne '') {
		my $tail = $2 || '';
		return $1 . $cd . $tail;
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9]+)(\d)(B\d\d)?$/i) {
		my $tail = $3 ? ".$3" : '';
		return $1 . $tail if ($2 == $self->_compute_checkdigits($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9]+)(\d)(B\d\d)?$/) {
		return $2 if ($2 == $self->_compute_checkdigits($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigits {
	my $self   = shift;
	my $number = shift;

	$number =~ s/\.//g;

	my @digits = split(//,$number);
	my $len = scalar(@digits) + 1;
	my $sum = 0;
	for (my $i = 0; $i <= $#digits; $i++) {
		$sum += ($len - $i) * $digits[$i];
	}
	$sum %= 11;
	return ($sum == 10) ? '' : $sum;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M11_011 - compute check digits for VAT Registration Number (NL)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $ustid = CheckDigits('ustid_nl');

  if ($ustid->is_valid('123456782')) {
	# do something
  }
  if ($ustid->is_valid('123456782B04')) {
	# do something
  }

  $cn = $ustid->complete('12345678');
  # $cn = '123456782'
  $cn = $ustid->complete('12345678.B04');
  # $cn = '123456782B04'

  $cd = $ustid->checkdigit('123456782');
  # $cd = '2'
  $cd = $ustid->checkdigit('123456782B04');
  # $cd = '2'

  $bn = $ustid->basenumber('123456782');
  # $bn = '12345678';
  $bn = $ustid->basenumber('123456782B04');
  # $bn = '12345678.B04';
  
=head1 DESCRIPTION

This VATRN has 12 "digits", the third last must be a I<B>, the fourth
last is the checkdigit. I don't know anything about the meaning of the
last two digits.

You may use the whole VATRN or only the first eight digits to compute
the checkdigit with this module.

=head2 ALGORITHM

=over 4

=item 1

Beginning right with the digit before the checkdigit all digits are
weighted with their position. I.e. the digit before the checkdigit is
multiplied with 2, the next with 3 and so on.

=item 2

The weighted digits are added.

=item 3

The sum from step 2 is taken modulo 11.

=item 4

If the sum from step 3 is 10, the number is discarded.

=back

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if the first eight positions of C<$number> consist
solely of digits (maybe followed by 'B' and to further digits)
and the eighth digit is a valid check digit according to the algorithm
given above.

Returns false otherwise,

=item complete($number)

The check digit for C<$number> is computed and inserted at position
eight of C<$number>.

Returns the complete number with check digit or '' if C<$number>
does not consist solely of digits a dot and maybe 'B' at the ninth
position.

=item basenumber($number)

Returns the basenumber of C<$number> if C<$number> has a valid check
digit.

Return '' otherwise.

=item checkdigit($number)

Returns the check digits of C<$number> if C<$number> has valid check
digits.

Return '' otherwise.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<www.pruefziffernberechnung.de>,

=head1 AUTHOR

Mathias Weidner, C<< <mamawe@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2020 by Mathias Weidner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
