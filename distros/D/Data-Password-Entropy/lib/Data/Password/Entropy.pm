package Data::Password::Entropy;
# coding: UTF-8

use utf8;
use strict;
use warnings;

use Encode;
use POSIX qw(floor);

our $VERSION = '0.08';

# ==============================================================================

use Exporter;
use base qw(Exporter);
our @EXPORT = qw(
    password_entropy
);
# ==============================================================================
use constant {
    CONTROL         => 0,
    NUMBER          => 1,
    UPPER           => 2,
    LOWER           => 3,
    PUNCT_1         => 4,
    PUNCT_2         => 5,
    EXTENDED        => 6,
};

my @CHAR_CLASSES;
my %CHAR_CAPACITY;

BEGIN
{
    for my $i (0..255) {
        my $cclass = 0;

        if ($i < 32) {
            $cclass = CONTROL;
        }
        elsif ($i >= ord('0') && $i <= ord('9')) {
            $cclass = NUMBER;
        }
        elsif ($i >= ord('A') && $i <= ord('Z')) {
            $cclass = UPPER;
        }
        elsif ($i >= ord('a') && $i <= ord('z')) {
            $cclass = LOWER;
        }
        elsif ($i > 127) {
            $cclass = EXTENDED;
        }
        elsif (
            # Simple punctuation marks, which can be typed with first row of keyboard or numpad
            $i == 32 ||          # space
            $i == ord('!') ||    # 33
            $i == ord('@') ||    # 64
            $i == ord('#') ||    # 35
            $i == ord('$') ||    # 36
            $i == ord('%') ||    # 37
            $i == ord('^') ||    # 94
            $i == ord('&') ||    # 38
            $i == ord('*') ||    # 42
            $i == ord('(') ||    # 40
            $i == ord(')') ||    # 41
            $i == ord('_') ||    # 95
            $i == ord('+') ||    # 43
            $i == ord('-') ||    # 45
            $i == ord('=') ||    # 61
            $i == ord('/')       # 47
        ) {
            $cclass = PUNCT_1;
        }
        else {
            # Other punctuation marks
            $cclass = PUNCT_2;
        }

        $CHAR_CLASSES[$i] = $cclass;
        if (!$CHAR_CAPACITY{$cclass}) {
            $CHAR_CAPACITY{$cclass} = 1;
        }
        else {
            $CHAR_CAPACITY{$cclass}++;
        }
    }
}
# ==============================================================================
sub password_entropy($)
{
    my ($passw) = @_;

    my $entropy = 0;

    if (defined($passw) && $passw ne '') {

        # Convert to octets
        $passw = Encode::encode_utf8($passw);

        my $classes = +{};

        my $eff_len = 0.0;      # the effective length
        my $char_count = +{};   # to count characters quantities
        my $distances = +{};    # to collect differences between adjacent characters

        my $len = length($passw);

        my $prev_nc = 0;

        for (my $i = 0; $i < $len; $i++) {
            my $c = substr($passw, $i, 1);
            my $nc = ord($c);
            $classes->{$CHAR_CLASSES[$nc]} = 1;

            my $incr = 1.0;     # value/factor for increment effective length

            if ($i > 0) {
                my $d = $nc - $prev_nc;

                if (exists($distances->{$d})) {
                    $distances->{$d}++;
                    $incr /= $distances->{$d};
                }
                else {
                    $distances->{$d} = 1;
                }
            }

            if (exists($char_count->{$c})) {
                $char_count->{$c}++;
                $eff_len += $incr * (1.0 / $char_count->{$c});
            }
            else {
                $char_count->{$c} = 1;
                $eff_len += $incr;
            }

            $prev_nc = $nc;
        }

        my $pci = 0;            # Password complexity index
        for (keys(%$classes)) {
            $pci += $CHAR_CAPACITY{$_};
        }

        if ($pci != 0) {
            my $bits_per_char = log($pci) / log(2.0);
            $entropy = floor($bits_per_char * $eff_len);
        }
    }

    return $entropy;
}
# ==============================================================================
1;
__END__

=head1 NAME

Data::Password::Entropy - Calculate password strength

=head1 SYNOPSIS

    use Data::Password::Entropy;

    print "Entropy is ", password_entropy("pass123"), " bits.";   # prints 31

    if (password_entropy("mypass") < password_entropy("Ha20&09_X!t")) {
        print "mypass is weaker. It is unexpectedly, isn't it?";
    }


=head1 DESCRIPTION

Information entropy, also known as I<password quality> or I<password strength>
when used in a discussion of the information security, is a measure of
a password in resisting brute-force attacks.

There are a lot of different ways to determine a password's entropy. We use
a simple, empirical algorithm: first, all characters from the string splitted to
several classes, such as numbers, lower- or upper-case letters and so on.
Any characters from one class have equal probability of being in the password.
Mix of the characters from the different classes extends the number of possible
symbols (symbols base) in the password and thereby increases its entropy. Then,
we calculate the I<effective length> of the password to ensure the next rules:

=over

=item * some orderliness decreases total entropy,
so C<'1234'> is weaker password than C<'1342'>,

=item * repeating sequences decrease total entropy,
so C<'a' x 100> insignificantly stronger than C<'a' x 4> (it may seem, that's too insignificantly).

=back

Do not expect too much: an algorithm does not check the password's weakness with
dictionary lookup (see L<Data::Password>). Also it can not detect obfuscation
like C<'p@ssw0rd'>, sequences from a keyboard row or personally related information.

Probability of characters occurring depends on the capacity of character class only.
Perhaps, it should be taken into account a prevalence of symbol class actually E<mdash>
it is very unlikely to find a control character in the password. But common password
policies don't allow control characters, spaces or extended characters in passwords,
therefore, so they should not occur in practice.

Similarly, there is no well-defined approach to process national characters.
For example, the Greek letters block in Unicode Character Database contains
about 400 symbols, but not all of them have equivalent frequency of usage.
An intruder, who knows that password may contain Greek letters, will not probe
the E<0x03b1> (Greek letter Alpha) with the same probability as
the E<0x1f06> (Greek small letter Alpha with psili and perispomeni), therefore
it might be incorrect to consider a whole UCD block or script as a base for
calculating probabilities.

So, data are treated as a bytes string, not a wide-character string,
and all characters with codes higher than 127 form one class.

The character classes based on the ASCII encoding. If you have something else,
e.g. EBCDIC, you can try something like the L<Encode> or L<Convert::EBCDIC> modules.


=head1 FUNCTIONS

There's only one function in this package and it is exported by default.

=over

=item C<password_entropy($data)>

Returns an entropy of C<$data>, calculating in bits.

=back


=head1 SEE ALSO

L<Data::Password>, L<Data::Password::Manager>, L<Data::Password::BasicCheck>.

L<http://en.wikipedia.org/wiki/Password_strength>

"A Conceptual Framework for Assessing Password Quality" by Wanli Ma, John Campbell, Dat Tran, and Dale Kleeman [PDF]
L<http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.98.3266&rep=rep1&type=pdf>

=head1 COPYRIGHT

Copyright (c) 2010 Oleg Alistratov. All rights reserved.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Oleg Alistratov <zero@cpan.org>

=cut
