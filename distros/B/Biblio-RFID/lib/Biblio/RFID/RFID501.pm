package Biblio::RFID::RFID501;

use warnings;
use strict;

use Data::Dump qw(dump);

=head1 NAME

Biblio::RFID::RFID501 - RFID Standard for Libraries

=head1 DESCRIPTION

This module tries to decode tag format as described in document

  RFID 501: RFID Standards for Libraries

L<http://solutions.3m.com/wps/portal/3M/en_US/3MLibrarySystems/Home/Resources/CaseStudiesAndWhitePapers/RFID501/>

Goal is to be compatibile with existing 3M Alphanumeric tag format
which, as far as I know, isn't specificed anywhere. My documentation about
this format is available at

L<http://saturn.ffzg.hr/rot13/index.cgi?hitchhikers_guide_to_rfid>

=head1 Data model

=head2 3M Alphanumeric tag

 0   04 is 00 tt   i [4 bit] = number of item in set	[1 .. i .. s]
                   s [4 bit] = total items in set
                   tt [8 bit] = item type

 1   dd dd dd dd   dd [16 bytes] = barcode data
 2   dd dd dd dd
 3   dd dd dd dd
 4   dd dd dd dd

 5   bb bl ll ll   b [12 bit] = branch [unsigned]
                   l [20 bit] = library [unsigned]

 6   cc cc cc cc   c [32 bit] = custom signed integer

=head2 3M Manufacturing Blank

 0   55 55 55 55
 1   55 55 55 55
 2   55 55 55 55
 3   55 55 55 55
 4   55 55 55 55
 5   55 55 55 55
 6   00 00 00 00 

=head2 Generic blank

 0   00 00 00 00
 1   00 00 00 00
 2   00 00 00 00

=head1 Security

AFI byte on RFID tag is used for security.

In my case, we have RFID door which can only read AFI bytes from tag and issue
alarm sound or ignore it depending on value of byte.

=over 8 

=item 0xD7 214

secured item (door will beep)

=item 0xDA 218

unsecured (door will ignore it)

=back


=head1 METHODS

=head2 to_hash

  my $hash = Biblio::RFID::Decode::RFID501->to_hash( $bytes );

  my $hash = Biblio::RFID::Decode::RFID501->to_hash( [ 'blk1', 'blk2', ... , 'blk7' ] );

=head2 from_hash

  my $blocks = Biblio::RFID::Decode::RFID->from_hash({ content => "1301234567" });

=head2 blank_3m

=head2 blank

  my $blocks = Biblio::RFID::Decode::RFID->blank;

=cut

my $item_type = {
	1 => 'Book',
	6 => 'CD/CD ROM',
	2 => 'Magazine',
	13 => 'Book with Audio Tape',
	9 => 'Book with CD/CD ROM',
	0 => 'Other',

	5 => 'Video',
	4 => 'Audio Tape',
	3 => 'Bound Journal',
	8 => 'Book with Diskette',
	7 => 'Diskette',
};

sub to_hash {
	my ( $self, $data ) = @_;

	return unless $data;

	$data = join('', @$data) if ref $data eq 'ARRAY';

	warn "## to_hash ",dump($data);

	my ( $u1, $set_item, $u2, $type, $content, $br_lib, $custom, $zero ) = unpack('C4Z16Nl>l',$data);
	my $hash = {
		u1 => $u1,	# FIXME 0x04
		set => ( $set_item & 0xf0 ) >> 4,
		total => ( $set_item & 0x0f ),

		u2 => $u2,	# FIXME 0x00

		type => $type,
		type_label => $item_type->{$type},

		content => $content,

		branch => $br_lib >> 20,
		library => $br_lib & 0x000fffff,

		custom => $custom,
	};

	warn "expected first byte to be 0x04, not $u1\n"   if $u1 != 4;
	warn "expected third byte to be 0x00, not $u2\n"   if $u2 != 0;
	warn "expected last block to be zero, not $zero\n" if $zero != 0;

	return $hash;
}

sub from_hash {
	my ( $self, $hash ) = @_;

	warn "## from_hash ",dump($hash);

	$hash->{$_} ||= 0 foreach ( qw( set total type branch library ) );

	return pack('C4Z16Nl>l',
		0x04,
		( $hash->{set} << 4 ) | ( $hash->{total} & 0x0f ),
		0x00,
		$hash->{type},

		$hash->{content},

		( $hash->{branch} << 20 ) | ( $hash->{library} & 0x000fffff ),

		$hash->{custom},
		0x00,
	);
}

sub blank_3m {
	return ( "\x55" x ( 6 * 4 ) ) . ( "\x00" x 4 );
}

sub blank {
	return "\x00" x ( 4 * 3 );
}

1;
