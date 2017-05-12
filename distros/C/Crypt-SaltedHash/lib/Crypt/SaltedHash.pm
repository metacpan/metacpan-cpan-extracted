package Crypt::SaltedHash;

use strict;
use MIME::Base64 ();
use Digest       ();

use vars qw($VERSION);

$VERSION = '0.09';

=encoding latin1

=head1 NAME

Crypt::SaltedHash - Perl interface to functions that assist in working
with salted hashes.

=head1 SYNOPSIS

	use Crypt::SaltedHash;

	my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
	$csh->add('secret');

	my $salted = $csh->generate;
	my $valid = Crypt::SaltedHash->validate($salted, 'secret');


=head1 DESCRIPTION

The C<Crypt::SaltedHash> module provides an object oriented interface to
create salted (or seeded) hashes of clear text data. The original
formalization of this concept comes from RFC-3112 and is extended by the use
of different digital agorithms.

=head1 ABSTRACT

=head2 Setting the data

The process starts with 2 elements of data:

=over

=item *

a clear text string (this could represent a password for instance).

=item *

the salt, a random seed of data. This is the value used to augment a hash in order to
ensure that 2 hashes of identical data yield different output.

=back

For the purposes of this abstract we will analyze the steps within code that perform the necessary actions
to achieve the endresult hashes. Cryptographers call this hash a digest. We will not however go into an explanation
of a one-way encryption scheme. Readers of this abstract are encouraged to get information on that subject by
their own.

Theoretically, an implementation of a one-way function as an algorithm takes input, and provides output, that are both
in binary form; realistically though digests are typically encoded and stored in a database or in a flat text or XML file.
Take slappasswd5 for instance, it performs the exact functionality described above. We will use it as a black box compiled
piece of code for our analysis.

In pseudocode we generate a salted hash as follows:

    Get the source string and salt as separate binary objects
    Concatenate the 2 binary values
    Hash the concatenation into SaltedPasswordHash
    Base64Encode(concat(SaltedPasswordHash, Salt))

We take a clear text string and hash this into a binary object representing the hashed value of the clear text string plus the random salt.
Then we have the Salt value, which are typically 4 bytes of purely random binary data represented as hexadecimal notation (Base16 as 8 bytes).

Using SHA-1 as the hashing algorithm, SaltedPasswordHash is of length 20 (bytes) in raw binary form
(40 bytes if we look at it in hex). Salt is then 4 bytes in raw binary form. The SHA-1 algorithm generates
a 160 bit hash string. Consider that 8 bits = 1 byte. So 160 bits = 20 bytes, which is exactly what the
algorithm gives us.

The Base64 encoding of the binary result looks like:

    {SSHA}B0O0XSYdsk7g9K229ZEr73Lid7HBD9DX

Take note here that the final output is a 32-byte string of data. The Base64 encoding process uses bit shifting, masking, and padding as per RFC-3548.

A couple of examples of salted hashes using on the same exact clear-text string:

    slappasswd -s testing123
    {SSHA}72uhy5xc1AWOLwmNcXALHBSzp8xt4giL

    slappasswd -s testing123
    {SSHA}zmIAVaKMmTngrUi4UlS0dzYwVAbfBTl7

    slappasswd -s testing123
    {SSHA}Be3F12VVvBf9Sy6MSqpOgAdEj6JCZ+0f

    slappasswd -s testing123
    {SSHA}ncHs4XYmQKJqL+VuyNQzQjwRXfvu6noa

4 runs of slappasswd against the same clear text string each yielded unique endresult hashes.
The random salt is generated silently and never made visible.

=head2 Extracting the data

One of the keys to note is that the salt is dealt with twice in the process. It is used once for the actual application of randomness to the
given clear text string, and then it is stored within the final output as purely Base64 encoded data. In order to perform an authentication
query for instance, we must break apart the concatenation that was created for storage of the data. We accomplish this by splitting
up the binary data we get after Base64 decoding the stored hash.

In pseudocode we would perform the extraction and verification operations as such:

    Strip the hash identifier from the Digest
    Base64Decode(Digest, 20)
    Split Digest into 2 byte arrays, one for bytes 0 – 20(pwhash), one for bytes 21 – 32 (salt)
    Get the target string and salt as separate binary object
    Concatenate the 2 binary values
    SHA hash the concatenation into targetPasswordHash
    Compare targetPasswordHash with pwhash
    Return corresponding Boolean value

