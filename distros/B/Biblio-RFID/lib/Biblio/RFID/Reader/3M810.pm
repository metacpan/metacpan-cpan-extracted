package Biblio::RFID::Reader::3M810;

=head1 NAME

Biblio::RFID::Reader::3M810 - support for 3M 810 RFID reader

=head1 DESCRIPTION

This module uses L<Biblio::RFID::Reader::Serial> over USB/serial adapter
with 3M 810 RFID reader, often used in library applications.

This is most mature implementation which supports full API defined
in L<Biblio::RFID::Reader::API>. This include scanning for all tags in reader
range, reading and writing of data, and AFI security manipulation.

This implementation is developed using Portmon on Windows to capture serial traffic
L<http://technet.microsoft.com/en-us/sysinternals/bb896644.aspx>

Checksum for this reader is developed using help from C<selwyn>
L<http://stackoverflow.com/questions/149617/how-could-i-guess-a-checksum-algorithm>

More inforation about process of reverse engeeniring protocol with
this reader is available at L<http://blog.rot13.org/rfid/>

=cut

use warnings;
use strict;

use base 'Biblio::RFID::Reader::Serial';
use Biblio::RFID;

use Data::Dump qw(dump);
use Carp qw(confess);
use Time::HiRes;
use Digest::CRC;

sub serial_settings {{
	baudrate  => "19200",
	databits  => "8",
	parity	  => "none",
	stopbits  => "1",
	handshake => "none",
}}

sub assert;

my $port;
sub init {
	my $self = shift;
	$port = $self->port;

	# disable timeouts
	$port->read_char_time(0);
	$port->read_const_time(0);

	# drain on startup
	my ( $count, $str ) = $port->read(3);
	if ( $count ) {
		my $data = $port->read( ord(substr($str,2,1)) );
		warn "drain ",as_hex( $str, $data ),"\n";
	}

	$port->read_char_time(100);	 # 0.1 s char timeout
	$port->read_const_time(500); # 0.5 s read timeout

	$port->write( hex2bytes( 'D5 00  05   04 00 11   8C66' ) );
	# hw-version     expect: 'D5 00  09   04 00 11   0A 05 00 02   7250'
	my $data = $port->read( 12 );
	return unless $data;

	warn "# probe response: ",as_hex($data);
	if ( my $rest = assert $data => 'D5 00  09   04 00 11' ) {
		my $hw_ver = join('.', unpack('CCCC', $rest));
		warn "# 3M 810 hardware version $hw_ver\n";

		cmd(
'13  04 01 00 02 00 03 00 04 00','FIXME: stats? rf-on?', sub { assert(shift,
'13  00 02 01 01 03 02 02 03 00'
		)});

		return $hw_ver;
	}

	return;
}

sub checksum {
	my $bytes = shift;
	my $crc = Digest::CRC->new(
		# midified CCITT to xor with 0xffff instead of 0x0000
		width => 16, init => 0xffff, xorout => 0xffff, refout => 0, poly => 0x1021, refin => 0,
	) or die $!;
	$crc->add( $bytes );
	pack('n', $crc->digest);
}

sub cmd {
	my ( $hex, $description, $coderef ) = @_;
	my $bytes = hex2bytes($hex);
	if ( substr($bytes,0,1) !~ /(\xD5|\xD6)/ ) {
		my $len = pack( 'n', length( $bytes ) + 2 );
		$bytes = $len . $bytes;
		my $checksum = checksum($bytes);
		$bytes = "\xD6" . $bytes . $checksum;
	}

	warn ">> ", as_hex( $bytes ), "\t\t[$description]\n" if $debug;
	$port->write( $bytes );

	my $r_len = $port->read(3);

	while ( length($r_len) < 3 ) {
		$r_len = $port->read( 3 - length($r_len) );
	}

	my $len = ord( substr($r_len,2,1) );
	my $data = $port->read( $len );

	warn "<< ", as_hex($r_len,$data),
		' | ',
		substr($data,-2,2) eq checksum(substr($r_len,1).substr($data,0,-2)) ? 'OK' : 'ERROR',
		" $len bytes\n" if $debug;


	$coderef->( $data ) if $coderef;

}

sub assert {
	my ( $got, $expected ) = @_;
	$expected = hex2bytes($expected);

	my $len = length($got);
	$len = length($expected) if length $expected < $len;

	confess "got ", as_hex($got), " expected ", as_hex($expected)
	unless substr($got,0,$len) eq substr($expected,0,$len);

	return substr($got,$len);
}


sub inventory {

	my @tags;

cmd( 'FE  00 05', 'scan for tags', sub {
	my $data = shift;
	my $rest = assert $data => 'FE 00 00 05';
	my $nr = ord( substr( $rest, 0, 1 ) );

	if ( ! $nr ) {
		warn "# no tags in range\n";
	} else {
		my $tags = substr( $rest, 1 );
		my $tl = length( $tags );
		die "wrong length $tl for $nr tags: ",dump( $tags ) if $tl =! $nr * 8;

		foreach ( 0 .. $nr - 1 ) {
			push @tags, hex_tag substr($tags, $_ * 8, 8);
		}
	}

});

	warn "# tags ",dump @tags;
	return @tags;
}


