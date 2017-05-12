package Crypt::AllOrNothing;

use warnings;
use strict;
use Crypt::OpenSSL::AES;
use Crypt::AllOrNothing::Util qw/:all/;
use Carp;
use Crypt::Random qw/makerandom/;

=head1 NAME

Crypt::AllOrNothing - All-Or-Nothing Encryption

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

  use Crypt::AllOrNothing;

  my $AllOrNothing = Crypt::AllOrNothing->new(K_0=>$K_0);
  my $K_0 = $AllOrNothing->get_K_0();
  my $K_0 = $AllOrNothing->set_K_0($K_0);
  my $size = $AllOrNothing->get_size();
  my @AllOrNothing_text = $AllOrNothing->encrypt(text=>$plaintext);
  my $plaintext = $AllOrNothing->decrypt(text=>@AllOrNothing_text);

=head1 CONSTANTS

  $SIZE = 128 bits;

=cut

my $SIZE = 128;

=head1 FUNCTIONS

=head2 new(K_0=>$K_0)

Create AllOrNothing object.  Good idea to provide K_0, which must be ascii encoded(characters) and of length given in size.  
If K_0 is not given, you must retrieve it later with $AllOrNothing->K_0() else you will not be able to decrypt the message.

=cut

sub new {
	my $class = shift;
	my %params = @_;
	my $self;
	########
	#Check params
	########
	if (!exists $params{size}) {
		$self->{size} = $SIZE;
	} elsif ($params{size} =~ /^(128)$/) {
		$self->{size} = $params{size};
	} else {
		croak "Given size($params{size}) is invalid, valid sizes are 128 256 512 1024";
	}

	if (!exists $params{K_0}) {
		#carp 'No K_0 given.  One will be automatically generated.  You must manually get this value with $AllOrNothing->get_K_0() to decrypt.';
		$self->{K_0}=randomValue(size=>$self->{size}, 'return'=>'ascii');
	} elsif (length $params{K_0} == $self->{size}/8) {
		$self->{K_0}=$params{K_0};
	} else {
		croak "Given K_0 was invalid, if given in new() it must be the correct length and characters(not int, hex, or base64)";
	}

	bless $self, $class;
}

=head2 K_0(K_0=>$K_0)

get/set K_0.  K_0 must be ascii encoded(characters) and length given in size.

=cut

sub K_0 {
	my $self = shift;
	if (@_) {
		my $tmp_K_0 = shift;
		if (length $tmp_K_0 != $self->{size}) {
			carp 'K_0 passed is not correct length(must be equal to $AllOrNothing->size()), K_0 will not be set';
		} else {
			$self->{K_0} = $tmp_K_0;
		}
	}
	return $self->{K_0};
}

=head2 size()

get size.

=cut

sub size {
	my $self = shift;
	return $self->{size};
}

=head2 @ciphertext = encrypt(plaintext=>$plaintext, padding=>$padding)

encrypt plaintext with All Or Nothing transform to array of messages.  Optionally pass padding which will be used internally

=cut

sub encrypt {
	my $self = shift;
	my %params = @_;

	#break packets into length size packets
	my @message = breakString(string=>$params{plaintext}, size=>$self->{size}/8);
	
	#create K_Prime
	my $K_Prime = randomValue(size=>$self->{size}, 'return'=>'ascii');
	my $cipher_K_Prime = Crypt::OpenSSL::AES->new($K_Prime) or croak "Could not create AES cipher with K_Prime";

	#add length and padding to message
	addLength_andPad(array=>\@message, size=>$self->{size}/8, padding=>$params{padding});

	#encrypt
	#m_Prime_sub_i = m_sub_i xor E(K_Prime, i) for i=1..s
	#i must be made to a character and padded to size 'size' bits
	my @messagePrime = ();
	for (my $i=0; $i<scalar @message; $i++) {
		push @messagePrime, $message[$i] ^ ($cipher_K_Prime->encrypt((sprintf("%c",0x00) x ($self->{size}/8-4)) . pack("L",$i)));
	}
	#m_Prime_sub_s_Prime = K_Prime xor h_1 xor h_2 xor ... h_s
	#h_i = E(K_sub_0, m_Prime_sub_i xor i) for i=1..s
	#i must be made to be 'size' bits
	#K_sub_0 is a fixed publicly known encryption key
	my $cipher_K_0 = Crypt::OpenSSL::AES->new($self->{K_0}) or croak "Could not create AES cipher with K_0";
	my $m_Prime_sub_s = $K_Prime;
	for (my $i=0; $i<scalar @message; $i++) {
		$m_Prime_sub_s ^= $cipher_K_0->encrypt($messagePrime[$i]^((sprintf("%c",0x00) x ($self->{size}/8-4)) . pack("L",$i)));
	}
	push @messagePrime, $m_Prime_sub_s;
	return @messagePrime;
}

=head2 $plaintext = decrypt(cryptotext=>\@cryptotext)

decrypt cryptotext array with All Or Nothing transform to plaintext

=cut

sub decrypt {
	my $self = shift;
	my %params = @_;
	my $cipher_K_0 = Crypt::OpenSSL::AES->new($self->{K_0}) or croak "Could not create AES cipher with K_0";
	#get K_Prime
	my $m_prime_sub_s_prime = $params{cryptotext}->[$#{$params{cryptotext}}];
	my $add_tmp = '';
	for (my $i=0;$i<$#{$params{cryptotext}};$i++) {
		$add_tmp ^= $cipher_K_0->encrypt($params{cryptotext}->[$i]^((sprintf("%c",0x00) x ($self->{size}/8-4)) . pack("L",$i)));
	}
	my $K_prime = $m_prime_sub_s_prime ^ $add_tmp;
	pop @{$params{cryptotext}};
	my $cipher_K_prime =  Crypt::OpenSSL::AES->new($K_prime) or die "did not work to create K_Prime AES cipher";
	my @m=();
	for (my $i=0;$i<scalar @{$params{cryptotext}};$i++) {
		push @m, $params{cryptotext}->[$i]^$cipher_K_prime->encrypt(((sprintf("%c",0x00) x 12) . pack("L",$i)));
	}
	remLength_andPad(array=>\@m);
	my $plaintext='';
	for (@m) {
		$plaintext .= $_;
	}
	return $plaintext;
}

=head1 AUTHOR

Timothy Zander, C<< <timothy.zander at alum.rpi.edu> >>

The All Or Nothing Encryption and Package Transform algorithm was developed by Ronald Rivest

=head1 BUGS

Please report any bugs or feature requests to
C<bug-crypt-aon at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-AllOrNothing>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Crypt::AllOrNothing

You can also look for information at:

=over 4

=item * Original Paper by Ronald Rivest

L<http://people.csail.mit.edu/rivest/fusion.pdf>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-AllOrNothing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-AllOrNothing>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-AllOrNothing>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-AllOrNothing>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Prof. Bulent Yener at RPI for his assistance.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Timothy Zander, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Crypt::AllOrNothing
