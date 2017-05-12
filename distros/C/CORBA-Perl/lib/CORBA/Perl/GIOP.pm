# ex: set ro:
#   This file was generated (by D:\Perl\site\bin/idl2pm). DO NOT modify it.
# From file : GIOP.idl, 9058 octets, Fri Oct 05 19:47:18 2007

use strict;
use warnings;

package main;

use CORBA::Perl::CORBA;
use Carp;

use CORBA::Perl::IOP;

#
#   begin of module CORBA::Perl::GIOP
#

package CORBA::Perl::GIOP;

use Carp;
use CORBA::Perl::CORBA;

# CORBA::Perl::GIOP::Version (struct)
sub Version__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'Version'.\n"
			unless (defined $value);
	croak "invalid struct for 'Version' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'major' in structure 'Version'.\n"
			unless (exists $value->{major});
	croak "no member 'minor' in structure 'Version'.\n"
			unless (exists $value->{minor});
	CORBA::Perl::CORBA::octet__marshal($r_buffer, $value->{major});
	CORBA::Perl::CORBA::octet__marshal($r_buffer, $value->{minor});
}

sub Version__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{major} = CORBA::Perl::CORBA::octet__demarshal($r_buffer, $r_offset, $endian);
	$value->{minor} = CORBA::Perl::CORBA::octet__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub Version__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'Version'.\n"
			unless (defined $value);
	croak "invalid struct for 'Version' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'major' in structure 'Version'.\n"
			unless (exists $value->{major});
	croak "no member 'minor' in structure 'Version'.\n"
			unless (exists $value->{minor});
	my $str = "struct Version {";
	$str .= "\n$tab  octet major = ";
	$str .= CORBA::Perl::CORBA::octet__stringify($value->{major}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  octet minor = ";
	$str .= CORBA::Perl::CORBA::octet__stringify($value->{minor}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub Version__id () {
	return "IDL:omg.org/GIOP/Version:1.0";
}

# CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet (sequence)
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

# CORBA::Perl::GIOP::Principal (typedef)
sub Principal__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'Principal'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__marshal($r_buffer, $value);
}

sub Principal__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__demarshal($r_buffer, $r_offset, $endian);
}

sub Principal__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'Principal'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__stringify($value, $tab);
}

sub Principal__id () {
	return "IDL:omg.org/GIOP/Principal:1.0";
}

# CORBA::Perl::GIOP::MsgType_1_1 (enum)
sub MsgType_1_1__marshal {
	my ($r_buffer, $value) = @_;
	if (0) {
	}
	elsif ($value eq 'Request') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 0);
	}
	elsif ($value eq 'Reply') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 1);
	}
	elsif ($value eq 'CancelRequest') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 2);
	}
	elsif ($value eq 'LocateRequest') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 3);
	}
	elsif ($value eq 'LocateReply') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 4);
	}
	elsif ($value eq 'CloseConnection') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 5);
	}
	elsif ($value eq 'MessageError') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 6);
	}
	elsif ($value eq 'Fragment') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 7);
	}
	else {
		croak "bad value for 'CORBA::Perl::GIOP::MsgType_1_1'.\n";
	}
}

sub MsgType_1_1__demarshal {
	my $value = CORBA::Perl::CORBA::unsigned_long__demarshal(@_);
	if (0) {
	}
	elsif ($value == 0) {
		return 'Request';
	}
	elsif ($value == 1) {
		return 'Reply';
	}
	elsif ($value == 2) {
		return 'CancelRequest';
	}
	elsif ($value == 3) {
		return 'LocateRequest';
	}
	elsif ($value == 4) {
		return 'LocateReply';
	}
	elsif ($value == 5) {
		return 'CloseConnection';
	}
	elsif ($value == 6) {
		return 'MessageError';
	}
	elsif ($value == 7) {
		return 'Fragment';
	}
	else {
		croak "bad value for 'CORBA::Perl::GIOP::MsgType_1_1'.\n";
	}
}

sub MsgType_1_1__stringify {
	my ($value) = @_;
	return $value;
}

sub MsgType_1_1__id () {
	return "IDL:omg.org/GIOP/MsgType_1_1:1.0";
}

sub Request () {
	return 'Request';
}
sub Reply () {
	return 'Reply';
}
sub CancelRequest () {
	return 'CancelRequest';
}
sub LocateRequest () {
	return 'LocateRequest';
}
sub LocateReply () {
	return 'LocateReply';
}
sub CloseConnection () {
	return 'CloseConnection';
}
sub MessageError () {
	return 'MessageError';
}
sub Fragment () {
	return 'Fragment';
}

# CORBA::Perl::GIOP::MsgType_1_2 (typedef)
sub MsgType_1_2__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'MsgType_1_2'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::MsgType_1_1__marshal($r_buffer, $value);
}

sub MsgType_1_2__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::MsgType_1_1__demarshal($r_buffer, $r_offset, $endian);
}

sub MsgType_1_2__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'MsgType_1_2'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::MsgType_1_1__stringify($value, $tab);
}

sub MsgType_1_2__id () {
	return "IDL:omg.org/GIOP/MsgType_1_2:1.0";
}

# CORBA::Perl::GIOP::MsgType_1_3 (typedef)
sub MsgType_1_3__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'MsgType_1_3'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::MsgType_1_1__marshal($r_buffer, $value);
}

sub MsgType_1_3__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::MsgType_1_1__demarshal($r_buffer, $r_offset, $endian);
}

sub MsgType_1_3__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'MsgType_1_3'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::MsgType_1_1__stringify($value, $tab);
}

sub MsgType_1_3__id () {
	return "IDL:omg.org/GIOP/MsgType_1_3:1.0";
}

