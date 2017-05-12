package Crypt::Juniper;

use warnings;
use strict;
use Carp;

use base 'Exporter';
our @EXPORT = qw( juniper_encrypt juniper_decrypt );

=head1 NAME

Crypt::Juniper - Encrypt/decrypt Juniper $9$ secrets

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Crypt::Juniper;
    my $secret = juniper_decrypt('$9$LbHX-wg4Z');  ## $secret="lc";
    my $crypt = juniper_encrypt('lc');             ## encrypt it

=cut

#################################################################
## globals

my $MAGIC = q{$9$};

###################################
## letter families

my @FAMILY = qw[ QzF3n6/9CAtpu0O B1IREhcSyrleKvMW8LXx 7N-dVbwsY2g4oaJZGUDj iHkq.mPf5T ];
my %EXTRA;

for my $fam (0..$#FAMILY)
{
    for my $c (split //, $FAMILY[$fam])
    {
        $EXTRA{$c} = (3-$fam);
    }
}

my $VALID = do {
    my $letters = join '', @FAMILY;
    my $end = "[$letters]{4,}\$";
    $end =~ s/-/\\-/;
    qr/^\Q$MAGIC\E$end/;
};

###################################
## forward and reverse dictionaries

my @NUM_ALPHA = split //, join '', @FAMILY;
my %ALPHA_NUM = map { $NUM_ALPHA[$_] => $_ } 0..$#NUM_ALPHA;

###################################
## encoding moduli by position

my @ENCODING = (
    [ 1,  4, 32 ],
    [ 1, 16, 32 ],
    [ 1,  8, 32 ],
    [ 1, 64     ],
    [ 1, 32     ],
    [ 1, 4, 16, 128 ],
    [ 1, 32, 64 ],
);

#################################################################

=head1 EXPORTED FUNCTIONS

=head2 juniper_decrypt($crypt)

Decrypt the string C<$crypt>, returning the corresponding plain-text.
Input string must be of the format "$9$blahblah".  This function will
die() if there any processing errors.

=cut

sub juniper_decrypt {
    my ($crypt) = @_;

    croak "Invalid Juniper crypt string!"
        unless (defined $crypt and $crypt =~ $VALID);

    my ($chars) = $crypt =~ /^\Q$MAGIC\E(\S+)/;

    my $first = _nibble(\$chars, 1);
    _nibble(\$chars, $EXTRA{$first});

    my $prev = $first;
    my $decrypt = '';

    while ($chars)
    {
        my $decode = $ENCODING[ length($decrypt) % @ENCODING ];
        my $len = @$decode;

        my @nibble = split //, _nibble(\$chars, $len);
        my @gaps = map { my $g = _gap($prev, $_); $prev = $_ ; $g } @nibble;

        $decrypt .= _gap_decode(\@gaps, $decode);
    }

    return $decrypt;
}

sub _nibble {
    my ($cref, $len) = @_;
    my $nib = substr($$cref, 0, $len, '');
    length($nib) == $len
        or croak "Ran out of characters: hit '$nib', expecting $len chars";
    return $nib;
}

###################################
## calculate the distance between two characters
sub _gap {
    my ($c1, $c2) = @_;

    return ($ALPHA_NUM{$c2} - $ALPHA_NUM{$c1}) % @NUM_ALPHA - 1;
};

###################################
## given a series of gaps and moduli, calculate the resulting plaintext
sub _gap_decode {
    my ($gaps, $dec) = @_;
    my $num = 0;
    @$gaps == @$dec or die "Nibble and decode size not the same!";
    for (0..$#$gaps)
    {
        $num += $gaps->[$_] * $dec->[$_];
    }
    chr( $num % 256 );
}

=head2 juniper_encrypt($secret)

Encrypt the plain text C<$secret>, returning a result suitable for
inclusion in a Juniper configuration.

=cut

sub juniper_encrypt {
    my ($plain, $salt) = @_;

    defined $salt or $salt = _randc(1);
    my $rand = _randc($EXTRA{$salt});

    my $pos = 0;
    my $prev = $salt;
    my $crypt = "$MAGIC$salt$rand";

    for my $p (split //, $plain)
    {
        my $encode = $ENCODING[ $pos % @ENCODING ];
        $crypt .= _gap_encode($p, $prev, $encode);
        $prev = substr($crypt, -1);
        $pos++;
    }

    return $crypt;
}

## return a random number of characters from our alphabet
sub _randc {
    my $cnt = shift || 0;
    my $r = '';

    $r .= $NUM_ALPHA[ int rand $#NUM_ALPHA ]
        while ($cnt-- > 0);

    $r;
}

## encode a plain-text character with a series of gaps,
## according to the current encoder.
sub _gap_encode {
    my ($pc, $prev, $enc) = @_;
    my $ord = ord($pc);

    my $crypt = '';
    my @gaps;

    for my $mod (reverse @$enc)
    {
        unshift @gaps, int($ord/$mod);
        $ord %= $mod;
    }

    for my $gap (@gaps)
    {
        $gap += $ALPHA_NUM{$prev} + 1;
        my $c = $prev = $NUM_ALPHA[ $gap % @NUM_ALPHA ];
        $crypt .= $c;
    }

    return $crypt;
}

=head1 AUTHOR

kevin brintnall, C<< <kbrint at rufus.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 kevin brintnall, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Crypt::Juniper
