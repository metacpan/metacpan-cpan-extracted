package Crypt::CFB;
use vars qw($VERSION) ;
use UNIVERSAL qw(can);
require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

$VERSION = 0.02;

# 
# The object returned by Crypt::CFB->new(<key>,<algorithm>,[iv]) contains:
#
#  $self->{key}: the key 
#  $self->{algo}: instantiated object of the class <algorithm>
#  $self->{register}: the internal state of the Cipher Feedback mode
#  $self->{registerlength}: the length of the internal state in bytes
#  $self->{bytes}: the number of bytes to xor per round
#  $self->{iv}: a block of $self->{bytes} bytes, containing the
#               Initialization Vector.
#  $self->{cf}: anonymous subroutine without parameters. The
#               subs in this implementation read $self->{key}
#               and $self->{register}, apply the cryptographic
#               one-way function and return its output. This is
#               the stuff that is XORed to the cleartext in
#               Crypt::CFB::encrypt.
#  $self->{statef}: reference to a sub which updates the internal
#               state after each $self->{cf} call.
#  $self->{epattern}, $self->{rpattern}, $self->{spattern}:
#               diverse patterns for pack/unpack, which are 
#               computed at instantiation.
#
#  If you want to create another PurePerl Cipher Mode which is
#  basically a stream cipher, then you can simply overload
#  $self->{statef} and $self->{cf}. See for example Crypt::Ctr.
#

sub _statef;
sub _reginit;

sub new {
	my ($proto, $key, $algo, $iv) = @_;
	my $class = ref($proto) || $proto;
	my $self = {};

	# The number of bytes that are extracted per round
	# from the cipher/digest's output

	$self->{bytes} = 1; # XXX unused
	$self->{key} = $key;
	$self->{cf}  = sub {die "Don't forget to set the key stream function";};

	eval "require $algo;";
	if ($@) {
		die "Could not instantiate $algo: $!";
	}

	# We allow cryptographic one-way functions,
	# i.e. ciphers and hashes.

	if ($algo =~ m/^Crypt::/) {
		_Crypt_new($self, $algo, $key);
	} elsif ( $algo =~ m/^Digest::/) {
		_Digest_new($self, $algo, $key);
	} else {
		die "Algorithm should belong to Crypt:: or Digest::";
	}

	# These are patterns for pack/unpack which are 
	# subsequently used a lot.

	$self->{epattern} = "x" . ($self->{registerlength} - $self->{bytes}) .
		                "a" . $self->{bytes};
	$self->{rpattern} = "x" . $self->{bytes}  .
					    "a" . ($self->{registerlength} - $self->{bytes});
	$self->{spattern} = "a" . $self->{bytes} . "a*";

	# Store the Initialization Vector
	if (defined($iv)) {
		$self->{iv} = $iv;
	}

	# Initialize the internal state.
	$self->{register} = _reginit($self);

	# This is the function that does per-round manipulation
	# of the internal state.  
	$self->{statef} = \&_statef;

	bless ($self, $class);
	return $self;
}

sub _Digest_new {
	my ($self, $algo, $key) = @_;
	$self->{algo} = $algo->new();
	if ($@) {
		die "Could not instantiate $algo: $!";
	}

	# The Digest class has no "blocklength" method,
	# but that's no problem
	$self->{algo}->add("");
	$self->{registerlength} = length ($self->{algo}->digest);
	if (not $self->{registerlength}) {
		die "Could not set registerlength";
	}

	# Anonymous function to produce the keystream
	$self->{cf} = sub { 
		$self->{algo}->add($self->{key} . $self->{register});
		return $self->{algo}->digest;
	}
}

sub _Crypt_new {
	my ($self, $algo, $key) = @_;
	eval "require $algo;";

	if ($@) {
			die "Could not instantiate $algo: $!";
	}

	# Crypt::Blowfish returns keysize 0, so we take
	# the maximum in that case

	if (length $key > ( $algo->keysize || 56)) {
		$key = substr $key, 0, $algo->keysize;
	} 

	# We could check for correct keysizes, but the
	# Crypt:: algorithms throw an error anyway.

	$self->{algo} = $algo->new($key);

	if ($@) {
			die "Could not instantiate $algo: $!";
	}

	if (not $self->{algo}->can('blocksize')) {
			die "$algo does not implement blocksize";
	}

	$self->{registerlength} = $self->{algo}->blocksize;

	if (not $self->{registerlength}) {
			die "Could not set registerlength";
	}

	# Anonymous function to produce the keystream
	$self->{cf} = sub { 
		return $self->{algo}->encrypt($self->{register});
	}
}

