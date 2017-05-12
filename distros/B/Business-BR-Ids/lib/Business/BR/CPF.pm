
package Business::BR::CPF;

use 5;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

#our %EXPORT_TAGS = ( 'all' => [ qw() ] );
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
#our @EXPORT = qw();

our @EXPORT_OK = qw( canon_cpf format_cpf parse_cpf random_cpf );
our @EXPORT = qw( test_cpf );

our $VERSION = '0.0022';

#use Scalar::Util qw(looks_like_number); 

use Business::BR::Ids::Common qw(_dot _canon_id);

sub canon_cpf {
  return _canon_id(shift, size => 11);
}   


# there is a subtle difference here between the return for
# for an input which is not 11 digits long (undef)
# and one that does not satisfy the check equations (0).
# Correct CPF numbers return 1.
sub test_cpf {
  my $cpf = canon_cpf shift;
  return undef if length $cpf != 11;
  my @cpf = split '', $cpf;
  my $s1 = _dot([10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0], \@cpf) % 11;
  my $s2 = _dot([0, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1], \@cpf) % 11;
  unless ($s1==0 || $s1==1 && $cpf[9]==0) {
    return 0;
  }
  return ($s2==0 || $s2==1 && $cpf[10]==0) ? 1 : 0;
}


sub format_cpf {
  my $cpf = canon_cpf shift;
  $cpf =~ s/^(...)(...)(...)(..).*/$1.$2.$3-$4/;
  return $cpf;
}

sub parse_cpf {
  my $cpf = canon_cpf shift;
  my ($base, $dv) = $cpf =~ /(\d{9})(\d{2})/;
  if (wantarray) {
    return ($base, $dv);
  }
  return { base => $base, dv => $dv };
}

# my ($dv1, $dv2) = _dv_cpf('390.533.447-05') # => $dv1 = 0, $dv2 = 5
# my ($dv1, $dv2) = _dv_cpf('390.533.447-05', 0) # computes non-valid check digits
#
# computes the check digits of the candidate CPF number given as argument
# (only the first 9 digits enter the computation)
#
# In list context, it returns the check digits.
# In scalar context, it returns the complete CPF (base and check digits)
sub _dv_cpf {
	my $base = shift; # expected to be canon'ed already ?!
	my $valid = @_ ? shift : 1;
	my $dev = $valid ? 0 : 2; # deviation (to make CPF invalid)
	my @base = split '', substr($base, 0, 9);
	my $dv1 = -_dot([10, 9, 8, 7, 6, 5, 4, 3, 2], \@base) % 11 % 10;
	my $dv2 = (-_dot([0, 10, 9, 8, 7, 6, 5, 4, 3, 2], [ @base, $dv1 ]) + $dev) % 11 % 10;
	return ($dv1, $dv2) if wantarray;
	substr($base, 9, 2) = "$dv1$dv2";
	return $base;
}

# generates a random (correct or incorrect) CPF
# $cpf = rand_cpf();
# $cpf = rand_cpf($valid);
#
# if $valid==0, produces an invalid CPF. 
sub random_cpf {
	my $valid = @_ ? shift : 1; # valid CPF by default
	my $base = sprintf "%09s", int(rand(1E9)); # 9 dígitos
	return scalar _dv_cpf($base, $valid);
}

1;

__END__

=head1 NAME

Business::BR::CPF - Perl module to test for correct CPF numbers

=head1 SYNOPSIS

  use Business::BR::CPF; 

  print "ok " if test_cpf('390.533.447-05'); # prints 'ok '
  print "bad " unless test_cpf('231.002.999-00'); # prints 'bad '

=head1 DESCRIPTION

The CPF number is an identification number of Brazilian citizens
emitted by the Brazilian Ministry of Revenue, which is called
"Ministério da Fazenda".

CPF stands for "Cadastro de Pessoa Física" (literally,
physical person registration) as opposed to the CNPJ number 
for companies. 

The CPF is comprised of a base of 9 digits and 2 check digits.
It is usually written like '231.002.999-00' so as to be 
more human-readable.

This module provides C<test_cpf> for checking that a CPF number
is I<correct>. Here a I<correct CPF number> means

=over 4

=item *

it is 11 digits long

=item *

it satisfies the two check equations mentioned below

=back

Before checking, any non-digit letter is stripped, making it
easy to test formatted entries like '231.002.999-00' and
entries with extra blanks like '   999.221.222-00  '.

=over 4

=item B<test_cpf>

  test_cpf('999.444.333-55') # incorrect CPF, returns 0
  test_cpf(' 263.946.533-30 ') # is ok, returns 1
  test_cpf('888') # nope, returns undef

Tests whether a CPF number is correct. Before testing,
any non-digit character is stripped. Then it is
expected to be 11 digits long and to satisfy two
check equations which validate the last two check digits.
See L</"THE CHECK EQUATIONS">.