Our job is to split the original digest up into 2 distinct byte arrays, one of the left 20 (0 - 20 including the null terminator) bytes and
the other for the rest of the data. The left 0 – 20 bytes will represent the salted  binary value we will use for a byte-by-byte data
match against the new clear text presented for verification. The string presented for verification will have to be salted as well. The rest
of the bytes (21 – 32) represent the random salt which when decoded will show the exact hex characters that make up the once randomly
generated seed.

We are now ready to verify some data. Let's start with the 4 hashes presented earlier. We will run them through our code to extract the
random salt and then using that verify the clear text string hashed by slappasswd. First, let's do a verification test with an erroneous
password; this should fail the matching test:

    {SSHA}72uhy5xc1AWOLwmNcXALHBSzp8xt4giL Test123
    Hash extracted (in hex): ef6ba1cb9c5cd4058e2f098d71700b1c14b3a7cc
    Salt extracted (in hex): 6de2088b
    Hash length is: 20 Salt length is: 4
    Hash presented in hex: 256bc48def0ce04b0af90dfd2808c42588bf9542
    Hashes DON'T match: Test123

The match failure test was successful as expected. Now let's use known valid data through the same exact code:

    {SSHA}72uhy5xc1AWOLwmNcXALHBSzp8xt4giL testing123
    Hash extracted (in hex): ef6ba1cb9c5cd4058e2f098d71700b1c14b3a7cc
    Salt extracted (in hex): 6de2088b
    Hash length is: 20 Salt length is: 4
    Hash presented in hex: ef6ba1cb9c5cd4058e2f098d71700b1c14b3a7cc
    Hashes match: testing123

The process used for salted passwords should now be clear. We see that salting hashed data does indeed add another layer of security to the
clear text one-way hashing process. But we also see that salted hashes should also be protected just as if the data was in clear text form.
Now that we have seen salted hashes actually work you should also realize that in code it is possible to extract salt values and use them
for various purposes. Obviously the usage can be on either side of the colored hat line, but the data is there.

=head1 METHODS

=over 4

=item B<new( [%options] )>

Returns a new Crypt::SaltedHash object.
Possible keys for I<%options> are:

=over

=item *

I<algorithm>: It's also possible to use common string representations of the
algorithm (e.g. "sha256", "SHA-384"). If the argument is missing, SHA-1 will
be used by default.

=item *

I<salt>: You can specify your on salt. You can either specify it as a sequence
of charactres or as a hex encoded string of the form "HEX{...}". If the argument is missing,
a random seed is provided for you (recommended).

=item *

I<salt_len>:  By default, the module assumes a salt length of 4 bytes (or 8, if it is encoded in hex).
If you choose a different length, you have to tell the I<validate> function how long your seed was.

=back

=cut

sub new {
    my ( $class, %options ) = @_;

    $options{algorithm} ||= 'SHA-1';
    $options{salt_len}  ||= 4;
    $options{salt}      ||= &__generate_hex_salt( $options{salt_len} * 2 );

    $options{algorithm} = uc( $options{algorithm} );
    $options{algorithm} .= '-1'
      if $options{algorithm} =~ m!SHA$!;  # SHA => SHA-1, HMAC-SHA => HMAC-SHA-1

    my $digest = Digest->new( $options{algorithm} );
    my $self   = {
        salt      => $options{salt},
        algorithm => $options{algorithm},
        digest    => $digest,
        scheme    => &__make_scheme( $options{algorithm} ),
    };

    return bless $self, $class;
}

=item B<add( $data, ... )>

Logically joins the arguments into a single string, and uses it to
update the current digest state. For more details see L<Digest>.

=cut

sub add {
    my $self = shift;
    $self->obj->add(@_);
    return $self;
}

=item B<clear()>

Resets the digest.

=cut

sub clear {
    my $self = shift;
    $self->{digest} = Digest->new( $self->{algorithm} );
    return $self;
}

=item B<salt_bin()>

Returns the salt in binary form.

=cut

sub salt_bin {
    my $self = shift;

    return $self->{salt} =~ m!^HEX\{(.*)\}$!i ? pack( "H*", $1 ) : $self->{salt};
}

=item B<salt_hex()>

Returns the salt in hexadecimal form ('HEX{...}')

=cut

sub salt_hex {
    my $self = shift;

    return $self->{salt} =~ m!^HEX\{(.*)\}$!i
      ? $self->{salt}
      : 'HEX{' . join( '', unpack( 'H*', $self->{salt} ) ) . '}';
}