# CORBA::Perl::GIOP::MessageHeader_1_0 (struct)
sub MessageHeader_1_0__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'MessageHeader_1_0'.\n"
			unless (defined $value);
	croak "invalid struct for 'MessageHeader_1_0' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'magic' in structure 'MessageHeader_1_0'.\n"
			unless (exists $value->{magic});
	croak "no member 'GIOP_version' in structure 'MessageHeader_1_0'.\n"
			unless (exists $value->{GIOP_version});
	croak "no member 'byte_order' in structure 'MessageHeader_1_0'.\n"
			unless (exists $value->{byte_order});
	croak "no member 'message_type' in structure 'MessageHeader_1_0'.\n"
			unless (exists $value->{message_type});
	croak "no member 'message_size' in structure 'MessageHeader_1_0'.\n"
			unless (exists $value->{message_size});
	local $_ = $value->{magic};
	croak "bad size of array 'magic'.\n"
			unless (scalar(@{$_}) == 4);
	foreach (@{$_}) {
		CORBA::Perl::CORBA::char__marshal($r_buffer, $_);
	}
	CORBA::Perl::GIOP::Version__marshal($r_buffer, $value->{GIOP_version});
	CORBA::Perl::CORBA::boolean__marshal($r_buffer, $value->{byte_order});
	CORBA::Perl::CORBA::octet__marshal($r_buffer, $value->{message_type});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{message_size});
}

sub MessageHeader_1_0__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	my @magic_array1 = ();
	for (my $idx1 = 0; $idx1 < 4; $idx1++) {
		push @magic_array1, CORBA::Perl::CORBA::char__demarshal($r_buffer, $r_offset, $endian);
	}
	$value->{magic} = \@magic_array1;
	$value->{GIOP_version} = CORBA::Perl::GIOP::Version__demarshal($r_buffer, $r_offset, $endian);
	$value->{byte_order} = CORBA::Perl::CORBA::boolean__demarshal($r_buffer, $r_offset, $endian);
	$value->{message_type} = CORBA::Perl::CORBA::octet__demarshal($r_buffer, $r_offset, $endian);
	$value->{message_size} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub MessageHeader_1_0__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'MessageHeader_1_0'.\n"
			unless (defined $value);
	croak "invalid struct for 'MessageHeader_1_0' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'magic' in structure 'MessageHeader_1_0'.\n"
			unless (exists $value->{magic});
	croak "no member 'GIOP_version' in structure 'MessageHeader_1_0'.\n"
			unless (exists $value->{GIOP_version});
	croak "no member 'byte_order' in structure 'MessageHeader_1_0'.\n"
			unless (exists $value->{byte_order});
	croak "no member 'message_type' in structure 'MessageHeader_1_0'.\n"
			unless (exists $value->{message_type});
	croak "no member 'message_size' in structure 'MessageHeader_1_0'.\n"
			unless (exists $value->{message_size});
	my $str = "struct MessageHeader_1_0 {";
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
	$str .= "\n$tab  Version GIOP_version = ";
	$str .= CORBA::Perl::GIOP::Version__stringify($value->{GIOP_version}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  boolean byte_order = ";
	$str .= CORBA::Perl::CORBA::boolean__stringify($value->{byte_order}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  octet message_type = ";
	$str .= CORBA::Perl::CORBA::octet__stringify($value->{message_type}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  unsigned_long message_size = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{message_size}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub MessageHeader_1_0__id () {
	return "IDL:omg.org/GIOP/MessageHeader_1_0:1.0";
}

# CORBA::Perl::GIOP::MessageHeader_1_1 (struct)
sub MessageHeader_1_1__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'MessageHeader_1_1'.\n"
			unless (defined $value);
	croak "invalid struct for 'MessageHeader_1_1' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'magic' in structure 'MessageHeader_1_1'.\n"
			unless (exists $value->{magic});
	croak "no member 'GIOP_version' in structure 'MessageHeader_1_1'.\n"
			unless (exists $value->{GIOP_version});
	croak "no member 'flags' in structure 'MessageHeader_1_1'.\n"
			unless (exists $value->{flags});
	croak "no member 'message_type' in structure 'MessageHeader_1_1'.\n"
			unless (exists $value->{message_type});
	croak "no member 'message_size' in structure 'MessageHeader_1_1'.\n"
			unless (exists $value->{message_size});
	local $_ = $value->{magic};
	croak "bad size of array 'magic'.\n"
			unless (scalar(@{$_}) == 4);
	foreach (@{$_}) {
		CORBA::Perl::CORBA::char__marshal($r_buffer, $_);
	}
	CORBA::Perl::GIOP::Version__marshal($r_buffer, $value->{GIOP_version});
	CORBA::Perl::CORBA::octet__marshal($r_buffer, $value->{flags});
	CORBA::Perl::CORBA::octet__marshal($r_buffer, $value->{message_type});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{message_size});
}

sub MessageHeader_1_1__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	my @magic_array1 = ();
	for (my $idx1 = 0; $idx1 < 4; $idx1++) {
		push @magic_array1, CORBA::Perl::CORBA::char__demarshal($r_buffer, $r_offset, $endian);
	}
	$value->{magic} = \@magic_array1;
	$value->{GIOP_version} = CORBA::Perl::GIOP::Version__demarshal($r_buffer, $r_offset, $endian);
	$value->{flags} = CORBA::Perl::CORBA::octet__demarshal($r_buffer, $r_offset, $endian);
	$value->{message_type} = CORBA::Perl::CORBA::octet__demarshal($r_buffer, $r_offset, $endian);
	$value->{message_size} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub MessageHeader_1_1__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'MessageHeader_1_1'.\n"
			unless (defined $value);
	croak "invalid struct for 'MessageHeader_1_1' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'magic' in structure 'MessageHeader_1_1'.\n"
			unless (exists $value->{magic});
	croak "no member 'GIOP_version' in structure 'MessageHeader_1_1'.\n"
			unless (exists $value->{GIOP_version});
	croak "no member 'flags' in structure 'MessageHeader_1_1'.\n"
			unless (exists $value->{flags});
	croak "no member 'message_type' in structure 'MessageHeader_1_1'.\n"
			unless (exists $value->{message_type});
	croak "no member 'message_size' in structure 'MessageHeader_1_1'.\n"
			unless (exists $value->{message_size});
	my $str = "struct MessageHeader_1_1 {";
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
	$str .= "\n$tab  Version GIOP_version = ";
	$str .= CORBA::Perl::GIOP::Version__stringify($value->{GIOP_version}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  octet flags = ";
	$str .= CORBA::Perl::CORBA::octet__stringify($value->{flags}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  octet message_type = ";
	$str .= CORBA::Perl::CORBA::octet__stringify($value->{message_type}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  unsigned_long message_size = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{message_size}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub MessageHeader_1_1__id () {
	return "IDL:omg.org/GIOP/MessageHeader_1_1:1.0";
}

# CORBA::Perl::GIOP::MessageHeader_1_2 (typedef)
sub MessageHeader_1_2__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'MessageHeader_1_2'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::MessageHeader_1_1__marshal($r_buffer, $value);
}

sub MessageHeader_1_2__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::MessageHeader_1_1__demarshal($r_buffer, $r_offset, $endian);
}

sub MessageHeader_1_2__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'MessageHeader_1_2'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::MessageHeader_1_1__stringify($value, $tab);
}

sub MessageHeader_1_2__id () {
	return "IDL:omg.org/GIOP/MessageHeader_1_2:1.0";
}

# CORBA::Perl::GIOP::MessageHeader_1_3 (typedef)
sub MessageHeader_1_3__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'MessageHeader_1_3'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::MessageHeader_1_1__marshal($r_buffer, $value);
}

