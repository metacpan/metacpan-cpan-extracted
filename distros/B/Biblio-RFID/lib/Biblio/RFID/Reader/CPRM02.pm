package Biblio::RFID::Reader::CPRM02;

=head1 NAME

Biblio::RFID::Reader::CPRM02 - support for CPR-M02 RFID reader

=head1 DESCRIPTION

This module implements serial protocol over usb/serial adapter with CPR-M02
reader as described in document C<H20800-16e-ID-B.pdf>

=cut

use warnings;
use strict;

use base 'Biblio::RFID::Reader::Serial';
use Biblio::RFID;

use Time::HiRes;
use Data::Dump qw(dump);

my $debug = 1;

sub serial_settings {{
	device    => "/dev/ttyUSB0",
	baudrate  => "38400",
	databits  => "8",
	parity	  => "even",
	stopbits  => "1",
	handshake => "none",
}}

sub cpr_m02_checksum {
	my $data = shift;

	my $preset = 0xffff;
	my $polynom = 0x8408;

	my $crc = $preset;
	foreach my $i ( 0 .. length($data) - 1 ) {
		$crc ^= ord(substr($data,$i,1));
		for my $j ( 0 .. 7 ) {
			if ( $crc & 0x0001 ) {
				$crc = ( $crc >> 1 ) ^ $polynom;
			} else {
				$crc = $crc >> 1;
			}
		}
#		warn sprintf('%d %04x', $i, $crc & 0xffff);
	}

	return pack('v', $crc);
}

sub wait_device {
	Time::HiRes::sleep 0.010;
}

our $port;

sub cpr {
	my ( $hex, $description, $coderef ) = @_;
	my $bytes = hex2bytes($hex);
	my $len = pack( 'c', length( $bytes ) + 3 );
	my $send = $len . $bytes;
	my $checksum = cpr_m02_checksum($send);
	$send .= $checksum;

	warn "##>> ", as_hex( $send ), "\t\t[$description]\n";
	$port->write( $send );

	wait_device;

	my $r_len = $port->read(1);

	my $count = 100;
	while ( ! $r_len ) {
		if ( $count-- == 0 ) {
			warn "no response from device";
			return;
		}
		wait_device;
		$r_len = $port->read(1);
	}

	wait_device;

	my $data_len = ord($r_len) - 1;
	my $data = $port->read( $data_len );
	warn "##<< ", as_hex( $r_len . $data ),"\n";

	wait_device;

	$coderef->( $data ) if $coderef;

}

# FF = COM-ADDR any

sub init {
	my $self = shift;

	$port = $self->port;

cpr( 'FF  52 00',	'Boud Rate Detection' );

cpr( 'FF  65',		'Get Software Version' );

cpr( 'FF  66 00',	'Get Reader Info - General hard and firware' );

cpr( 'FF  69',		'RF Reset' );

	return 1;
}


sub inventory {

	my @tags;

cpr( 'FF  B0  01 00', 'ISO - Inventory', sub {
	my $data = shift;
	if (length($data) < 5 + 2 ) {
		warn "# no tags in range\n";
		return;
	}

	my $data_sets = ord(substr($data,3,1));
	$data = substr($data,4);
	foreach ( 1 .. $data_sets ) {
		my $tr_type = substr($data,0,1);
		die "FIXME only TR-TYPE=3 ISO 15693 supported" unless $tr_type eq "\x03";
		my $dsfid   = substr($data,1,1);
		my $uid     = substr($data,2,8);
		$data = substr($data,10);
		warn "# TAG $_ ",as_hex( $tr_type, $dsfid, $uid ),$/;
		push @tags, hex_tag $uid;
		
	}
});

	warn "# tags ",dump(@tags),$/;
	return @tags;
}


sub _get_system_info {
	my $tag = shift;

	my $info;

	cpr( "FF  B0 2B  01  $tag", "Get System Information $tag", sub {
		my $data = shift;

		warn "# data ",as_hex($data);

		return if length($data) < 17;

		$info = {
			DSFID    => substr($data,5-2,1),
			UID      => substr($data,6-2,8),
			AFI      => substr($data,14-2,1),
			MEM      => substr($data,15-2,1),
			SIZE     => substr($data,16-2,1),
			IC_REF   => substr($data,17-2,1),
		};

	});

	warn "# _get_system_info $tag ",dump( $info );

	return $info;
}


sub read_blocks {
	my $tag = shift;
	$tag = shift if ref $tag;

	my $info = _get_system_info $tag;

	return unless $info->{SIZE};

	my $max_block = ord($info->{SIZE});

	my $tag_blocks;

	my $block = 0;
	while ( $block < $max_block ) {
		cpr( sprintf("FF  B0 23  01  $tag %02x 04", $block), "Read Multiple Blocks $block", sub {
			my $data = shift;

			my $DB_N    = ord substr($data,5-2,1);
			my $DB_SIZE = ord substr($data,6-2,1);

			$data = substr($data,7-2,-2);
#			warn "# DB N: $DB_N SIZE: $DB_SIZE ", as_hex( $data ), " transponder_data: [$transponder_data] ",length($transponder_data),"\n";
			foreach my $n ( 1 .. $DB_N ) {
				my $sec = ord(substr($data,0,1));
				my $db  = substr($data,1,$DB_SIZE);
				warn "## block $n ",dump( $sec, $db ) if $debug;
				$tag_blocks->{$tag}->[$block+$n-1] = reverse split(//,$db);
				$data = substr($data, $DB_SIZE + 1);
			}
		});
		$block += 4;
	}

	warn "# tag_blocks ",dump($tag_blocks),$/;
	return $tag_blocks;
}


sub write_blocks {
	my $tag = shift;
	$tag = shift if ref $tag;

	my $data = shift;
	$data = join('', @$data) if ref $data eq 'ARRAY';

	my $DB_ADR  = 0; # start at first block
	my $DB_SIZE = 4; # bytes in one block FIXME this should be read from transponder and not hard-coded
	if ( my $padding = length($data) % $DB_SIZE ) {
		warn "WARNING: data block not padded to $DB_SIZE bytes";
		$data .= "\x00" x $padding;
	}
	my $DB_N    = length($data) / $DB_SIZE;

	my $send_data;
	foreach my $block ( 0 .. $DB_N ) {
		$send_data .= reverse split(//, substr( $data, $block * $DB_SIZE, $DB_SIZE ) );
	}

	cpr( sprintf("FF  B0 24  01  $tag   %02x %02x %02x  %s", $DB_ADR, $DB_N, $DB_SIZE, as_hex($send_data)), "Write Multiple Blocks $tag", sub {
		my $data = shift;
		warn dump( $data );
	});

}

sub read_afi {
	my $tag = shift;
	$tag = shift if ref $tag;

	my $info = _get_system_info $tag;
	return $info->{AFI} || warn "no AFI for $tag in ",dump($info);

}

sub write_afi {
	my $tag = shift;
	$tag = shift if ref $tag;

	my $afi = shift || die "no afi?";
	$afi = as_hex $afi;

	cpr( "FF  B0  27  01  $tag  $afi", "Write AFI $tag $afi", sub {
		my $data = shift;
		warn "## write_afi $tag got ",as_hex($data);
	});

}

1
