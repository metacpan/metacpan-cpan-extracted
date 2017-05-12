#!perl -w

=begin PerlDox

=head1 NAME

=cut

package Crypt::RS14_PP; #< A pure Perl implementation of RS14, aka "Spritz", encryption algorithm.
our $VERSION = '0.03';  #<

=head1 SYNOPSIS

    use Crypt::RS14_PP;

    my $key   = '16 to 64 bytes of key';
    my $rs14  = Crypt::RS14_PP->new($key);
    my $ctext = $rs14->encrypt('This is my plain text.');
    $rs14->set_key($key);
    my $ptext = $rs14->encrypt($ctext); # or decrypt as both do the same
    print "$ptext\n"; # prints 'This is my plain text.'

=head1 DESCRIPTION

RS14, aka "Spritz", is an encryption algorithm, proposed by Ron Rivist
and Jacob Schuldt, as a replacement for RC4, created by Ron Rivist.
RS14, like RC4, is a stream algorithm. It takes the basic concepts behind
RC4, enhancing and updating them for greater security.

Being pure Perl, this module is really just a testing tool. An XS or
Inline::C implementation will provide far better performance.

I<Note:> While this module's API is a superset of the Crypt:: API, the RS14
algorithm is not intended for use with Crypt::CBC or similar. By its
nature, it already operates in OFB (Output Feedback) mode.

I<Note:> Only the encrypt/decrypt capabilities of RS14 are implemented.

I<Note:> In this module, encrypt/decrypt use bitwise exclusive-or (C<^>) to
encipher/decipher the input, as this is commonly used in stream ciphers.
As a consequence, encrypt and decrypt are the same. Other operations are
possible. This not specified in the algorithm specification.

I<Note:> To encrypt "wide characters", such as Unicode, the character stream
B<must> be encoded into a byte stream before encrypting. (For Unicode, use
UTF-8 encoding.) Whatever encoding is used, security is enhanced by excluding
any byte order marks.

=cut

use warnings;
use strict;

# only load Carp if needed
sub _carp
{
    require Carp;
    Carp::carp(@_);
}
sub _croak
{
    require Carp;
    Carp::croak(@_);
}

# Tried C<use integer;> but causes bitwise ops to treat numbers as signed (see Perl documentation)

## @internal

=head2 Constants

=cut

use constant {
    N   => 256,   #< Number of elements in S-Box.
                  #  @note This implementation is byte oriented, so N == 256
                  #  @note This implementation assumes N is a power of 2. If not,
                  #  update of w will need enhancement to ensure gcd(N,w) == 1,
                  #  i.e., N and w must be relatively prime.
};

use constant {
    A   => N + 0, #< index of a (number of nibbles absorbed) in instance array
    I   => N + 1, #< index of i (an internal state index) in instance array
    J   => N + 2, #< index of j (an internal state index) in instance array
    K   => N + 3, #< index of k (an internal state index) in instance array
    W   => N + 4, #< index of w (an internal state index) in instance array
    Z   => N + 5, #< index of z (output state index) in instance array
    M   => N - 1, #< mask for modulo-N operations
};

## @endinternal

=head2 Class Methods

=cut

## Creates a RS14 object and optionally sets the cryptographic key.
sub new
{
    my ($class,
        $key    #< @param - Key (optional - used for compatability with other Crypt:: modules)
        ) = @_;
    my $self = bless [];
    $self->set_key($key) if defined $key;
    return $self;
}

=head2 Instance Methods

=cut

## Sets the cryptographic key.
sub set_key
{
    my ($S,
        $key   #< @param - Key - 16 to N/4 bytes of key
        ) = @_;
    if (defined $key)
    {
        _carp('key too short') if (length($key) < 16);
        _croak('key too long') if (length($key) > (N / 4));
        $S->_init(); # only initialize if key is going to be used
        $S->_absorb($key);
        $S->_shuffle();
    }
}

