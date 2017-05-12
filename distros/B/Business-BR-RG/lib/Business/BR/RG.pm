use strict;
use warnings;

package Business::BR::RG;

use 5.004;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = 0.001;

#our %EXPORT_TAGS = ( 'all' => [ qw() ] );
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
#our @EXPORT = qw();

our @EXPORT_OK = qw( canon_rg format_rg parse_rg random_rg );
our @EXPORT    = qw( test_rg );

# tambem tive que copiar o _dot do Business::BR::Ids::Common pois o valor de X é 10
sub _dot {
    my $a = shift;
    my $b = shift;
    warn "arguments a and b should have the same length"
      unless ( @$a == @$b );
    my $s = 0;
    my $c = @$a;
    for my $i ( 0 .. $c ) {
        my ( $x, $y ) = ( $a->[$i], $b->[$i] );
        if ( $x && $y ) {
            $y = 10 if ( $y eq 'X' );

            $s += $x * $y;
        }
    }
    return $s;
}

# o RG tem pode ter o digito X que representa o numero 10, portanto, nao pude usar o
# _canon_id do Business::BR::Ids::Common
# the RG may have an X, thats represents 10, because of this, I use self functions for _dot and for clean
sub canon_rg {
    my $rg = uc shift();

    if ($rg) {

        $rg =~ s/[^X\d]//go;

        if ( length($rg) == 9 ) {
            return $rg;
        }
        else {
            return sprintf( '%0*s', 9, $rg );
        }

    }
    return undef;
}

# there is a subtle difference here between the return for
# for an input which is not 9 digits long (undef)
# and one that does not satisfy the check equations (0).
# Correct RG numbers return 1.
sub test_rg {
    my $rg = canon_rg shift;
    return undef if length $rg != 9;

    my @rg = split '', $rg;

    my $mod = _dot( [ 2, 3, 4, 5, 6, 7, 8, 9, 100 ], \@rg ) % 11;

    return $mod == 0 ? 1 : 0;
}

sub format_rg {
    my $rg = canon_rg shift;
    $rg =~ s/^(..)(...)(...)(.)/$1.$2.$3-$4/;
    return $rg;
}

sub parse_rg {
    my $rg = canon_rg shift;
    my ( $base, $dv ) = $rg =~ /(\d{8})(\d|X)/;
    if (wantarray) {
        return ( $base, $dv );
    }
    return { base => $base, dv => $dv };
}

# computes the check digits of the candidate RG number given as argument
# (only the first 8 digits enter the computation)
#
# In list context, it returns the check digit.
# In scalar context, it returns the complete RG (base and check digit)
sub _dv_rg {
    my $base  = shift;             # expected to be canon'ed already ?!
    my $valid = @_ ? shift : 1;
    my $dev   = $valid ? 0 : 2;    # deviation (to make RG invalid)

    my @base = split '', substr( $base, 0, 8 );

    my $dv = ( -_dot( [ 2, 3, 4, 5, 6, 7, 8, 9 ], \@base ) + $dev ) % 11 % 10;

    if ( $dv == 0 && $valid && test_rg( $base . $dv ) == 0 ) {
        $dv = 'X';
    }

    return ($dv) if wantarray;

    if ( length($base) == 9 ) {
        substr( $base, 9, 1 ) = $dv;
    }
    else {
        $base .= $dv;
    }

    return $base;
}

# generates a random (correct or incorrect) RG
# $rg = rand_rg();
# $rg = rand_rg($valid);
#
# if $valid==0, produces an invalid .  RG
sub random_rg {
    my $valid = @_ ? shift : 1;    # valid RG by default

    my $base = sprintf '%08s', int( rand(1E8) );    # 8 dígitos

    return scalar _dv_rg( $base, $valid );
}

1;

__END__

=pod

=head1 NAME

Business::BR::RG

=head1 VERSION

version 0.0021

=head1 DESCRIPTION

The RG number is an identification number of Brazilian citizens
emitted by the Department of Public Safety, which is called
"Secretaria de Segurança Pública (SSP)".

RG stands for "Registro Geral", and it is valid for all brazil territory.
May be use as passport to Argentina, Paraguay, Uruguay and Chile.

The RG is comprised of a base of 8 digits and one check digit.

It is usually written like '12.002.999-0' so as to be
more human-readable.

This module provides C<test_rg> for checking that a RG number
is I<correct>. Here a I<correct RG number> means

=over 4

=item *

it is 9 digits long

=item *

it satisfies the check equation mentioned below

=back

Before checking, any non-digit letter is stripped, making it
easy to test formatted entries like '21.002.999-00' and
entries with extra blanks like '   99.221.222-00  '.
Except the letter X, because it's represents the number 10.

=over 4

=item B<test_rg>

	test_rg('39.985.676-X') # incorrect RG, returns 0
	test_rg(' 39.985.676-6 ') # is ok, returns 1
	test_rg('123') # nope, returns undef

Tests whether a RG number is correct. Before testing,
any non-digit [except X, no matter its case] character is stripped.
Then it is
expected to be 9 digits long and to satisfy
check equation which validate the check digit.
See L</"THE CHECK EQUATIONS">.

