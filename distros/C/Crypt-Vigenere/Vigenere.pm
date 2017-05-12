package Crypt::Vigenere;

$VERSION = "0.08";

use strict;

sub new {
	my $class = shift;
	my $keyword = shift || '';

	if( $keyword !~ /^[a-z]+$/ ) {
		return;
	};

	my $self = {
		'keyword' => $keyword,
	};
	bless $self, $class;

	$self->_init( $keyword );

	return( $self );
};

sub _init {
	my $self = shift;

	foreach ( split('', lc($self->{keyword})) ) {
		my $ks = (ord($_)-97) % 26;
		my $ke = $ks - 1;
 
		my ($s, $S, $e, $E);
 
		$s = chr(ord('a') + $ks);
		$e = chr(ord('a') + $ke);

		push @{$self->{fwdLookupTable}}, "a-z/$s-za-$e";
		push @{$self->{revLookupTable}}, "$s-za-$e/a-z";
	};

	return( $self );
};

sub encodeMessage {
	my $self = shift;
	my $string = shift;
	return( $self->_doTheMath($string, $self->{fwdLookupTable}) );
};

sub decodeMessage {
	my $self = shift;
	my $string = shift;
	return( $self->_doTheMath($string, $self->{revLookupTable}) );
};


sub _doTheMath {
	my $self = shift;
	my $string = shift;
	my $lookupTable = shift;
	my $returnString;

	my $count = 0;
	foreach( split('', lc($string)) ) {
		if( /[a-z]{1}/ ) {
			eval "\$_ =~ tr/$lookupTable->[$count % length($self->{keyword})]/";
			$count++;
			$returnString .= $_;
		}
	};

	return( $returnString );
};


1;

=head1 NAME

Crypt::Vigenere - Perl implementation of the Vigenere cipher


=head1 SYNOPSIS

  use Crypt::Vigenere;

  $vigenere = Crypt::Vigenere->new( $keyword );

  # Encode the plaintext
  $cipher_text = $vigenere->encodeMessage( $plain_text );

  # Decode the ciphertext 
  $plain_text = $vigenere->decodeMessage( $cipher_text );


=head1 DESCRIPTION

See the documentation that came with the Crypt::Vigenere package for
more information.

=head2 EXPORT

None by default.


=head1 AUTHOR

Alistair Mills, http://search.cpan.org/~friffin/

=cut
