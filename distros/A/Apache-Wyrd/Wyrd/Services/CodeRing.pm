#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Services::CodeRing;
our $VERSION = '0.98';
use Apache::Wyrd::Services::SAK qw(lc_hash);
use Apache::Wyrd::Services::Key;
use Digest::SHA qw(sha1_hex);

my $pure_perl = 0;
eval ('use Crypt::Blowfish');
if ($@) {
	eval ('use Crypt::Blowfish_PP');
	die "$@" if ($@);
	$pure_perl = 1;
}

#Initialize Key.  Assumes startup with Apache, will stay resident as a class constant
my $key = Apache::Wyrd::Services::Key->instance();

=pod

=head1 NAME

Apache::Wyrd::Services::CodeRing - Apache-resident crypto tool (Blowfish)

=head1 SYNOPSIS

    my $cr1 = Apache::Wyrd::Services::CodeRing->new;
    my $key = $cr1->key;
    my $secret = "The turtle moves!"
    my $cytext = $cr1->encrypt($secret);

    my $cr2 = Apache::Wyrd::Services::CodeRing->new({key => $key});
    my $plaintext = ($cr2->decrypt($crptext)
      || die "Key or cypher text was corrupt");

=head1 DESCRIPTION

The CodeRing is an encryption/decryption object for use primarily for
encrypting state information into cookies or hidden variables without
exposing the data to deconstruction or corruption in transference.

It uses the blowfish algorithm via either a Crypt::Blowfish or
Crypt::Blowfish_PP module, depending on which one compiles on this
system, preferring the C-based one.

The CodeRing uses an internal hashing algorithm (SHA) to check the
validity of the decrypt.  If the decrypt shows alteration, it returns an
empty string.

Unless the CodeRing is given a key on initialization, it uses an
instance of the C<Apache::Wyrd::Services::Key> class, which is designed to
be a constant in primary server memory space.  The Key, in this case, is
"known" only to the Apache process, and is regenerated on each restart.

=head2 HTML ATTRIBUTES

=over

=item attribute

attribute description

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (Apache::Wyrd::Services::CodeRing) C<new> ([hashref])

Create a new CodeRing.  Accepts an optional hashref initialization.  The
hashref can have a key, B<key>, the value of which will be the key used
for encryption and decryption.

=cut

sub new {
	my ($class, $init) = @_;
	$init = lc_hash($init);
	my $instance_cypher = $key->cypher;
	if ($pure_perl) {
		$instance_cypher = Crypt::Blowfish_PP->new($$init{'key'}) if ($$init{'key'});
	} else {
		$instance_cypher = Crypt::Blowfish->new($$init{'key'}) if ($$init{'key'});
	}
	my $data = {
		cypher => $instance_cypher,
		key => ($$init{'key'} || $key->key)
	};
	bless $data, $class;
	return $data;
}

=item (scalar) C<key> (void)

Return the value of the current key.

=cut

sub key {
	my $self = shift;
	return $self->{'key'};
}

=pod

=item (scalarref) C<encrypt> (scalarref)

Encrypt the text referred to by the argument.  Returns a scalarref.

=cut

sub encrypt {
	my ($self, $textref) = @_;
	die ("you must use a scalar ref in encrypt at " . join(':', caller)) unless (ref($textref) eq 'SCALAR');
	my ($i, @out, $block, $cyphertext) = ();
	#Note: 7 nulls are added to ensure a full final octet.
	my $crc = sha1_hex($$textref);
	my @in = split ('', $$textref . "\0". $crc . "\0\0\0\0\0\0\0\0");
	while ($#in > 0) {
		$block = $self->{'cypher'}->encrypt(pack('a8', join('', splice (@in, 0, 8))));
		push (@out, unpack('H*', $block));
	}
	$cyphertext = join ('', @out);
	return \$cyphertext;
}

=pod

=item (scalarref) C<decrypt> (scalarref)

Decrypt the text referred to by the argument.  Returns a scalarref.  The
scalarref is zero-length on a failed decrypt.

=cut

sub decrypt {
	my ($self, $textref) = @_;
	die ("you must use a scalar ref in decrypt at " . join(':', caller)) unless (ref($textref) eq 'SCALAR');
	my ($d, $block, $plaintext) = ();
	my @in = split('', $$textref);
	while ($#in > 0) {
		$block = '';
		while (length($block) < 8){
			$d = chr(hex(join('', (splice(@in, 0, 2)))));
			#last unless ($d);
			$block .= $d;
		}
		$plaintext .= $self->{'cypher'}->decrypt($block);
	}
	#remove tail nulls and all trailing garbage
	$plaintext =~ s/\0([A-Fa-f0-9]{40})\0*.*$//s;
	my $crc = sha1_hex($plaintext);
	#If the CRC check fails, assume the key is bad and return null;
	$plaintext = '' if ($crc ne $1);
	return \$plaintext
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Rather than returning an error, the C<decrypt> method silently returns a
ref to an empty string on an unsuccessful decrypt.  The null byte ("\0")
is used internally as a string terminator.  Any item encrypted
containing null bytes will not successfully decrypt.

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd::Services::Key

Shared-memory encryption key and cypher.

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;