=item B<generate()>

Generates the seeded hash. Uses the I<clone>-method of L<Digest> before actually performing
the digest calculation, so adding more cleardata after a call of I<generate> to an instance of
I<Crypt::SaltedHash> has the same effect as adding the data before the call of I<generate>.

=cut

sub generate {
    my $self = shift;

    my $clone = $self->obj->clone;
    my $salt  = $self->salt_bin;

    $clone->add($salt);

    my $gen = &MIME::Base64::encode_base64( $clone->digest . $salt, '' );
    my $scheme = $self->{scheme};

    return "{$scheme}$gen";
}

=item B<validate( $hasheddata, $cleardata, [$salt_len] )>

Validates a hasheddata previously generated against cleardata. I<$salt_len> defaults to 4 if not set.
Returns 1 if the validation is successful, 0 otherwise.

=cut

sub validate {
    my ( undef, $hasheddata, $cleardata, $salt_len ) = @_;

    # trim white-spaces
    $hasheddata =~ s!^\s+!!;
    $hasheddata =~ s!\s+$!!;

    my $scheme    = &__get_pass_scheme($hasheddata);
    $scheme       = uc( $scheme ) if $scheme;
    my $algorithm = &__make_algorithm($scheme);
    my $hash      = &__get_pass_hash($hasheddata) || '';
    my $salt      = &__extract_salt( $hash, $salt_len );

    my $obj = __PACKAGE__->new(
        algorithm => $algorithm,
        salt      => $salt,
        salt_len  => $salt_len
    );
    $obj->add($cleardata);

    my $gen_hasheddata = $obj->generate;
    my $gen_hash       = &__get_pass_hash($gen_hasheddata);

    return $gen_hash eq $hash;
}

=item B<obj()>

Returns a handle to L<Digest> object.

=cut

sub obj {
    return shift->{digest};
}

=back

=head1 FUNCTIONS

I<none yet.>

=cut

sub __make_scheme {

    my $scheme = shift;

    my @parts = split /-/, $scheme;
    pop @parts if $parts[-1] eq '1';    # SHA-1 => SHA

    $scheme = join '', @parts;

    return uc("S$scheme");
}

sub __make_algorithm {
    my ( $algorithm ) = @_;

    $algorithm ||= '';
    local $1;

    if ( $algorithm =~ m!^S(.*)$! ) {
        $algorithm = $1;

        # print STDERR "algorithm: $algorithm\n";
        if ( $algorithm =~ m!([a-zA-Z]+)([0-9]+)! ) {

            my $name   = uc($1);
            my $digits = $2;

            # print STDERR "name: $name\n";
            # print STDERR "digits: $digits\n";

            $name = "HMAC-$2" if $name =~ m!^HMAC(.*)$!;    # HMAC-SHA-1
            $digits = "-$digits" unless $name =~ m!MD$!;    # MD2, MD4, MD5

            $algorithm = "$name$digits";
        }

    }

    return $algorithm;
}

sub __get_pass_scheme {
    local $1;
    return unless $_[0] =~ m/{([^}]*)/;
    return $1;
}

sub __get_pass_hash {
    local $1;
    return unless $_[0] =~ m/}(.*)/;
    return $1;
}

sub __generate_hex_salt {

    my @keychars = (
        "0", "1", "2", "3", "4", "5", "6", "7",
        "8", "9", "a", "b", "c", "d", "e", "f"
    );
    my $length = shift || 8;

    my $salt = '';
    my $max  = scalar @keychars;
    for my $i ( 0 .. $length - 1 ) {
        my $skip = $i == 0 ? 1 : 0;    # don't let the first be 0
        $salt .= $keychars[ $skip + int( rand( $max - $skip ) ) ];
    }

    return "HEX{$salt}";
}

sub __extract_salt {

    my ( $hash, $salt_len ) = @_;

    my $binhash = &MIME::Base64::decode_base64($hash);
    my $binsalt = substr( $binhash, length($binhash) - ( $salt_len || 4 ) );

    return $binsalt;
}

=head1 SEE ALSO

L<Digest>, L<MIME::Base64>

=head1 AUTHOR

Sascha Kiefer, L<esskar@cpan.org>

=head1 ACKNOWLEDGMENTS

The author is particularly grateful to Andres Andreu for his article: Salted
hashes demystified - A Primer (L<http://www.securitydocs.com/library/3439>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 Sascha Kiefer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
