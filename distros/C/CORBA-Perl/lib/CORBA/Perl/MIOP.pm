# ex: set ro:
#   This file was generated (by D:\Perl\site\bin/idl2pm). DO NOT modify it.
# From file : MIOP.idl, 1424 octets, Fri Oct 05 19:47:18 2007

use strict;
use warnings;

package main;

use CORBA::Perl::CORBA;
use Carp;

use CORBA::Perl::IOP;

use CORBA::Perl::GIOP;

#
#   begin of module CORBA::Perl::MIOP
#

package CORBA::Perl::MIOP;

use Carp;
use CORBA::Perl::CORBA;

# CORBA::Perl::MIOP::sequence_CORBA_Perl_CORBA_octet (sequence)
sub sequence_CORBA_Perl_CORBA_octet__marshal {
	my ($r_buffer, $value, $max) = @_;
	croak "undefined value for 'sequence_CORBA_Perl_CORBA_octet'.\n"
			unless (defined $value);
	croak "value '$value' is not a string.\n"
			if (ref $value);
	my $len = length($value);
	croak "too long sequence for 'sequence_CORBA_Perl_CORBA_octet' (max:$max).\n"
			if (defined $max and $len > $max);
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $len);
	$$r_buffer .= $value;
}

sub sequence_CORBA_Perl_CORBA_octet__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $len = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	my @seq = ();
	my $str = substr $$r_buffer, $$r_offset, $len;
	$$r_offset += $len;
	return $str;
}

sub sequence_CORBA_Perl_CORBA_octet__stringify {
	my ($value, $tab, $max) = @_;
	$tab = q{} unless (defined $tab);
	croak "undefined value for 'sequence_CORBA_Perl_CORBA_octet'.\n"
			unless (defined $value);
	$value = [map ord, split //, $value];
	my $len = scalar(@{$value});
	croak "too long sequence for 'sequence_CORBA_Perl_CORBA_octet' (max:$max).\n"
			if (defined $max and $len > $max);
	my $str = '{';
	my $first = 1;
	foreach (@{$value}) {
		if ($first) {
			$first = 0;
		}
		else {
			$str .= ',';
		}
		$str .= CORBA::Perl::CORBA::octet__stringify($_, $tab . q{ } x 2);
	}
	$str .= '}';
	return $str;
}

# CORBA::Perl::MIOP::UniqueId (typedef)
sub UniqueId__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'UniqueId'.\n"
			unless (defined $value);
	CORBA::Perl::MIOP::sequence_CORBA_Perl_CORBA_octet__marshal($r_buffer, $value, 252);
}

sub UniqueId__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::MIOP::sequence_CORBA_Perl_CORBA_octet__demarshal($r_buffer, $r_offset, $endian);
}

sub UniqueId__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'UniqueId'.\n"
			unless (defined $value);
	return CORBA::Perl::MIOP::sequence_CORBA_Perl_CORBA_octet__stringify($value, $tab, 252);
}

sub UniqueId__id () {
	return "IDL:omg.org/MIOP/UniqueId:1.0";
}

# CORBA::Perl::MIOP::PacketHeader_1_0 (struct)
sub PacketHeader_1_0__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'PacketHeader_1_0'.\n"
			unless (defined $value);
	croak "invalid struct for 'PacketHeader_1_0' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'magic' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{magic});
	croak "no member 'hdr_version' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{hdr_version});
	croak "no member 'flags' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{flags});
	croak "no member 'packet_length' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{packet_length});
	croak "no member 'packet_number' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{packet_number});
	croak "no member 'number_of_packets' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{number_of_packets});
	croak "no member 'id' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{id});
	local $_ = $value->{magic};
	croak "bad size of array 'magic'.\n"
			unless (scalar(@{$_}) == 4);
	foreach (@{$_}) {
		CORBA::Perl::CORBA::char__marshal($r_buffer, $_);
	}
	CORBA::Perl::CORBA::octet__marshal($r_buffer, $value->{hdr_version});
	CORBA::Perl::CORBA::octet__marshal($r_buffer, $value->{flags});
	CORBA::Perl::CORBA::unsigned_short__marshal($r_buffer, $value->{packet_length});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{packet_number});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{number_of_packets});
	CORBA::Perl::MIOP::UniqueId__marshal($r_buffer, $value->{id});
}

