package Biblio::RFID::SmartX;

use warnings;
use strict;

use Data::Dump qw(dump);

=head1 NAME

Biblio::RFID::SmartX - Croatian student cards format


=head1 METHODS

=head2 to_hash

  my $hash = Biblio::RFID::Decode::SmartX->to_hash( [ 'sector1', 'sector2', ... , 'sector7' ] );

=cut

sub bcd {
	my $data = shift;
	return join('', map { sprintf("%02x",ord($_)) } split (//, $data));
}

sub to_hash {
	my ( $self, $data ) = @_;

	return unless $data;

	die "expecting array of sectors" unless ref $data eq 'ARRAY';

	my $decoded;
	foreach ( 4 .. 6 ) {
		warn "# $_: ",
		$decoded->[$_] = bcd( $data->[$_] );
	}

	my $hash;
	$hash->{SXID}    = substr( $decoded->[4], 0,  20 );
	$hash->{JMBAG}   = substr( $decoded->[4], 22, 10 );
	$hash->{OIB}     = substr( $decoded->[5], 16, 11 );
	$hash->{SPOL}    = substr( $data->[5], 14, 1 ); # char, not BCD!
	$hash->{INST_ID} = substr( $decoded->[6], 0, 12 );
	$hash->{CARD_V}  = substr( $decoded->[6], 12, 4  );

	warn "## hash = ",dump($hash);

	return $hash;

}

1;