sub MessageHeader_1_3__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::MessageHeader_1_1__demarshal($r_buffer, $r_offset, $endian);
}

sub MessageHeader_1_3__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'MessageHeader_1_3'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::MessageHeader_1_1__stringify($value, $tab);
}

sub MessageHeader_1_3__id () {
	return "IDL:omg.org/GIOP/MessageHeader_1_3:1.0";
}

# CORBA::Perl::GIOP::RequestHeader_1_0 (struct)
sub RequestHeader_1_0__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'RequestHeader_1_0'.\n"
			unless (defined $value);
	croak "invalid struct for 'RequestHeader_1_0' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'service_context' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{service_context});
	croak "no member 'request_id' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{request_id});
	croak "no member 'response_expected' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{response_expected});
	croak "no member 'object_key' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{object_key});
	croak "no member 'operation' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{operation});
	croak "no member 'requesting_principal' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{requesting_principal});
	CORBA::Perl::IOP::ServiceContextList__marshal($r_buffer, $value->{service_context});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{request_id});
	CORBA::Perl::CORBA::boolean__marshal($r_buffer, $value->{response_expected});
	CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__marshal($r_buffer, $value->{object_key});
	CORBA::Perl::CORBA::string__marshal($r_buffer, $value->{operation});
	CORBA::Perl::GIOP::Principal__marshal($r_buffer, $value->{requesting_principal});
}

