package Crypt::Ctr::FullWidth;
use base qw(Crypt::CFB);

use strict;
use warnings;

sub _statef;

sub new {
	my ($proto, $key, $algo) = @_;
	my $class = ref($proto) || $proto;
	my $self = new Crypt::CFB ($key, $algo);
	$self->{statef} = \&_statef;
	bless ($self, $class);
}

	
sub _statef {
	my $self = shift;

	my @ints = reverse unpack "n*", $self->{register};

	use integer; # unsigned
	foreach my $int ( @ints ) {
		$int++;
		last unless $int & ( 1 << 16 ); # we can stop if the integer didn't overflow
	}

	$self->{register} = pack("n*", reverse @ints);
}

sub bencrypt {
	my ($self, $block, $d) = @_;
	my $xor = &{$self->{cf}}();
	my $out = $block ^ substr($xor, 0, length($block) );
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
	my $blocksize = $self->{registerlength};
	join '', map { $self->bencrypt($_, $d) } unpack("(a$blocksize)*", $string);
}

# UGH! gotta duplicate these tow because they call _encrypt as a function, not a method
sub encrypt {
	my ($self, $string) = @_;
	return $self->_encrypt($string, 0);
}

sub decrypt {
	my ($self, $string) = @_;
	return $self->_encrypt($string, 1);
}

sub set_nonce {
	my ( $self, $nonce ) = @_;
	$self->{register} = $nonce;
}

1;
__END__

=pod

=head1 NAME

Crypt::Ctr::FullWidth - Like L<Crypt::Ctr> but works at the blocksize, not word size.

=head1 SYNOPSIS

	use Crypt::Ctr::FullWidth;

	my $cipher = new Crypt::Ctr::FullWidth $key, 'Crypt::Rijndael';

	my $ciphertext = $cipher->encrypt($plaintext);
	my $plaintext = $cipher->decrypt($ciphertext);

	my $cipher2 = new Crypt::Ctr::FullWidth $key, 'Digest::MD5';

	$ciphertext = $cipher->encrypt($plaintext);
	$plaintext = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

See L<Crypt::Ctr> for the API. It is unchanged.

The difference is in the block processing. Instead of incrementing the counter
and xoring per each byte of input, this mode works with the native size of the
underlying block cipher.

This module was written to support L<Crypt::EAX>, whose specification mandates
a different implementation of the counter mode.