sub PacketHeader_1_0__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	my @magic_array1 = ();
	for (my $idx1 = 0; $idx1 < 4; $idx1++) {
		push @magic_array1, CORBA::Perl::CORBA::char__demarshal($r_buffer, $r_offset, $endian);
	}
	$value->{magic} = \@magic_array1;
	$value->{hdr_version} = CORBA::Perl::CORBA::octet__demarshal($r_buffer, $r_offset, $endian);
	$value->{flags} = CORBA::Perl::CORBA::octet__demarshal($r_buffer, $r_offset, $endian);
	$value->{packet_length} = CORBA::Perl::CORBA::unsigned_short__demarshal($r_buffer, $r_offset, $endian);
	$value->{packet_number} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	$value->{number_of_packets} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	$value->{id} = CORBA::Perl::MIOP::UniqueId__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub PacketHeader_1_0__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'PacketHeader_1_0'.\n"
			unless (defined $value);
	croak "invalid struct for 'PacketHeader_1_0' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'magic' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{magic});
	croak "no member 'hdr_version' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{hdr_version});
	croak "no member 'flags' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{flags});
	croak "no member 'packet_length' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{packet_length});
	croak "no member 'packet_number' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{packet_number});
	croak "no member 'number_of_packets' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{number_of_packets});
	croak "no member 'id' in structure 'PacketHeader_1_0'.\n"
			unless (exists $value->{id});
	my $str = "struct PacketHeader_1_0 {";
	$str .= "\n$tab  char[] magic = ";
	local $_ = $value->{magic};
	croak "bad size of array 'magic'.\n"
			unless (scalar(@{$_}) == 4);
	$str .= "{";
	my $first1 = 1;
	foreach (@{$_}) {
		if ($first1) {
			$first1 = 0;
		}
		else {
			$str .= ",";
		}
		$str .= CORBA::Perl::CORBA::char__stringify($_, $tab . "  ");
	}
	$str .= "}";
	$str .= ',';
	$str .= "\n$tab  octet hdr_version = ";
	$str .= CORBA::Perl::CORBA::octet__stringify($value->{hdr_version}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  octet flags = ";
	$str .= CORBA::Perl::CORBA::octet__stringify($value->{flags}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  unsigned_short packet_length = ";
	$str .= CORBA::Perl::CORBA::unsigned_short__stringify($value->{packet_length}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  unsigned_long packet_number = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{packet_number}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  unsigned_long number_of_packets = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{number_of_packets}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  UniqueId id = ";
	$str .= CORBA::Perl::MIOP::UniqueId__stringify($value->{id}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub PacketHeader_1_0__id () {
	return "IDL:omg.org/MIOP/PacketHeader_1_0:1.0";
}

# CORBA::Perl::MIOP::Version (typedef)
sub Version__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'Version'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::Version__marshal($r_buffer, $value);
}

sub Version__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::Version__demarshal($r_buffer, $r_offset, $endian);
}

sub Version__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'Version'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::Version__stringify($value, $tab);
}

sub Version__id () {
	return "IDL:omg.org/MIOP/Version:1.0";
}

# CORBA::Perl::MIOP::Address (typedef)
sub Address__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'Address'.\n"
			unless (defined $value);
	CORBA::Perl::CORBA::string__marshal($r_buffer, $value);
}

sub Address__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::CORBA::string__demarshal($r_buffer, $r_offset, $endian);
}

sub Address__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'Address'.\n"
			unless (defined $value);
	return CORBA::Perl::CORBA::string__stringify($value, $tab);
}

sub Address__id () {
	return "IDL:omg.org/MIOP/Address:1.0";
}

# CORBA::Perl::MIOP::sequence_CORBA_Perl_IOP_TaggedComponent (sequence)
sub sequence_CORBA_Perl_IOP_TaggedComponent__marshal {
	my ($r_buffer, $value, $max) = @_;
	croak "undefined value for 'sequence_CORBA_Perl_IOP_TaggedComponent'.\n"
			unless (defined $value);
	my $len = scalar(@{$value});
	croak "too long sequence for 'sequence_CORBA_Perl_IOP_TaggedComponent' (max:$max).\n"
			if (defined $max and $len > $max);
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $len);
	foreach (@{$value}) {
		CORBA::Perl::IOP::TaggedComponent__marshal($r_buffer, $_);
	}
}