sub RequestHeader_1_0__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{service_context} = CORBA::Perl::IOP::ServiceContextList__demarshal($r_buffer, $r_offset, $endian);
	$value->{request_id} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	$value->{response_expected} = CORBA::Perl::CORBA::boolean__demarshal($r_buffer, $r_offset, $endian);
	$value->{object_key} = CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__demarshal($r_buffer, $r_offset, $endian);
	$value->{operation} = CORBA::Perl::CORBA::string__demarshal($r_buffer, $r_offset, $endian);
	$value->{requesting_principal} = CORBA::Perl::GIOP::Principal__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub RequestHeader_1_0__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'RequestHeader_1_0'.\n"
			unless (defined $value);
	croak "invalid struct for 'RequestHeader_1_0' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'service_context' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{service_context});
	croak "no member 'request_id' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{request_id});
	croak "no member 'response_expected' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{response_expected});
	croak "no member 'object_key' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{object_key});
	croak "no member 'operation' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{operation});
	croak "no member 'requesting_principal' in structure 'RequestHeader_1_0'.\n"
			unless (exists $value->{requesting_principal});
	my $str = "struct RequestHeader_1_0 {";
	$str .= "\n$tab  ServiceContextList service_context = ";
	$str .= CORBA::Perl::IOP::ServiceContextList__stringify($value->{service_context}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  unsigned_long request_id = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{request_id}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  boolean response_expected = ";
	$str .= CORBA::Perl::CORBA::boolean__stringify($value->{response_expected}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  sequence_CORBA_Perl_CORBA_octet object_key = ";
	$str .= CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__stringify($value->{object_key}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  string operation = ";
	$str .= CORBA::Perl::CORBA::string__stringify($value->{operation}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  Principal requesting_principal = ";
	$str .= CORBA::Perl::GIOP::Principal__stringify($value->{requesting_principal}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub RequestHeader_1_0__id () {
	return "IDL:omg.org/GIOP/RequestHeader_1_0:1.0";
}

# CORBA::Perl::GIOP::RequestHeader_1_1 (struct)
sub RequestHeader_1_1__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'RequestHeader_1_1'.\n"
			unless (defined $value);
	croak "invalid struct for 'RequestHeader_1_1' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'service_context' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{service_context});
	croak "no member 'request_id' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{request_id});
	croak "no member 'response_expected' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{response_expected});
	croak "no member 'reserved' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{reserved});
	croak "no member 'object_key' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{object_key});
	croak "no member 'operation' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{operation});
	croak "no member 'requesting_principal' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{requesting_principal});
	CORBA::Perl::IOP::ServiceContextList__marshal($r_buffer, $value->{service_context});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{request_id});
	CORBA::Perl::CORBA::boolean__marshal($r_buffer, $value->{response_expected});
	local $_ = $value->{reserved};
	croak "bad size of array 'reserved'.\n"
			unless (scalar(@{$_}) == 3);
	foreach (@{$_}) {
		CORBA::Perl::CORBA::octet__marshal($r_buffer, $_);
	}
	CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__marshal($r_buffer, $value->{object_key});
	CORBA::Perl::CORBA::string__marshal($r_buffer, $value->{operation});
	CORBA::Perl::GIOP::Principal__marshal($r_buffer, $value->{requesting_principal});
}

sub RequestHeader_1_1__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{service_context} = CORBA::Perl::IOP::ServiceContextList__demarshal($r_buffer, $r_offset, $endian);
	$value->{request_id} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	$value->{response_expected} = CORBA::Perl::CORBA::boolean__demarshal($r_buffer, $r_offset, $endian);
	my @reserved_array1 = ();
	for (my $idx1 = 0; $idx1 < 3; $idx1++) {
		push @reserved_array1, CORBA::Perl::CORBA::octet__demarshal($r_buffer, $r_offset, $endian);
	}
	$value->{reserved} = \@reserved_array1;
	$value->{object_key} = CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__demarshal($r_buffer, $r_offset, $endian);
	$value->{operation} = CORBA::Perl::CORBA::string__demarshal($r_buffer, $r_offset, $endian);
	$value->{requesting_principal} = CORBA::Perl::GIOP::Principal__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub RequestHeader_1_1__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'RequestHeader_1_1'.\n"
			unless (defined $value);
	croak "invalid struct for 'RequestHeader_1_1' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'service_context' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{service_context});
	croak "no member 'request_id' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{request_id});
	croak "no member 'response_expected' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{response_expected});
	croak "no member 'reserved' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{reserved});
	croak "no member 'object_key' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{object_key});
	croak "no member 'operation' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{operation});
	croak "no member 'requesting_principal' in structure 'RequestHeader_1_1'.\n"
			unless (exists $value->{requesting_principal});
	my $str = "struct RequestHeader_1_1 {";
	$str .= "\n$tab  ServiceContextList service_context = ";
	$str .= CORBA::Perl::IOP::ServiceContextList__stringify($value->{service_context}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  unsigned_long request_id = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{request_id}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  boolean response_expected = ";
	$str .= CORBA::Perl::CORBA::boolean__stringify($value->{response_expected}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  octet[] reserved = ";
	local $_ = $value->{reserved};
	croak "bad size of array 'reserved'.\n"
			unless (scalar(@{$_}) == 3);
	$str .= "{";
	my $first1 = 1;
	foreach (@{$_}) {
		if ($first1) {
			$first1 = 0;
		}
		else {
			$str .= ",";
		}
		$str .= CORBA::Perl::CORBA::octet__stringify($_, $tab . "  ");
	}
	$str .= "}";
	$str .= ',';
	$str .= "\n$tab  sequence_CORBA_Perl_CORBA_octet object_key = ";
	$str .= CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__stringify($value->{object_key}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  string operation = ";
	$str .= CORBA::Perl::CORBA::string__stringify($value->{operation}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  Principal requesting_principal = ";
	$str .= CORBA::Perl::GIOP::Principal__stringify($value->{requesting_principal}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub RequestHeader_1_1__id () {
	return "IDL:omg.org/GIOP/RequestHeader_1_1:1.0";
}

# CORBA::Perl::GIOP::AddressingDisposition (typedef)
sub AddressingDisposition__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'AddressingDisposition'.\n"
			unless (defined $value);
	CORBA::Perl::CORBA::short__marshal($r_buffer, $value);
}

sub AddressingDisposition__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::CORBA::short__demarshal($r_buffer, $r_offset, $endian);
}

sub AddressingDisposition__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'AddressingDisposition'.\n"
			unless (defined $value);
	return CORBA::Perl::CORBA::short__stringify($value, $tab);
}

sub AddressingDisposition__id () {
	return "IDL:omg.org/GIOP/AddressingDisposition:1.0";
}

# CORBA::Perl::GIOP::KeyAddr
sub KeyAddr () {
	return 0;
}

# CORBA::Perl::GIOP::ProfileAddr
sub ProfileAddr () {
	return 1;
}

# CORBA::Perl::GIOP::ReferenceAddr
sub ReferenceAddr () {
	return 2;
}

# CORBA::Perl::GIOP::IORAddressingInfo (struct)
sub IORAddressingInfo__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'IORAddressingInfo'.\n"
			unless (defined $value);
	croak "invalid struct for 'IORAddressingInfo' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'selected_profile_index' in structure 'IORAddressingInfo'.\n"
			unless (exists $value->{selected_profile_index});
	croak "no member 'ior' in structure 'IORAddressingInfo'.\n"
			unless (exists $value->{ior});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{selected_profile_index});
	CORBA::Perl::IOP::IOR__marshal($r_buffer, $value->{ior});
}

sub IORAddressingInfo__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{selected_profile_index} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	$value->{ior} = CORBA::Perl::IOP::IOR__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub IORAddressingInfo__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'IORAddressingInfo'.\n"
			unless (defined $value);
	croak "invalid struct for 'IORAddressingInfo' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'selected_profile_index' in structure 'IORAddressingInfo'.\n"
			unless (exists $value->{selected_profile_index});
	croak "no member 'ior' in structure 'IORAddressingInfo'.\n"
			unless (exists $value->{ior});
	my $str = "struct IORAddressingInfo {";
	$str .= "\n$tab  unsigned_long selected_profile_index = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{selected_profile_index}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  IOR ior = ";
	$str .= CORBA::Perl::IOP::IOR__stringify($value->{ior}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub IORAddressingInfo__id () {
	return "IDL:omg.org/GIOP/IORAddressingInfo:1.0";
}

# CORBA::Perl::GIOP::TargetAddress (union)
sub TargetAddress__marshal {
	my ($r_buffer, $union) = @_;
	croak "undefined value for 'TargetAddress'.\n"
			unless (defined $union);
	croak "invalid union for 'TargetAddress' (not a ARRAY reference).\n"
			unless (ref $union eq 'ARRAY');
	croak "invalid union 'TargetAddress'.\n"
			unless (scalar(@{$union}) == 2);
	my $d = ${$union}[0];
	my $value = ${$union}[1];
	CORBA::Perl::GIOP::AddressingDisposition__marshal($r_buffer,$d);
	if (0) {
		# empty
	}
	elsif ($d == CORBA::Perl::GIOP::KeyAddr()) {
		CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__marshal($r_buffer, $value);
	}
	elsif ($d == CORBA::Perl::GIOP::ProfileAddr()) {
		CORBA::Perl::IOP::TaggedProfile__marshal($r_buffer, $value);
	}
	elsif ($d == CORBA::Perl::GIOP::ReferenceAddr()) {
		CORBA::Perl::GIOP::IORAddressingInfo__marshal($r_buffer, $value);
	}
	else {
		croak "invalid discriminator ($d) for 'TargetAddress'.\n";
	}
}

sub TargetAddress__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = undef;
	my $d = CORBA::Perl::GIOP::AddressingDisposition__demarshal($r_buffer,$r_offset,$endian);
	if (0) {
		# empty
	}
	elsif ($d == CORBA::Perl::GIOP::KeyAddr()) {
		$value = CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__demarshal($r_buffer, $r_offset, $endian);
	}
	elsif ($d == CORBA::Perl::GIOP::ProfileAddr()) {
		$value = CORBA::Perl::IOP::TaggedProfile__demarshal($r_buffer, $r_offset, $endian);
	}
	elsif ($d == CORBA::Perl::GIOP::ReferenceAddr()) {
		$value = CORBA::Perl::GIOP::IORAddressingInfo__demarshal($r_buffer, $r_offset, $endian);
	}
	else {
		croak "invalid discriminator ($d) for 'TargetAddress'.\n";
	}
	return [$d, $value];
}

sub TargetAddress__stringify {
	my ($union, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'TargetAddress'.\n"
			unless (defined $union);
	croak "invalid union for 'TargetAddress' (not a ARRAY reference).\n"
			unless (ref $union eq 'ARRAY');
	croak "invalid union 'TargetAddress'.\n"
			unless (scalar(@{$union}) == 2);
	my $d = ${$union}[0];
	my $value = ${$union}[1];
	my $str = "union TargetAddress {";
	if (0) {
		# empty
	}
	elsif ($d == CORBA::Perl::GIOP::KeyAddr()) {
		$str .= "\n$tab  sequence_CORBA_Perl_CORBA_octet object_key = ";
		$str .= CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__stringify($value, $tab . "  ");
	}
	elsif ($d == CORBA::Perl::GIOP::ProfileAddr()) {
		$str .= "\n$tab  TaggedProfile profile = ";
		$str .= CORBA::Perl::IOP::TaggedProfile__stringify($value, $tab . "  ");
	}
	elsif ($d == CORBA::Perl::GIOP::ReferenceAddr()) {
		$str .= "\n$tab  IORAddressingInfo ior = ";
		$str .= CORBA::Perl::GIOP::IORAddressingInfo__stringify($value, $tab . "  ");
	}
	else {
		croak "invalid discriminator ($d) for 'TargetAddress'.\n";
	}
	$str .= "\n$tab}";
	return $str;
}

sub TargetAddress__id () {
	return "IDL:omg.org/GIOP/TargetAddress:1.0";
}

# CORBA::Perl::GIOP::RequestHeader_1_2 (struct)
sub RequestHeader_1_2__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'RequestHeader_1_2'.\n"
			unless (defined $value);
	croak "invalid struct for 'RequestHeader_1_2' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{request_id});
	croak "no member 'response_flags' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{response_flags});
	croak "no member 'reserved' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{reserved});
	croak "no member 'target' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{target});
	croak "no member 'operation' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{operation});
	croak "no member 'service_context' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{service_context});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{request_id});
	CORBA::Perl::CORBA::octet__marshal($r_buffer, $value->{response_flags});
	local $_ = $value->{reserved};
	croak "bad size of array 'reserved'.\n"
			unless (scalar(@{$_}) == 3);
	foreach (@{$_}) {
		CORBA::Perl::CORBA::octet__marshal($r_buffer, $_);
	}
	CORBA::Perl::GIOP::TargetAddress__marshal($r_buffer, $value->{target});
	CORBA::Perl::CORBA::string__marshal($r_buffer, $value->{operation});
	CORBA::Perl::IOP::ServiceContextList__marshal($r_buffer, $value->{service_context});
}

sub RequestHeader_1_2__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{request_id} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	$value->{response_flags} = CORBA::Perl::CORBA::octet__demarshal($r_buffer, $r_offset, $endian);
	my @reserved_array1 = ();
	for (my $idx1 = 0; $idx1 < 3; $idx1++) {
		push @reserved_array1, CORBA::Perl::CORBA::octet__demarshal($r_buffer, $r_offset, $endian);
	}
	$value->{reserved} = \@reserved_array1;
	$value->{target} = CORBA::Perl::GIOP::TargetAddress__demarshal($r_buffer, $r_offset, $endian);
	$value->{operation} = CORBA::Perl::CORBA::string__demarshal($r_buffer, $r_offset, $endian);
	$value->{service_context} = CORBA::Perl::IOP::ServiceContextList__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub RequestHeader_1_2__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'RequestHeader_1_2'.\n"
			unless (defined $value);
	croak "invalid struct for 'RequestHeader_1_2' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{request_id});
	croak "no member 'response_flags' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{response_flags});
	croak "no member 'reserved' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{reserved});
	croak "no member 'target' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{target});
	croak "no member 'operation' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{operation});
	croak "no member 'service_context' in structure 'RequestHeader_1_2'.\n"
			unless (exists $value->{service_context});
	my $str = "struct RequestHeader_1_2 {";
	$str .= "\n$tab  unsigned_long request_id = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{request_id}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  octet response_flags = ";
	$str .= CORBA::Perl::CORBA::octet__stringify($value->{response_flags}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  octet[] reserved = ";
	local $_ = $value->{reserved};
	croak "bad size of array 'reserved'.\n"
			unless (scalar(@{$_}) == 3);
	$str .= "{";
	my $first1 = 1;
	foreach (@{$_}) {
		if ($first1) {
			$first1 = 0;
		}
		else {
			$str .= ",";
		}
		$str .= CORBA::Perl::CORBA::octet__stringify($_, $tab . "  ");
	}
	$str .= "}";
	$str .= ',';
	$str .= "\n$tab  TargetAddress target = ";
	$str .= CORBA::Perl::GIOP::TargetAddress__stringify($value->{target}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  string operation = ";
	$str .= CORBA::Perl::CORBA::string__stringify($value->{operation}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  ServiceContextList service_context = ";
	$str .= CORBA::Perl::IOP::ServiceContextList__stringify($value->{service_context}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub RequestHeader_1_2__id () {
	return "IDL:omg.org/GIOP/RequestHeader_1_2:1.0";
}

# CORBA::Perl::GIOP::RequestHeader_1_3 (typedef)
sub RequestHeader_1_3__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'RequestHeader_1_3'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::RequestHeader_1_2__marshal($r_buffer, $value);
}

sub RequestHeader_1_3__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::RequestHeader_1_2__demarshal($r_buffer, $r_offset, $endian);
}

sub RequestHeader_1_3__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'RequestHeader_1_3'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::RequestHeader_1_2__stringify($value, $tab);
}

sub RequestHeader_1_3__id () {
	return "IDL:omg.org/GIOP/RequestHeader_1_3:1.0";
}

# CORBA::Perl::GIOP::ReplyStatusType_1_2 (enum)
sub ReplyStatusType_1_2__marshal {
	my ($r_buffer, $value) = @_;
	if (0) {
	}
	elsif ($value eq 'NO_EXCEPTION') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 0);
	}
	elsif ($value eq 'USER_EXCEPTION') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 1);
	}
	elsif ($value eq 'SYSTEM_EXCEPTION') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 2);
	}
	elsif ($value eq 'LOCATION_FORWARD') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 3);
	}
	elsif ($value eq 'LOCATION_FORWARD_PERM') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 4);
	}
	elsif ($value eq 'NEEDS_ADDRESSING_MODE') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 5);
	}
	else {
		croak "bad value for 'CORBA::Perl::GIOP::ReplyStatusType_1_2'.\n";
	}
}

sub ReplyStatusType_1_2__demarshal {
	my $value = CORBA::Perl::CORBA::unsigned_long__demarshal(@_);
	if (0) {
	}
	elsif ($value == 0) {
		return 'NO_EXCEPTION';
	}
	elsif ($value == 1) {
		return 'USER_EXCEPTION';
	}
	elsif ($value == 2) {
		return 'SYSTEM_EXCEPTION';
	}
	elsif ($value == 3) {
		return 'LOCATION_FORWARD';
	}
	elsif ($value == 4) {
		return 'LOCATION_FORWARD_PERM';
	}
	elsif ($value == 5) {
		return 'NEEDS_ADDRESSING_MODE';
	}
	else {
		croak "bad value for 'CORBA::Perl::GIOP::ReplyStatusType_1_2'.\n";
	}
}

sub ReplyStatusType_1_2__stringify {
	my ($value) = @_;
	return $value;
}

sub ReplyStatusType_1_2__id () {
	return "IDL:omg.org/GIOP/ReplyStatusType_1_2:1.0";
}

sub NO_EXCEPTION () {
	return 'NO_EXCEPTION';
}
sub USER_EXCEPTION () {
	return 'USER_EXCEPTION';
}
sub SYSTEM_EXCEPTION () {
	return 'SYSTEM_EXCEPTION';
}
sub LOCATION_FORWARD () {
	return 'LOCATION_FORWARD';
}
sub LOCATION_FORWARD_PERM () {
	return 'LOCATION_FORWARD_PERM';
}
sub NEEDS_ADDRESSING_MODE () {
	return 'NEEDS_ADDRESSING_MODE';
}