# 3M defaults: 8,4
# cards 16, stickers: 8
my $max_rfid_block = 8;
my $blocks = 8;

sub _matched {
	my ( $data, $hex ) = @_;
	my $b = hex2bytes $hex;
	my $l = length($b);
	if ( substr($data,0,$l) eq $b ) {
		warn "_matched $hex [$l] in ",as_hex($data) if $debug;
		return substr($data,$l);
	}
}

sub read_blocks {
	my $tag = shift || confess "no tag?";
	$tag = shift if ref($tag);

	my $tag_blocks;
	my $start = 0;
	cmd(
		 sprintf( "02 $tag %02x %02x", $start, $blocks ) => "read_blocks $tag $start/$blocks", sub {
			my $data = shift;
			if ( my $rest = _matched $data => '02 00' ) {

				my $tag = hex_tag substr($rest,0,8);
				my $blocks = ord(substr($rest,8,1));
				warn "# response from $tag $blocks blocks ",as_hex substr($rest,9);
				foreach ( 1 .. $blocks ) {
					my $pos = ( $_ - 1 ) * 6 + 9;
					my $nr = unpack('v', substr($rest,$pos,2));
					my $payload = substr($rest,$pos+2,4);
					warn "## pos $pos block $nr ",as_hex($payload), $/;
					$tag_blocks->{$tag}->[$nr] = $payload;
				}
			} elsif ( $rest = _matched $data => 'FE 00 00 05 01' ) {
				warn "FIXME ready? ",as_hex $rest;
			} elsif ( $rest = _matched $data => '02 06' ) {
				die "ERROR ",as_hex($rest);
			} else {
				die "FIXME unsuported ",as_hex($rest);
			}
	});

	warn "# tag_blocks ",dump($tag_blocks);
	return $tag_blocks;
}

sub write_blocks {
	my $tag = shift;
	$tag = shift if ref $tag;

	my $data = shift;
	$data = join('', @$data) if ref $data eq 'ARRAY';

	warn "## write_blocks ",dump($tag,$data);

	if ( length($data) % 4 ) {
		$data .= '\x00' x ( 4 - length($data) % 4 );
		warn "# padded data to ",dump($data);
	}

	my $hex_data = as_hex $data;
	my $blocks   = sprintf('%02x', length($data) / 4 );

	cmd(
		"04 $tag 00 $blocks 00 $hex_data", "write_blocks $tag [$blocks] $hex_data", sub {
			my $data = shift;
			if ( my $rest = _matched $data => '04 00' ) {
				my $tag = substr($rest,0,8);
				my $blocks = substr($rest,8,1);
				warn "# WRITE ",as_hex($tag), " [$blocks]\n";
			} elsif ( $rest = _matched $data => '04 06' ) {
				die "ERROR ",as_hex($rest);
			} else {
				die "UNSUPPORTED";
			}
		}
	);

}

sub read_afi {
	my $tag = shift;
	$tag = shift if ref $tag;

	my $afi;

	cmd(
		"0A $tag", "read_afi $tag", sub {
		my $data = shift;

		if ( my $rest = _matched $data => '0A 00' ) {

			my $tag = substr($rest,0,8);
			   $afi = substr($rest,8,1);

			warn "# SECURITY ", hex_tag($tag), " AFI: ", as_hex($afi);

		} elsif ( $rest = _matched $data => '0A 06' ) {
			die "ERROR reading security from $tag ", as_hex($data);
		} else {
			die "IGNORED ",as_hex($data);
		}
	});
	warn "## read_afi ",dump($tag, $afi);
	return $afi;
}

sub write_afi {
	my $tag = shift;
	$tag = shift if ref $tag;
	my $afi = shift || die "no afi?";

	$afi = as_hex $afi;

	cmd(
		"09 $tag $afi", "write_afi $tag $afi", sub {
		my $data = shift;

		if ( my $rest = _matched $data => '09 00' ) {
			my $tag_back = hex_tag substr($rest,0,8);
			die "write_afi got $tag_back expected $tag" if $tag_back ne $tag;
			warn "# SECURITY ", hex_tag($tag), " AFI: ", as_hex($afi);
		} elsif ( $rest = _matched $data => '0A 06' ) {
			die "ERROR writing AFI to $tag ", as_hex($data);
		} else {
			die "IGNORED ",as_hex($data);
		}
	});
	warn "## write_afi ", dump( $tag, $afi );
	return $afi;
}

1

__END__

=head1 SEE ALSO

L<Biblio::RFID::Reader::API>
