package Crypt::CVS;
BEGIN {
  $Crypt::CVS::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $Crypt::CVS::VERSION = '0.03';
}

use strict;
use warnings;
use base 'Exporter';

our @EXPORT    = ();
our @EXPORT_OK = qw(scramble descramble);
our %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = \@EXPORT_OK;

# This table is from src/scramble.c in the CVS source
our @SHIFTS = (
    0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
    114,120, 53, 79, 96,109, 72,108, 70, 64, 76, 67,116, 74, 68, 87,
    111, 52, 75,119, 49, 34, 82, 81, 95, 65,112, 86,118,110,122,105,
    41, 57, 83, 43, 46,102, 40, 89, 38,103, 45, 50, 42,123, 91, 35,
    125, 55, 54, 66,124,126, 59, 47, 92, 71,115, 78, 88,107,106, 56,
    36,121,117,104,101,100, 69, 73, 99, 63, 94, 93, 39, 37, 61, 48,
    58,113, 32, 90, 44, 98, 60, 51, 33, 97, 62, 77, 84, 80, 85,223,
    225,216,187,166,229,189,222,188,141,249,148,200,184,136,248,190,
    199,170,181,204,138,232,218,183,255,234,220,247,213,203,226,193,
    174,172,228,252,217,201,131,230,197,211,145,238,161,179,160,212,
    207,221,254,173,202,146,224,151,140,196,205,130,135,133,143,246,
    192,159,244,239,185,168,215,144,139,165,180,157,147,186,214,176,
    227,231,219,169,175,156,206,198,129,164,150,210,154,177,134,127,
    182,128,158,208,162,132,167,209,149,241,153,251,237,236,171,195,
    243,233,253,240,194,250,191,155,142,137,245,235,163,242,178,152
);

sub scramble
{
    my ($str) = @_;
    my @str = unpack "C*", $str;
    my $ret = join '', map { chr $SHIFTS[$_] } @str;
    return "A$ret";
}

sub descramble
{
    my ($str) = @_;

    # This should never happen, the same password format (A) has been
    # used by CVS since the beginning of time
    {
        my $fmt = substr($str, 0, 1);
        die "invalid password format `$fmt'" unless $fmt eq 'A';
    }

    my @str = unpack "C*", substr($str, 1);
    my $ret = join '', map { chr $SHIFTS[$_] } @str;
    return $ret;
}

1;

__END__

=head1 NAME

Crypt::CVS - Substitution cipher for CVS passwords

=head1 SYNOPSIS

    use Crypt::CVS qw(:all);

    # AE00uy
    my $scrambled = scramble "foobar";
    # foobar
    my $descrambled = descramble $scrambled;

=head1 DESCRIPTION

The CVS protocol uses a substitution cipher for passwords going over
the wire. From F<src/scramble.c> in GNU CVS's source distribution:

    Trivially encode strings to protect them from innocent eyes (i.e.,
    inadvertent password compromises, like a network administrator
    who's watching packets for legitimate reasons and accidentally sees
    the password protocol go by.

About the encoding:

    Map characters to each other randomly and symmetrically, A <--> B.

    We divide the ASCII character set into 3 domains: control chars (0
    thru 31), printing chars (32 through 126), and "meta"-chars (127
    through 255).  The control chars map _to_ themselves, the printing
    chars map _among_ themselves, and the meta chars map _among_
    themselves.  Why is this thus?

    No character in any of these domains maps to a character in another
    domain, because I'm not sure what characters are valid in
    passwords, or what tools people are likely to use to cut and paste
    them.  It seems prudent not to introduce control or meta chars,
    unless the user introduced them first.  And having the control
    chars all map to themselves insures that newline and
    carriage-return are safely handled.

=head1 FUNCTIONS

=head1 scramble($plaintext)

Takes plaintext and returns a scrambled version of it. The first byte
of the scrambled string is a single letter indicating the scrambling
method. This has always been C<"A">, it's very unlikely that there'll
ever be another scrambling method.

=head1 unscramble($scrambled)

Takes a scrambled string and returns an unscrambled version. Dies if
the first letter isn't C<"A">.

=head1 EXPORTS

The functions L</scramble> and L</descramble> can be optionally
exported. C<use Crypt::CVS ':all'> exports both of them.

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE

Copyright 2007-2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