# CORBA::Perl::GIOP::ReplyHeader_1_2 (struct)
sub ReplyHeader_1_2__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'ReplyHeader_1_2'.\n"
			unless (defined $value);
	croak "invalid struct for 'ReplyHeader_1_2' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'ReplyHeader_1_2'.\n"
			unless (exists $value->{request_id});
	croak "no member 'reply_status' in structure 'ReplyHeader_1_2'.\n"
			unless (exists $value->{reply_status});
	croak "no member 'service_context' in structure 'ReplyHeader_1_2'.\n"
			unless (exists $value->{service_context});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{request_id});
	CORBA::Perl::GIOP::ReplyStatusType_1_2__marshal($r_buffer, $value->{reply_status});
	CORBA::Perl::IOP::ServiceContextList__marshal($r_buffer, $value->{service_context});
}

sub ReplyHeader_1_2__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{request_id} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	$value->{reply_status} = CORBA::Perl::GIOP::ReplyStatusType_1_2__demarshal($r_buffer, $r_offset, $endian);
	$value->{service_context} = CORBA::Perl::IOP::ServiceContextList__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub ReplyHeader_1_2__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'ReplyHeader_1_2'.\n"
			unless (defined $value);
	croak "invalid struct for 'ReplyHeader_1_2' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'ReplyHeader_1_2'.\n"
			unless (exists $value->{request_id});
	croak "no member 'reply_status' in structure 'ReplyHeader_1_2'.\n"
			unless (exists $value->{reply_status});
	croak "no member 'service_context' in structure 'ReplyHeader_1_2'.\n"
			unless (exists $value->{service_context});
	my $str = "struct ReplyHeader_1_2 {";
	$str .= "\n$tab  unsigned_long request_id = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{request_id}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  ReplyStatusType_1_2 reply_status = ";
	$str .= CORBA::Perl::GIOP::ReplyStatusType_1_2__stringify($value->{reply_status}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  ServiceContextList service_context = ";
	$str .= CORBA::Perl::IOP::ServiceContextList__stringify($value->{service_context}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub ReplyHeader_1_2__id () {
	return "IDL:omg.org/GIOP/ReplyHeader_1_2:1.0";
}

# CORBA::Perl::GIOP::ReplyHeader_1_3 (typedef)
sub ReplyHeader_1_3__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'ReplyHeader_1_3'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::ReplyHeader_1_2__marshal($r_buffer, $value);
}

sub ReplyHeader_1_3__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::ReplyHeader_1_2__demarshal($r_buffer, $r_offset, $endian);
}

sub ReplyHeader_1_3__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'ReplyHeader_1_3'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::ReplyHeader_1_2__stringify($value, $tab);
}

sub ReplyHeader_1_3__id () {
	return "IDL:omg.org/GIOP/ReplyHeader_1_3:1.0";
}

# CORBA::Perl::GIOP::SystemExceptionReplyBody (struct)
sub SystemExceptionReplyBody__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'SystemExceptionReplyBody'.\n"
			unless (defined $value);
	croak "invalid struct for 'SystemExceptionReplyBody' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'exception_id' in structure 'SystemExceptionReplyBody'.\n"
			unless (exists $value->{exception_id});
	croak "no member 'minor_code_value' in structure 'SystemExceptionReplyBody'.\n"
			unless (exists $value->{minor_code_value});
	croak "no member 'completion_status' in structure 'SystemExceptionReplyBody'.\n"
			unless (exists $value->{completion_status});
	CORBA::Perl::CORBA::string__marshal($r_buffer, $value->{exception_id});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{minor_code_value});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{completion_status});
}