## Encrypt (or decrypt) the given data bytes. (This function is
#  identical to C<decrypt>.)
#  @note Because this is a stream cipher, C<encrypt("ab") eq encrypt("a") . encrypt("b")>.
#        To encrypt (or decrypt) 2 messages with same key, you must C<set_key($key)>
#        before each message. Also, to encrypt and decrypt with same key, you must
#        C<set_key($key)> between encrypting and decrypting (or use 2 objects).
sub encrypt
{
    my $S = $_[0];
    my @bytes = unpack('C*', $_[1]);            #< @param $string Byte string to encrypt or decrypt

    _croak('No key set') unless ($$S[A]);       # this test assumes key limited to N/4 bytes (and other assumptions)
    @bytes = map { ($_ ^ $S->_cipher()) } @bytes;
    return pack('C*', @bytes);
}

## Decrypt (or encrypt) the given data bytes. (This function is an
#  alias to C<encrypt>.)
sub decrypt
{
    ## @par See L</encrypt>.
    goto &encrypt;
}

## @internal

## Update the S-Box state. Update the state with values that
#  are a complex function of the current values.
sub _update
{
    my $S = $_[0];
    my ($i, $j, $k, $w) = \@$S[I .. W];
    $$i = ($$i + $$w) & M;
    $$j = ($$k + $$S[($$j + $$S[$$i]) & M]) & M;
    $$k = ($$i + $$k + $$S[$$j]) & M;
    @$S[$$j, $$i] = @$S[$$i, $$j];
}

## Produce next byte of the cipher stream. The output is a
#  complex function of the state and itself. This is a form
#  of OFB mode (Output Feedback).
sub _cipher
{
    my $S = $_[0];
    $S->_update();
    my ($i, $j, $k, $w, $z) = \@$S[I .. Z];
    $$z = ($$S[($$j + $$S[($$i + $$S[($$z + $$k) & M] & M)]) & M]) & M;
}

## Thoroughly mix the S-Box. Repeatedly call _update to provide
#  very complex new values to the state.
sub _whip
{
    my $S = $_[0];
    $S->_update() for (0 .. ((N * 2) - 1));
    $$S[W] += 2; ## @note If N not a power of 2, a complex update is
                 #        required to keep w relatively prime to N
}

## More mixing - this step is irreversible. It intentionally looses
#  information about the current state. Specifically, it maps 2**(N/2)
#  states to 1. This makes it harder to reverse engineer the key.
sub _crush
{
    my $S = $_[0];
    for my $v (0 .. (int(N / 2) - 1))
    {
        if ($$S[$v] > $$S[(N - 1) - $v])
        {
            @$S[$v, (N - 1) - $v] = @$S[(N - 1) - $v, $v];
        }
    }
}

## The mix master
#  @note Assumes key limited to N/2 nibbles (N/4 bytes). Otherwise
#        must set a to 0 so more key bytes can be absorbed.
sub _shuffle
{
    $_[0]->_whip();
    $_[0]->_crush();
    $_[0]->_whip();
    $_[0]->_crush();
    $_[0]->_whip();
    # (see note) $_[0]->[A] = 0;
}

## Bring in key data
#  @note Byte oriented implementation
#  @note Assumes key limited to N/2 nibbles (N/4 bytes). Otherwise
#        must check if a >= (N/2) to trigger a _shuffle.
sub _absorb
{
    my $S = $_[0];
    my $a = \$$S[A];
    for (split '', $_[1]) #< @param $string Key string (bytes) to absorb
    {
        my $t = ord($_);
        for my $x ((0x0f & $t), ((0xf0 & $t) >> 4))
        {
            # (see note) $S->_shuffle() if ($$a >= int(N / 2));
            @$S[int(N / 2) + $x, $$a] = @$S[$$a, int(N / 2) + $x];
            $$a++;
        }
    }
}

## Initialize the S-Box and state variables
sub _init
{
    my $S = $_[0];
                 # a  i  j  k  w  z
    @$S[A .. Z] = (0, 0, 0, 0, 1, 0);
    $$S[$_] = $_ for (0 .. (N - 1));
}

## @endinternal

1;

=end PerlDox

=head1 REFERENCES

I<Spritz - a spongy RC4-like stream cipher and hash function>, 2014,
Ronald L. Rivest, MIT and Jacob C. N. Schuldt, AIST (Japan)
C<http://people.csail.mit.edu/rivest/pubs/RS14.pdf>

=head1 AUTHOR

RonW, <ronw at cpan.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-rs14_pp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-RS14_PP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::RS14_PP

=head1 LICENSE AND COPYRIGHT

Copyright 2015 RonW, ronw at cpan.org

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic license 2. You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
