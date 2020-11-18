package Algorithm::CheckDigits::MXX_001;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.5';

our @ISA = qw(Algorithm::CheckDigits);

my %weight = (
	'aba_rn'  => [ 3,7,1,3,7,1,3,7,1, ],
	'mxx-001' => [ 7,3,1,7,3,1,7,3,1,7,3,1,7,3,1,7,3,1,7,3,1,7,3,1, ],
	'pa_de'   => [ 7,3,1,7,3,1,7,3,1,7,3,1,7,3,1,7,3,1,7,3,1,7,3,1, ],
);

sub new {
	my ($proto, $type) = @_;
	my $class = ref($proto) || $proto;
	my $self  = bless({}, $class);
	$self->{type}   = lc($type);
	$self->{weight} = $weight{$type};
	if ('aba_rn' eq $type) {
		$self->{complement} = 1;
	}
	return $self;
} # new()

sub is_valid {
	my ($self,$number) = @_;
	if ('aba_rn' eq $self->{type}) {
		$number =~ y/[0-9]//cd;
		if ($number =~ /^(\d{8})(\d)$/) {
			my $ccd = $self->_compute($1);
			my $pcd = $2;
			return 1 if ($ccd == $pcd);
		}
	}
	else {
		if ($number =~ /^\d{9}(\d).<+\d{6}(\d)<+\d{6}(\d)<+(\d)$/) {
			my @cd = $self->_compute_checkdigit($number);
			return 1 if (   $cd[0] == $1 and $cd[1] == $2
		            	and $cd[2] == $3 and $cd[3] == $4
			    	);
		}
		elsif ($number =~ /^(\d+)(\d)$/) {
			return 1 if $2 == $self->_compute($1);
		}
	}
	return 0;
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{9}).(.<+\d{6}).(<+\d{6}).(<+).$/) {
		my @cd = $self->_compute_checkdigit($number);
		return $1 . $cd[0] . $2 . $cd[1] . $3 . $cd[2] . $4 .  $cd[3];
	}
	elsif ($number =~ /^(\d+)$/) {
		return $number . $self->_compute($number);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{9})(\d)(.<+\d{6})(\d)(<+\d{6})(\d)(<+)(\d)$/) {
		my @cd = $self->_compute_checkdigit($number);
		return $1 . '_' . $3 . '_' . $5 . '_' . $7 . '_'
			if (   $cd[0] == $2 and $cd[1] == $4
		           and $cd[2] == $6 and $cd[3] == $8
			   );
	}
	elsif ($number =~ /^(\d+)(\d)$/) {
		return $1 if $2 == $self->_compute($1);
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^\d{9}(\d).<+\d{6}(\d)<+\d{6}(\d)<+(\d)$/) {
		my @cd = $self->_compute_checkdigit($number);
		return join('<',@cd)
			if (   $cd[0] == $1 and $cd[1] == $2
		           and $cd[2] == $3 and $cd[3] == $4
			   );
	}
	elsif ($number =~ /^(\d+)(\d)$/) {
		return $self->_compute($1);
	}
	return '';
} # checkdigit()

sub _compute {
	my ($self,$digits) = @_;
	my ($sum,$i) = (0,0);
	my @w = @{$self->{weight}};
	while ($digits =~ /(\d)/g) {
	        $sum += $1 * $w[$i++];
	}
	if ($self->{complement}) {
		return (10 - $sum % 10) % 10;
	}
	return $sum % 10;
} # _compute()

sub _compute_checkdigit {
	my ($self,$number) = @_;

	if ($number =~ /^(\d{9})..<+(\d{6}).<+(\d{6}).<+.$/) {
		my @cd;
		$cd[0] = $self->_compute($1);
		$cd[1] = $self->_compute($2);
		$cd[2] = $self->_compute($3);
		$cd[3] = $self->_compute($1 . $cd[0] . $2 . $cd[1] . $3 . $cd[2]);
		return @cd;
	}
	return ();
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::MXX_001 - compute check digits for german Personalausweis
(pa_de) or ABA routing numbers (aba_rn)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $pa = CheckDigits('pa_de');

  if ($pa->is_valid('2406055684D<<6810203<0705109<6')) {
	# do something
  }

  if ($pa->is_valid('2406055684') {
  	# do_something
  }

  $cn = $pa->complete('240605568_D<<681020_<070510_<_');
  # $cn = '2406055684D<<6810203<0705109<6'

  $cd = $pa->checkdigit('2406055684D<<6810203<0705109<6');
  # $cd = '6'

  $bn = $pa->basenumber('2406055684D<<6810203<0705109<6');
  # $bn = '240605568_D<<681020_<070510_<_'

  $aba = CheckDigits('aba_rn');
  if ($aba->is_valid('789456124')) {
       # do something
  }
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning left all digits are weighted with 7,3,1,7,3,1,... for I<pa_de>
or 3,7,1,3,7,1,3,7,1 for I<aba_rn>.

=item 2

The sum of those products is computed.

=item 3

For I<pa_de> the checksum is the last digit of the sum from step 2 (modulo 10).

For I<aba_rn> the checksum is the difference of the sum from step 2 to the
next multiple of 10.

=item 4

For the german Personalausweis step 1 to 3 is performed for every part of
the number and for all 3
parts including the particular checkdigit to compute the total
checksum.

If the number solely consists of digits, the checksum is just computed
once according to algorithm given above.

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

=head1 THANKS

Aaron W. West pointed me to a fault in the computing of the check
digit. Jim Hickstein made me aware of the ABA routing numbers.

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<www.pruefziffernberechnung.de>,
F<http://answers.google.com/answers/threadview/id/43619.html>,
F<http://www.brainjar.com/js/validation/>

=cut