sub sequence_CORBA_Perl_IOP_TaggedComponent__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $len = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	my @seq = ();
	while ($len--) {
		push @seq,CORBA::Perl::IOP::TaggedComponent__demarshal($r_buffer, $r_offset, $endian);
	}
	return \@seq;
}

sub sequence_CORBA_Perl_IOP_TaggedComponent__stringify {
	my ($value, $tab, $max) = @_;
	$tab = q{} unless (defined $tab);
	croak "undefined value for 'sequence_CORBA_Perl_IOP_TaggedComponent'.\n"
			unless (defined $value);
	my $len = scalar(@{$value});
	croak "too long sequence for 'sequence_CORBA_Perl_IOP_TaggedComponent' (max:$max).\n"
			if (defined $max and $len > $max);
	my $str = '{';
	my $first = 1;
	foreach (@{$value}) {
		if ($first) {
			$first = 0;
		}
		else {
			$str .= ',';
		}
		$str .= "\n$tab  ";
		$str .= CORBA::Perl::IOP::TaggedComponent__stringify($_, $tab . q{ } x 2);
	}
	$str .= "\n$tab";
	$str .= '}';
	return $str;
}

# CORBA::Perl::MIOP::UIPMC_ProfileBody (struct)
sub UIPMC_ProfileBody__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'UIPMC_ProfileBody'.\n"
			unless (defined $value);
	croak "invalid struct for 'UIPMC_ProfileBody' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'miop_version' in structure 'UIPMC_ProfileBody'.\n"
			unless (exists $value->{miop_version});
	croak "no member 'the_address' in structure 'UIPMC_ProfileBody'.\n"
			unless (exists $value->{the_address});
	croak "no member 'the_port' in structure 'UIPMC_ProfileBody'.\n"
			unless (exists $value->{the_port});
	croak "no member 'components' in structure 'UIPMC_ProfileBody'.\n"
			unless (exists $value->{components});
	CORBA::Perl::MIOP::Version__marshal($r_buffer, $value->{miop_version});
	CORBA::Perl::MIOP::Address__marshal($r_buffer, $value->{the_address});
	CORBA::Perl::CORBA::short__marshal($r_buffer, $value->{the_port});
	CORBA::Perl::MIOP::sequence_CORBA_Perl_IOP_TaggedComponent__marshal($r_buffer, $value->{components});
}

sub UIPMC_ProfileBody__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{miop_version} = CORBA::Perl::MIOP::Version__demarshal($r_buffer, $r_offset, $endian);
	$value->{the_address} = CORBA::Perl::MIOP::Address__demarshal($r_buffer, $r_offset, $endian);
	$value->{the_port} = CORBA::Perl::CORBA::short__demarshal($r_buffer, $r_offset, $endian);
	$value->{components} = CORBA::Perl::MIOP::sequence_CORBA_Perl_IOP_TaggedComponent__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub UIPMC_ProfileBody__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'UIPMC_ProfileBody'.\n"
			unless (defined $value);
	croak "invalid struct for 'UIPMC_ProfileBody' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'miop_version' in structure 'UIPMC_ProfileBody'.\n"
			unless (exists $value->{miop_version});
	croak "no member 'the_address' in structure 'UIPMC_ProfileBody'.\n"
			unless (exists $value->{the_address});
	croak "no member 'the_port' in structure 'UIPMC_ProfileBody'.\n"
			unless (exists $value->{the_port});
	croak "no member 'components' in structure 'UIPMC_ProfileBody'.\n"
			unless (exists $value->{components});
	my $str = "struct UIPMC_ProfileBody {";
	$str .= "\n$tab  Version miop_version = ";
	$str .= CORBA::Perl::MIOP::Version__stringify($value->{miop_version}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  Address the_address = ";
	$str .= CORBA::Perl::MIOP::Address__stringify($value->{the_address}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  short the_port = ";
	$str .= CORBA::Perl::CORBA::short__stringify($value->{the_port}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  sequence_CORBA_Perl_IOP_TaggedComponent components = ";
	$str .= CORBA::Perl::MIOP::sequence_CORBA_Perl_IOP_TaggedComponent__stringify($value->{components}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub UIPMC_ProfileBody__id () {
	return "IDL:omg.org/MIOP/UIPMC_ProfileBody:1.0";
}


#
#   end of module CORBA::Perl::MIOP
#

package main;

1;

#   end of file : MIOP.pm

# Local variables:
#   buffer-read-only: t
# End:
