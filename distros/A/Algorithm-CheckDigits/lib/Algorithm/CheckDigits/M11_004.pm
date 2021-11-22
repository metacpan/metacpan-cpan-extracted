package Algorithm::CheckDigits::M11_004;

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
	if ($number =~ /^([-\d.]+)(\d\d)$/) {
		return $2 eq $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^[-\d.]+$/) {
		my $cd = $self->_compute_checkdigit($number);
		return $number . $cd unless 0 > $cd;
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^([-\d.]+)(\d\d)$/) {
		return $1 if ($2 eq $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^([-\d.]+)(\d\d)$/) {
		return $2 if ($2 eq $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;
	my ($cd1,$cd2) = ('','');

	my $calc_cd = sub {
		my $number = shift;
		my $weight = shift;
		my @digits = split(//,$number);
		my $sum    = 0;
		for (my $i = 0; $i <= $#digits; $i++) {
			$sum += $weight * $digits[$i];
			--$weight;
		};
		$sum %= 11;
		return 0 if (2 > $sum);
		return 11 - $sum;
	};

	return -1 unless ($number =~ /^[-\d.]+$/);

	$number =~ s/[-.]//g;
	if ('cpf' eq $self->{type}) {
		return -1 unless length($number) == 9;
		$cd1 = $calc_cd->($number,10);
		$cd2 = $calc_cd->($number . $cd1,11);
	} elsif ('titulo_eleitor' eq $self->{type}) {
		$number = substr("00000000000" . $number, -10);
		$cd1 = $calc_cd->(substr($number,0,8),9);
		$cd2 = $calc_cd->(substr($number,-2) . $cd1,4);
	}
	return $cd1 . $cd2;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=encoding iso-8859-1

=head1 NAME

CheckDigits::M11_004 - compute check digits for CPF (BR), Título Eleitoral (BR)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $cpf = CheckDigits('cpf');

  if ($cpf->is_valid('043.033.407-90')) {
	# do something
  }

  $cn = $cpf->complete('043.033.407-');
  # $cn = '043.033.407-90'

  $cd = $cpf->checkdigit('043.033.407-90');
  # $cd = '90'

  $bn = $cpf->basenumber('043.033.407-90');
  # $bn = '043.033.407-'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

From left to right all digits are multiplied with their position
in the sequence.

=item 2

The sum of all products is computed.

=item 3

The sum of step 2 is taken modulo 11.

a) If the result is 0 or 1 the checkdigit is 0

b) otherwise the checkdigit is 11 minus the result.

=item 4

The first checkdigit is appended to the number and step 1 to 3 are
repeated.

=back

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if C<$number> consists solely of numbers and the last digit
is a valid check digit according to the algorithm given above.

Returns false otherwise,

=item complete($number)

The check digit for C<$number> is computed and concatenated to the end
of C<$number>.

Returns the complete number with check digit or '' if C<$number>
does not consist solely of digits and spaces.

=item basenumber($number)

Returns the basenumber of C<$number> if C<$number> has a valid check
digit.

Return '' otherwise.

=item checkdigit($number)

Returns the checkdigit of C<$number> if C<$number> has a valid check
digit.

Return '' otherwise.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Mathias Weidner, C<< <mamawe@cpan.org> >>

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<www.pruefziffernberechnung.de>.

=cut