The policy to get rid of '.' and '-' is very liberal. 
It indeeds discards anything that is not a digit (0, 1, ..., 9)
or letter. That is handy for discarding spaces as well 

  test_cpf(' 263.946.533-30 ') # is ok, returns 1

But extraneous inputs like '#333%444*2.3+2-00' are
also accepted. If you are worried about this kind of input,
just check against a regex:

  warn "bad CPF: only digits (11) expected" 
    unless ($cpf =~ /^\d{11}$/);

  warn "bad CPF: does not match mask '___.___.___-__'" 
    unless ($cpf =~ /^\d{3}\.\d{3}\.\d{3}-\d{2}$/);

NOTE. Integer numbers like 9999811299 (or 99_998_112_99) 
with fewer than 11 digits will be normalized (eg. to
"09999811299") before testing.

=item B<canon_cpf>

  canon_cpf(99); # returns '00000000099'
  canon_cpf('999.999.999-99'); # returns '99999999999'

Brings a candidate for a CPF number to a canonical form. 
In case,
the argument is an integer, it is formatted to at least
eleven digits. Otherwise, it is stripped of any 
non-alphanumeric characters and returned as it is.

=item B<format_cpf>

  format_cpf('00000000000'); # returns '000.000.000-00'

Formats its input into '000.000.000-00' mask.
First, the argument is canon'ed and then
dots and hyphen are added to the first
11 digits of the result.

=item B<parse_cpf>

  ($base, $dv) = parse_cpf($cpf);
  $hashref = parse_cpf('999.222.111-00'); # { base => '999222111', dv => '00' }

Splits a candidate for CPF number into base and check
digits (dv - dígitos de verificação). It canon's
the argument before splitting it into 9- and 2-digits
parts. In a list context,
returns a two-element list with the base and the check
digits. In a scalar context, returns a hash ref
with keys 'base' and 'dv' and associated values.

=item B<random_cpf>

  $rand_cpf = random_cpf($valid);

  $correct_cpf = random_cpf();
  $cpf = random_cpf(1); # also a correct CPF
  $bad_cpf = random_cpf(0); # an incorrect CPF

Generates a random CPF. If $valid is omitted or 1, it is guaranteed
to be I<correct>. If $valid is 0, it is guaranteed to be I<incorrect>.
This function is intented for mass test. (Use it wisely.)

The implementation is simple: just generate a 9-digits random number,
hopefully with a uniform distribution and then compute the check digits.
If $valid==0, the check digits are computed B<not to> satisfy the
check equations.

=back

=head2 EXPORT

C<test_cpf> is exported by default. C<canon_cpf>, C<format_cpf>,
C<parse_cpf> and C<random_cpf> can be exported on demand.


=head1 THE CHECK EQUATIONS

A correct CPF number has two check digits which are computed
from the base 9 first digits. Consider the CPF number 
written as 11 digits

  c[1] c[2] c[3] c[4] c[5] c[6] c[7] c[8] c[9] dv[1] dv[2]

To check whether a CPF is correct or not, it has to satisfy 
the check equations:

  c[1]*10+c[2]*9+c[3]*8+c[4]*7+c[5]*6+
          c[6]*5+c[7]*4+c[8]*3+c[9]*2+dv[1] = 0 (mod 11) or
                                            = 1 (mod 11) (if dv[1]=0)

and 

  c[2]*10+c[3]*9+c[4]*8+c[5]*7+c[6]*6+
          c[7]*5+c[8]*4+c[9]*3+dv[1]*2+dv[2] = 0 (mod 11) or
                                             = 1 (mod 11) (if dv[2]=0)


=head1 BUGS

I heard that there are exceptions of CPF numbers which don't
obey the check equations and are still authentic. I have never found
one of them. 

=head1 SEE ALSO

To make sure this module works, one can try the results obtained against 
those found with  "Comprovante de Inscrição e de Situação Cadastral no CPF", 
a web page which the Brazilian Ministry of Revenue provides for public 
consultation on regularity status of the taxpayer.
This page tells if the CPF number is a correct entry (11-digits-long with verified
check digits), if it references a real person and if he/she is regular
with the government body. 

Given a bad CPF, the after-submit page tells "CPF incorreto".
If the CPF is a good one but does not reference a real person,
it says "CPF não existe em nossa base de dados" (CPF does not exist
in our database). Otherwise, it shows a details form for the identified
taxpayer.

Note that this module only tests correctness.
It doesn't enter the merit whether the CPF number actually exists
at the Brazilian government databases. 

As you might have guessed, this is not the first Perl module
to approach this kind of functionality. Take a look at

  http://search.cpan.org/search?module=Brasil::Checar::CPF
  http://search.cpan.org/search?query=cpf&mode=all

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
