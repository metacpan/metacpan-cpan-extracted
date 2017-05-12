package Crypt::Ctr;
use Crypt::CFB;
use vars qw($VERSION);
@ISA = (Crypt::CFB);

$VERSION = 0.01;

sub _statef;

#
# Crypt::Ctr implements the Counter Mode for block ciphers.
# almost everything is inherited from Crypt::CFB, just the
# _statef method is overloaded.
# 
# XXX  the counter is just a perl int. So after roughly two Gigabytes
# of cleartext, the keystream will repeat itself. 
#

sub new {
	my ($proto, $key, $algo) = @_;
	my $class = ref($proto) || $proto;
	my $self = new Crypt::CFB ($key, $algo);
	$self->{statef} = \&_statef;
	$self->{fill} = "\x0" x ($self->{registerlength} - 4);
	bless ($self, $class);
}

	
sub _statef {
	my $self = shift;
	my ($c, undef) = unpack "La*", $self->{register};
	$c++;
	$self->{register} = unpack "a*" , (pack "La*", ($c, $self->{fill}));
}

1;
__END__

=pod

=head1 NAME

Crypt::Ctr - Encrypt Data in Counter Mode

=head1 SYNOPSIS

	use Crypt::Ctr;

	my $cipher = new Crypt::Ctr $key, 'Crypt::Rijndael';

	my $ciphertext = $cipher->encrypt($plaintext);
	my $plaintext = $cipher->decrypt($ciphertext);

	my $cipher2 = new Crypt::Ctr $key, 'Digest::MD5';

	$ciphertext = $cipher->encrypt($plaintext);
	$plaintext = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

Generic Counter Mode implementation in pure Perl.
The Counter Mode module constructs a stream
cipher from a block cipher or cryptographic hash funtion
and returns it as an object. Any block cipher in the
C<Crypt::> class can be used, as long as it supports the
C<blocksize> and C<keysize> methods. Any hash function in
the C<Digest::> class can be used, as long as it supports
the C<add> method.

=head2 Note 

Counter mode produces the keystream independent from the
input. Be sure not to re-use keys in Counter mode. As
with Cipher Feedback mode, one should use Counter mode
inside authenticated channels, e.g. HMAC.

=head1 METHODS

=over 4

=item C<$cipher = new Crypt::Ctr $key, $algorithm>

Constructs a Crypt::Ctr object. If C<$algorithm> is a block cipher, then
C<$key> should be of the correct size for that cipher. In most
cases you can inquire the block cipher module by invoking the
C<keysize> method. If C<$algorithm> is a hash function, then
C<$key> can be of any size.

=item C<$ciphertext = $cipher-E<gt>encrypt $plaintext>

Encrypts C<$plaintext>. The input is XORed with the keystream
generated from the internal state of the Ctr object and that 
state is updated with the output. C<$plaintext> can be of any length.

=item C<$cipher-E<gt>reset>

Resets the internal state. Remember to do that
before decrypting, if you use the same object.

=item C<$plaintext = $cipher-E<gt>decrypt $ciphertext>

Decrypts C<$ciphertext>.

=back

=head1 BUGS

This is awfully slow. Some classes in C<Digest::> do not provide
the C<add> method, so they will fail.  The internal
counter is a Perl integer. This could possibly lead to strange errors
when encrypting more than C<POSIX::LONG_MAX> bytes and decrypting
it on a different architecture.

=head1 AUTHOR

Matthias Bauer <matthiasb@acm.org>

=cut


