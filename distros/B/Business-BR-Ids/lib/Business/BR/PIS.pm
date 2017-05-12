
package Business::BR::PIS;

use 5;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

#our %EXPORT_TAGS = ( 'all' => [ qw() ] );
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
#our @EXPORT = qw();

our @EXPORT_OK = qw( canon_pis format_pis parse_pis random_pis );
our @EXPORT = qw( test_pis );

our $VERSION = '0.0022';

use Business::BR::Ids::Common qw(_dot _canon_id);

sub canon_pis {
  return _canon_id(shift, size => 11);
}


# there is a subtle difference here between the return for
# for an input which is not 11 digits long (undef)
# and one that does not satisfy the check equations (0).
# Correct PIS numbers return 1.
sub test_pis {
  my $pis = canon_pis shift;
  return undef if length $pis != 11;
  my @pis = split '', $pis;
  my $sum = _dot([qw(3 2 9 8 7 6 5 4 3 2 1)], \@pis) % 11;
  return ($sum==0 || $sum==1 && $pis[10]==0) ? 1 : 0;
}

sub format_pis {
  my $pis = canon_pis shift;
  $pis =~ s/^(...)(.....)(..)(.).*/$1.$2.$3-$4/; # 999.99999.99-9
  return $pis;
}

sub parse_pis {
  my $pis = canon_pis shift;
  my ($base, $dv) = $pis =~ /(\d{10})(\d{1})/;
  if (wantarray) {
    return ($base, $dv);
  }
  return { base => $base, dv => $dv };
}

# my $dv = _dv_pis('121.51144.13-7') # => $dv1 = 
# my $dv = _dv_pis('121.51144.13-7', 0) # computes non-valid check digit
#
# computes the check digit of the candidate PIS number given as argument
# (only the first 10 digits enter the computation)
#
# In list context, it returns the check digit.
# In scalar context, it returns the complete PIS (base and check digits)
sub _dv_pis {
	my $base = shift; # expected to be canon'ed already ?!
	my $valid = @_ ? shift : 1;
	my $dev = $valid ? 0 : 2; # deviation (to make PIS invalid)
	my @base = split '', substr($base, 0, 10);
	my $dv = (-_dot([qw(3 2 9 8 7 6 5 4 3 2)], \@base) + $dev) % 11 % 10;
	return ($dv) if wantarray;
	substr($base, 10, 1) = $dv;
	return $base;
}

# generates a random (correct or incorrect) PIS
# $pis = rand_pis();
# $pis = rand_pis($valid);
#
# if $valid==0, produces an invalid PIS. 
sub random_pis {
	my $valid = @_ ? shift : 1; # valid PIS by default
	my $base = sprintf "%010s?", int(rand(1E10)); # 10 dígitos
	return scalar _dv_pis($base, $valid);
}

1;

__END__

=head1 NAME

Business::BR::PIS - Perl module to test for correct PIS numbers

=head1 SYNOPSIS

  use Business::BR::PIS; 

  print "ok " if test_pis('121.51144.13-7'); # prints 'ok '
  print "bad " unless test_pis('121.51144.13-0'); # prints 'bad '

=head1 DESCRIPTION

This module handles PIS numbers, testing, formatting, etc.

=head2 EXPORT

C<test_pis> is exported by default. C<canon_pis>, C<format_pis>,
C<parse_pis> and C<random_pis> can be exported on demand.


=head1 THE CHECK EQUATIONS

A correct PIS number has a check digit which is computed
from the base 10 first digits. Consider the PIS number 
written as 11 digits

  c[1] c[2] c[3] c[4] c[5] c[6] c[7] c[8] c[9] c[10] dv[1]

To check whether a PIS is correct or not, it has to satisfy 
the check equation:

  c[1]*3+c[2]*2+c[3]*9+c[4]*8+c[5]*7+
          c[6]*6+c[7]*5+c[8]*4+c[9]*3+c[10]*2+dv[1] = 0 (mod 11) or
                                                   = 1 (mod 11) (if dv[1]=0)

=head1 BUGS

Absolute lack of documentation by now.

=head1 SEE ALSO

Please reports bugs via CPAN RT, 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-BR-Ids
By doing so, the author will receive your reports and patches, 
as well as the problem and solutions will be documented.

=head1 AUTHOR

A. R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by A. R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