sub SystemExceptionReplyBody__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{exception_id} = CORBA::Perl::CORBA::string__demarshal($r_buffer, $r_offset, $endian);
	$value->{minor_code_value} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	$value->{completion_status} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub SystemExceptionReplyBody__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'SystemExceptionReplyBody'.\n"
			unless (defined $value);
	croak "invalid struct for 'SystemExceptionReplyBody' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'exception_id' in structure 'SystemExceptionReplyBody'.\n"
			unless (exists $value->{exception_id});
	croak "no member 'minor_code_value' in structure 'SystemExceptionReplyBody'.\n"
			unless (exists $value->{minor_code_value});
	croak "no member 'completion_status' in structure 'SystemExceptionReplyBody'.\n"
			unless (exists $value->{completion_status});
	my $str = "struct SystemExceptionReplyBody {";
	$str .= "\n$tab  string exception_id = ";
	$str .= CORBA::Perl::CORBA::string__stringify($value->{exception_id}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  unsigned_long minor_code_value = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{minor_code_value}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  unsigned_long completion_status = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{completion_status}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub SystemExceptionReplyBody__id () {
	return "IDL:omg.org/GIOP/SystemExceptionReplyBody:1.0";
}

# CORBA::Perl::GIOP::CancelRequestHeader (struct)
sub CancelRequestHeader__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'CancelRequestHeader'.\n"
			unless (defined $value);
	croak "invalid struct for 'CancelRequestHeader' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'CancelRequestHeader'.\n"
			unless (exists $value->{request_id});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{request_id});
}

sub CancelRequestHeader__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{request_id} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub CancelRequestHeader__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'CancelRequestHeader'.\n"
			unless (defined $value);
	croak "invalid struct for 'CancelRequestHeader' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'CancelRequestHeader'.\n"
			unless (exists $value->{request_id});
	my $str = "struct CancelRequestHeader {";
	$str .= "\n$tab  unsigned_long request_id = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{request_id}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub CancelRequestHeader__id () {
	return "IDL:omg.org/GIOP/CancelRequestHeader:1.0";
}

# CORBA::Perl::GIOP::LocateRequestHeader_1_0 (struct)
sub LocateRequestHeader_1_0__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'LocateRequestHeader_1_0'.\n"
			unless (defined $value);
	croak "invalid struct for 'LocateRequestHeader_1_0' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'LocateRequestHeader_1_0'.\n"
			unless (exists $value->{request_id});
	croak "no member 'object_key' in structure 'LocateRequestHeader_1_0'.\n"
			unless (exists $value->{object_key});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{request_id});
	CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__marshal($r_buffer, $value->{object_key});
}

sub LocateRequestHeader_1_0__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{request_id} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	$value->{object_key} = CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub LocateRequestHeader_1_0__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'LocateRequestHeader_1_0'.\n"
			unless (defined $value);
	croak "invalid struct for 'LocateRequestHeader_1_0' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'LocateRequestHeader_1_0'.\n"
			unless (exists $value->{request_id});
	croak "no member 'object_key' in structure 'LocateRequestHeader_1_0'.\n"
			unless (exists $value->{object_key});
	my $str = "struct LocateRequestHeader_1_0 {";
	$str .= "\n$tab  unsigned_long request_id = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{request_id}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  sequence_CORBA_Perl_CORBA_octet object_key = ";
	$str .= CORBA::Perl::GIOP::sequence_CORBA_Perl_CORBA_octet__stringify($value->{object_key}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub LocateRequestHeader_1_0__id () {
	return "IDL:omg.org/GIOP/LocateRequestHeader_1_0:1.0";
}

# CORBA::Perl::GIOP::LocateRequestHeader_1_1 (typedef)
sub LocateRequestHeader_1_1__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'LocateRequestHeader_1_1'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::LocateRequestHeader_1_0__marshal($r_buffer, $value);
}

sub LocateRequestHeader_1_1__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::LocateRequestHeader_1_0__demarshal($r_buffer, $r_offset, $endian);
}

sub LocateRequestHeader_1_1__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'LocateRequestHeader_1_1'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::LocateRequestHeader_1_0__stringify($value, $tab);
}

sub LocateRequestHeader_1_1__id () {
	return "IDL:omg.org/GIOP/LocateRequestHeader_1_1:1.0";
}

# CORBA::Perl::GIOP::LocateRequestHeader_1_2 (struct)
sub LocateRequestHeader_1_2__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'LocateRequestHeader_1_2'.\n"
			unless (defined $value);
	croak "invalid struct for 'LocateRequestHeader_1_2' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'LocateRequestHeader_1_2'.\n"
			unless (exists $value->{request_id});
	croak "no member 'target' in structure 'LocateRequestHeader_1_2'.\n"
			unless (exists $value->{target});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{request_id});
	CORBA::Perl::GIOP::TargetAddress__marshal($r_buffer, $value->{target});
}

sub LocateRequestHeader_1_2__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{request_id} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	$value->{target} = CORBA::Perl::GIOP::TargetAddress__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub LocateRequestHeader_1_2__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'LocateRequestHeader_1_2'.\n"
			unless (defined $value);
	croak "invalid struct for 'LocateRequestHeader_1_2' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'LocateRequestHeader_1_2'.\n"
			unless (exists $value->{request_id});
	croak "no member 'target' in structure 'LocateRequestHeader_1_2'.\n"
			unless (exists $value->{target});
	my $str = "struct LocateRequestHeader_1_2 {";
	$str .= "\n$tab  unsigned_long request_id = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{request_id}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  TargetAddress target = ";
	$str .= CORBA::Perl::GIOP::TargetAddress__stringify($value->{target}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub LocateRequestHeader_1_2__id () {
	return "IDL:omg.org/GIOP/LocateRequestHeader_1_2:1.0";
}

# CORBA::Perl::GIOP::LocateRequestHeader_1_3 (typedef)
sub LocateRequestHeader_1_3__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'LocateRequestHeader_1_3'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::LocateRequestHeader_1_2__marshal($r_buffer, $value);
}

sub LocateRequestHeader_1_3__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::LocateRequestHeader_1_2__demarshal($r_buffer, $r_offset, $endian);
}

sub LocateRequestHeader_1_3__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'LocateRequestHeader_1_3'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::LocateRequestHeader_1_2__stringify($value, $tab);
}

sub LocateRequestHeader_1_3__id () {
	return "IDL:omg.org/GIOP/LocateRequestHeader_1_3:1.0";
}

# CORBA::Perl::GIOP::LocateStatusType_1_2 (enum)
sub LocateStatusType_1_2__marshal {
	my ($r_buffer, $value) = @_;
	if (0) {
	}
	elsif ($value eq 'UNKNOWN_OBJECT') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 0);
	}
	elsif ($value eq 'OBJECT_HERE') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 1);
	}
	elsif ($value eq 'OBJECT_FORWARD') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 2);
	}
	elsif ($value eq 'OBJECT_FORWARD_PERM') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 3);
	}
	elsif ($value eq 'LOC_SYSTEM_EXCEPTION') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 4);
	}
	elsif ($value eq 'LOC_NEEDS_ADDRESSING_MODE') {
		CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, 5);
	}
	else {
		croak "bad value for 'CORBA::Perl::GIOP::LocateStatusType_1_2'.\n";
	}
}