The policy to get rid of '.' and '-' is very liberal.
It indeeds discards anything that is not a digit (0, 1, ..., 9, or X)
or letter. That is handy for discarding spaces as well

	test_rg(' 39.985.676-6 ') # is ok, returns 1

But extraneous inputs like '3.9.9 8w5.6w7h6?6' are
also accepted. If you are worried about this kind of input,
just check against a regex:

	warn "bad RG: only digits (9) expected"
		unless ($rg =~ /^\d{8}(\d|x)$/i);

	warn "bad RG: does not match mask '__.___.___-_'"
		unless ($rg =~ /^\d{2}\.\d{3}\.\d{3}-(\d|x)$/i);

NOTE. Integer numbers like 1234567
with fewer than 8 digits will be normalized (eg. to "001234567") before testing.

=item B<canon_rg>

	canon_rg(99); # returns '000000099'
	canon_rg('99.999.999-9'); # returns '999999999'

Brings a candidate for a RG number to a canonical form.
In case,
the argument is an integer, it is formatted to at least
9 digits. Otherwise, it is stripped of any
non-alphanumeric [again, except x] characters and returned as it is.

=item B<format_rg>

	format_rg('00000000'); # returns '00.000.000-0'

Formats its input into '00.000.000-0' mask.
First, the argument is canon'ed and then
dots and hyphen are added to the first
9 digits of the result.
So you can call format_rg even when its already formated.

=item B<parse_rg>

	($base, $dv) = parse_rg($rg);
	$hashref = parse_rg('99.222.111-0'); # { base => '99222111', dv => '0' }

Splits a candidate for RG number into base and check
digits (dv - dígitos de verificação). It canon's
the argument before splitting it into 8- and 1-digit
parts. In a list context,
returns a two-element list with the base and the check
digits. In a scalar context, returns a hash ref
with keys 'base' and 'dv' and associated values.

=item B<random_rg>

	$rand_rg = random_rg($valid);

	$correct_rg = random_rg();
	$rg = random_rg(1); # also a correct RG
	$bad_rg = random_rg(0); # an incorrect RG

Generates a random RG. If $valid is omitted or 1, it is guaranteed
to be I<correct>. If $valid is 0, it is guaranteed to be I<incorrect>.
This function is intented for mass test. (Use it wisely.)

The implementation is simple: just generate a 8-digits random number,
hopefully with a uniform distribution and then compute the check digits.
If $valid==0, the check digits are computed B<not to> satisfy the
check equations.

=back

=head2 EXPORT

C<test_rg> is exported by default. C<canon_rg>, C<format_rg>,
C<parse_rg> and C<random_rg> can be exported on demand.

=head1 NAME

Business::BR::RG - Perl module to test for correct RG numbers

ABSTRACT:

	use Business::BR::RG;

	print "ok " if test_rg('390.533.447-05'); # prints 'ok '
	print "bad " unless test_rg('231.002.999-00'); # prints 'bad '

using all methods

	use Business::BR::RG qw /canon_rg test_rg random_rg format_rg parse_rg/;

	test_rg('48.391.390-x') # 1
	canon_rg('11.456.789-x') # '11456789X'

	test_rg('48.190.390-X') # 0

	test_rg('48.190') # undef

	format_rg('48.19.0.3.9.0.X') # '48.190.390-X'

	my ($base, $dv) = parse_rg('48.19.0.3.9.0.X');
	print $base # '48190390'
	print $dv   # 'X'

	my $hashref = parse_rg('48.19.0.3.9.0.X');
	print $hashref->{base} . '-' . $hashref->{dv}; # 48190390-X

=head1 THE CHECK EQUATIONS

A correct RG number has one check digit which are computed
from the base 8 first digits. Consider the RG number
written as 9 digits

c[1] c[2] c[3] c[4] c[5] c[6] c[7] c[8] dv[1]

To check whether a RG is correct or not, it has to satisfy
the check equations:

c[1]*2 + c[2]*3 + c[3]*4 + c[4]*5 + c[5]*6 + c[6]*7 + c[7]*8 + c[8]*9 +
dv[9] * 100 = 0 (mod 11)

=head1 BUGS

until now I do not found any RG that has less than 8 digits.
But, I guess, old people still have it.
For now, this is the only way that I found to check RG.
If you found any bug, feel free to send e-mail, open an issue on github or open a RT.

=head1 SEE ALSO

Note that this module only tests correctness.
It doesn't enter the merit whether the RG number actually exists
at the Brazilian government databases.

Please reports bugs via CPAN RT or github.

L<http://github.com/renatocron/>

You may be interested too in validation of CPF/CNPJ. So you can look at:

L<Business::BR::CNPJ>

L<Business::BR::CPF>

You should too make a search about the L<Business::BR> namespace.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command (to read this)

	perldoc Business\:\:BR\:\:RG

=head2 Github

If you want to contribute with the code, you can fork this module on github:

L<https://github.com/renatocron/Business--BR--RG>

You can even report a issue.

=head1 AUTHOR

Renato CRON, E<lt>rentocron@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Renato CRON

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

=head1 AUTHOR

Renato CRON <rentocron@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Renato CRON.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