sub _reginit {
	my $self = shift;
	my $iv = defined($self->{iv}) ? $self->{iv} : "";
	my $remainder = $self->{registerlength} - length($iv);
	return $iv . ("\x0" x $remainder);
}

# Per $self->{bytes} encryption/decryption 
sub bencrypt {
	my ($self, $block, $d) = @_;
	my $xor = &{$self->{cf}}();
	$xor = substr $xor, -($self->{bytes}), $self->{bytes};
# 	$xor = unpack $self->{epattern}, $xor;
	if ($self->{bytes} > 1) {
		if (length $block < length $xor) {
			$xor = substr $xor, 0, (length $block); 
		}
	}
	my $out = $block ^ $xor;
	if ($d) {
		&{$self->{statef}}($self,$block);
	} else {
		&{$self->{statef}}($self,$out);
	}
	return $out;
}

sub _encrypt {
	my ($self, $string, $d) = @_;
	my ($out, $i, $l);
	$l = length ($string);
	for ($i = 0; $i < $l; $i += $self->{bytes}) {
		$out .=  bencrypt ($self, (substr $string, $i, $self->{bytes}) , $d);
	}
	return $out;
}

sub encrypt {
	my ($self, $string) = @_;
	return _encrypt($self, $string, 0);
}

sub decrypt {
	my ($self, $string) = @_;
	return _encrypt($self, $string, 1);
}
		
# Reset the internal state
sub reset {
	my ($self, $iv) = @_;
	if (defined($iv)) {
		$self->{iv} = $iv;
	}
	$self->{register} = _reginit($self);
}

# This manipulates the internal state
sub _statef {
	my ($self, $c)  = @_;
	$self->{register} = (unpack $self->{rpattern}, $self->{register}) . $c;
}

1;

__END__


=pod

=head1 NAME

Crypt::CFB - Encrypt Data in Cipher Feedback Mode

=head1 SYNOPSIS

	use Crypt::CFB;

	my $cipher = new Crypt::CFB $key, 'Crypt::Rijndael';

	## Or:
	my $iv = ''; map { $iv .= chr(rand(256)) } (0..16);
	my $cipher = new Crypt::CFB $key, 'Crypt::Rijndael', $iv;

	my $ciphertext = $cipher->encrypt($plaintext);
	my $plaintext = $cipher->decrypt($ciphertext);

	my $cipher2 = new Crypt::CFB $key, 'Digest::MD5';

	$ciphertext = $cipher->encrypt($plaintext);
	$plaintext = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

Generic CFB implementation in pure Perl.
The Cipher Feedback Mode module constructs a stream
cipher from a block cipher or cryptographic hash funtion
and returns it as an object. Any block cipher in the
C<Crypt::> class can be used, as long as it supports the
C<blocksize> and C<keysize> methods. Any hash function in
the C<Digest::> class can be used, as long as it supports
the C<add> method.

=head1 METHODS

=over 4

=item C<$cipher = new Crypt::CFB $key, $algorithm, $optional_iv>

Constructs a CFB object. If C<$algorithm> is a block cipher, then
C<$key> should be of the correct size for that cipher. In most
cases you can inquire the block cipher module by invoking the
C<keysize> method. If C<$algorithm> is a hash function (C<Digest::>), then
C<$key> can be of any size.  The optional IV can be used to further
seed the crypto algorithm.  If no IV is given, a string of zeroes is used.

=item C<$ciphertext = $cipher-E<gt>encrypt $plaintext>

Encrypts C<$plaintext>. The input is XORed with the keystream
generated from the internal state of the CFB object and that 
state is updated with the output. C<$plaintext> can be of any length.

=item C<$cipher-E<gt>reset>

Resets the internal state. Remember to do that
before decrypting, if you use the same object.

=item C<$plaintext = $cipher-E<gt>decrypt $ciphertext>

Decrypts C<$ciphertext>.

=back

=head1 BUGS

This is awfully slow. Some classes in C<Digest::> do not provide
the C<add> method, so they will fail. The implementation is
a little baroque.

=head1 AUTHOR

Matthias Bauer <matthiasb@acm.org>

=head1 CHANGES

Added the use of an IV.

=head1 AUTHOR

Kees Jan Hermans <kees@phoezo.com>

=cut