sub LocateStatusType_1_2__demarshal {
	my $value = CORBA::Perl::CORBA::unsigned_long__demarshal(@_);
	if (0) {
	}
	elsif ($value == 0) {
		return 'UNKNOWN_OBJECT';
	}
	elsif ($value == 1) {
		return 'OBJECT_HERE';
	}
	elsif ($value == 2) {
		return 'OBJECT_FORWARD';
	}
	elsif ($value == 3) {
		return 'OBJECT_FORWARD_PERM';
	}
	elsif ($value == 4) {
		return 'LOC_SYSTEM_EXCEPTION';
	}
	elsif ($value == 5) {
		return 'LOC_NEEDS_ADDRESSING_MODE';
	}
	else {
		croak "bad value for 'CORBA::Perl::GIOP::LocateStatusType_1_2'.\n";
	}
}

sub LocateStatusType_1_2__stringify {
	my ($value) = @_;
	return $value;
}

sub LocateStatusType_1_2__id () {
	return "IDL:omg.org/GIOP/LocateStatusType_1_2:1.0";
}

sub UNKNOWN_OBJECT () {
	return 'UNKNOWN_OBJECT';
}
sub OBJECT_HERE () {
	return 'OBJECT_HERE';
}
sub OBJECT_FORWARD () {
	return 'OBJECT_FORWARD';
}
sub OBJECT_FORWARD_PERM () {
	return 'OBJECT_FORWARD_PERM';
}
sub LOC_SYSTEM_EXCEPTION () {
	return 'LOC_SYSTEM_EXCEPTION';
}
sub LOC_NEEDS_ADDRESSING_MODE () {
	return 'LOC_NEEDS_ADDRESSING_MODE';
}

# CORBA::Perl::GIOP::LocateReplyHeader_1_2 (struct)
sub LocateReplyHeader_1_2__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'LocateReplyHeader_1_2'.\n"
			unless (defined $value);
	croak "invalid struct for 'LocateReplyHeader_1_2' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'LocateReplyHeader_1_2'.\n"
			unless (exists $value->{request_id});
	croak "no member 'locate_status' in structure 'LocateReplyHeader_1_2'.\n"
			unless (exists $value->{locate_status});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{request_id});
	CORBA::Perl::GIOP::LocateStatusType_1_2__marshal($r_buffer, $value->{locate_status});
}

sub LocateReplyHeader_1_2__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{request_id} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	$value->{locate_status} = CORBA::Perl::GIOP::LocateStatusType_1_2__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub LocateReplyHeader_1_2__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'LocateReplyHeader_1_2'.\n"
			unless (defined $value);
	croak "invalid struct for 'LocateReplyHeader_1_2' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'LocateReplyHeader_1_2'.\n"
			unless (exists $value->{request_id});
	croak "no member 'locate_status' in structure 'LocateReplyHeader_1_2'.\n"
			unless (exists $value->{locate_status});
	my $str = "struct LocateReplyHeader_1_2 {";
	$str .= "\n$tab  unsigned_long request_id = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{request_id}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  LocateStatusType_1_2 locate_status = ";
	$str .= CORBA::Perl::GIOP::LocateStatusType_1_2__stringify($value->{locate_status}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub LocateReplyHeader_1_2__id () {
	return "IDL:omg.org/GIOP/LocateReplyHeader_1_2:1.0";
}

# CORBA::Perl::GIOP::LocateReplyHeader_1_3 (typedef)
sub LocateReplyHeader_1_3__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'LocateReplyHeader_1_3'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::LocateReplyHeader_1_2__marshal($r_buffer, $value);
}

sub LocateReplyHeader_1_3__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::LocateReplyHeader_1_2__demarshal($r_buffer, $r_offset, $endian);
}

sub LocateReplyHeader_1_3__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'LocateReplyHeader_1_3'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::LocateReplyHeader_1_2__stringify($value, $tab);
}

sub LocateReplyHeader_1_3__id () {
	return "IDL:omg.org/GIOP/LocateReplyHeader_1_3:1.0";
}

# CORBA::Perl::GIOP::FragmentHeader_1_2 (struct)
sub FragmentHeader_1_2__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'FragmentHeader_1_2'.\n"
			unless (defined $value);
	croak "invalid struct for 'FragmentHeader_1_2' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'FragmentHeader_1_2'.\n"
			unless (exists $value->{request_id});
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value->{request_id});
}

sub FragmentHeader_1_2__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{request_id} = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub FragmentHeader_1_2__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'FragmentHeader_1_2'.\n"
			unless (defined $value);
	croak "invalid struct for 'FragmentHeader_1_2' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'request_id' in structure 'FragmentHeader_1_2'.\n"
			unless (exists $value->{request_id});
	my $str = "struct FragmentHeader_1_2 {";
	$str .= "\n$tab  unsigned_long request_id = ";
	$str .= CORBA::Perl::CORBA::unsigned_long__stringify($value->{request_id}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub FragmentHeader_1_2__id () {
	return "IDL:omg.org/GIOP/FragmentHeader_1_2:1.0";
}

# CORBA::Perl::GIOP::FragmentHeader_1_3 (typedef)
sub FragmentHeader_1_3__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'FragmentHeader_1_3'.\n"
			unless (defined $value);
	CORBA::Perl::GIOP::FragmentHeader_1_2__marshal($r_buffer, $value);
}

sub FragmentHeader_1_3__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::GIOP::FragmentHeader_1_2__demarshal($r_buffer, $r_offset, $endian);
}

sub FragmentHeader_1_3__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'FragmentHeader_1_3'.\n"
			unless (defined $value);
	return CORBA::Perl::GIOP::FragmentHeader_1_2__stringify($value, $tab);
}

sub FragmentHeader_1_3__id () {
	return "IDL:omg.org/GIOP/FragmentHeader_1_3:1.0";
}


#
#   end of module CORBA::Perl::GIOP
#

package main;

1;

#   end of file : GIOP.pm

# Local variables:
#   buffer-read-only: t
# End:
