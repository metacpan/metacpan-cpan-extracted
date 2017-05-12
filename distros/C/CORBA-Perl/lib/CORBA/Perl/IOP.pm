# ex: set ro:
#   This file was generated (by D:\Perl\site\bin/idl2pm). DO NOT modify it.
# From file : IOP.idl, 5190 octets, Fri Oct 05 19:47:18 2007

use strict;
use warnings;

package main;

use CORBA::Perl::CORBA;
use Carp;

#
#   begin of module CORBA::Perl::IOP
#

package CORBA::Perl::IOP;

use Carp;
use CORBA::Perl::CORBA;

# CORBA::Perl::IOP::ProfileId (typedef)
sub ProfileId__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'ProfileId'.\n"
			unless (defined $value);
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value);
}

sub ProfileId__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
}

sub ProfileId__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'ProfileId'.\n"
			unless (defined $value);
	return CORBA::Perl::CORBA::unsigned_long__stringify($value, $tab);
}

sub ProfileId__id () {
	return "IDL:omg.org/IOP/ProfileId:1.0";
}

# CORBA::Perl::IOP::TAG_INTERNET_IOP
sub TAG_INTERNET_IOP () {
	return 0;
}

# CORBA::Perl::IOP::TAG_MULTIPLE_COMPONENTS
sub TAG_MULTIPLE_COMPONENTS () {
	return 1;
}

# CORBA::Perl::IOP::TAG_SCCP_IOP
sub TAG_SCCP_IOP () {
	return 2;
}

# CORBA::Perl::IOP::sequence_CORBA_Perl_CORBA_octet (sequence)
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

# CORBA::Perl::IOP::TaggedProfile (struct)
sub TaggedProfile__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'TaggedProfile'.\n"
			unless (defined $value);
	croak "invalid struct for 'TaggedProfile' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'tag' in structure 'TaggedProfile'.\n"
			unless (exists $value->{tag});
	croak "no member 'profile_data' in structure 'TaggedProfile'.\n"
			unless (exists $value->{profile_data});
	CORBA::Perl::IOP::ProfileId__marshal($r_buffer, $value->{tag});
	CORBA::Perl::IOP::sequence_CORBA_Perl_CORBA_octet__marshal($r_buffer, $value->{profile_data});
}

sub TaggedProfile__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{tag} = CORBA::Perl::IOP::ProfileId__demarshal($r_buffer, $r_offset, $endian);
	$value->{profile_data} = CORBA::Perl::IOP::sequence_CORBA_Perl_CORBA_octet__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub TaggedProfile__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'TaggedProfile'.\n"
			unless (defined $value);
	croak "invalid struct for 'TaggedProfile' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'tag' in structure 'TaggedProfile'.\n"
			unless (exists $value->{tag});
	croak "no member 'profile_data' in structure 'TaggedProfile'.\n"
			unless (exists $value->{profile_data});
	my $str = "struct TaggedProfile {";
	$str .= "\n$tab  ProfileId tag = ";
	$str .= CORBA::Perl::IOP::ProfileId__stringify($value->{tag}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  sequence_CORBA_Perl_CORBA_octet profile_data = ";
	$str .= CORBA::Perl::IOP::sequence_CORBA_Perl_CORBA_octet__stringify($value->{profile_data}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub TaggedProfile__id () {
	return "IDL:omg.org/IOP/TaggedProfile:1.0";
}

# CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_TaggedProfile (sequence)
sub sequence_CORBA_Perl_IOP_TaggedProfile__marshal {
	my ($r_buffer, $value, $max) = @_;
	croak "undefined value for 'sequence_CORBA_Perl_IOP_TaggedProfile'.\n"
			unless (defined $value);
	my $len = scalar(@{$value});
	croak "too long sequence for 'sequence_CORBA_Perl_IOP_TaggedProfile' (max:$max).\n"
			if (defined $max and $len > $max);
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $len);
	foreach (@{$value}) {
		CORBA::Perl::IOP::TaggedProfile__marshal($r_buffer, $_);
	}
}

sub sequence_CORBA_Perl_IOP_TaggedProfile__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $len = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	my @seq = ();
	while ($len--) {
		push @seq,CORBA::Perl::IOP::TaggedProfile__demarshal($r_buffer, $r_offset, $endian);
	}
	return \@seq;
}

sub sequence_CORBA_Perl_IOP_TaggedProfile__stringify {
	my ($value, $tab, $max) = @_;
	$tab = q{} unless (defined $tab);
	croak "undefined value for 'sequence_CORBA_Perl_IOP_TaggedProfile'.\n"
			unless (defined $value);
	my $len = scalar(@{$value});
	croak "too long sequence for 'sequence_CORBA_Perl_IOP_TaggedProfile' (max:$max).\n"
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
		$str .= CORBA::Perl::IOP::TaggedProfile__stringify($_, $tab . q{ } x 2);
	}
	$str .= "\n$tab";
	$str .= '}';
	return $str;
}

# CORBA::Perl::IOP::IOR (struct)
sub IOR__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'IOR'.\n"
			unless (defined $value);
	croak "invalid struct for 'IOR' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'type_id' in structure 'IOR'.\n"
			unless (exists $value->{type_id});
	croak "no member 'profiles' in structure 'IOR'.\n"
			unless (exists $value->{profiles});
	CORBA::Perl::CORBA::string__marshal($r_buffer, $value->{type_id});
	CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_TaggedProfile__marshal($r_buffer, $value->{profiles});
}

sub IOR__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{type_id} = CORBA::Perl::CORBA::string__demarshal($r_buffer, $r_offset, $endian);
	$value->{profiles} = CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_TaggedProfile__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub IOR__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'IOR'.\n"
			unless (defined $value);
	croak "invalid struct for 'IOR' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'type_id' in structure 'IOR'.\n"
			unless (exists $value->{type_id});
	croak "no member 'profiles' in structure 'IOR'.\n"
			unless (exists $value->{profiles});
	my $str = "struct IOR {";
	$str .= "\n$tab  string type_id = ";
	$str .= CORBA::Perl::CORBA::string__stringify($value->{type_id}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  sequence_CORBA_Perl_IOP_TaggedProfile profiles = ";
	$str .= CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_TaggedProfile__stringify($value->{profiles}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub IOR__id () {
	return "IDL:omg.org/IOP/IOR:1.0";
}

# CORBA::Perl::IOP::ComponentId (typedef)
sub ComponentId__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'ComponentId'.\n"
			unless (defined $value);
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value);
}

sub ComponentId__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
}

sub ComponentId__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'ComponentId'.\n"
			unless (defined $value);
	return CORBA::Perl::CORBA::unsigned_long__stringify($value, $tab);
}

sub ComponentId__id () {
	return "IDL:omg.org/IOP/ComponentId:1.0";
}

# CORBA::Perl::IOP::TaggedComponent (struct)
sub TaggedComponent__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'TaggedComponent'.\n"
			unless (defined $value);
	croak "invalid struct for 'TaggedComponent' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'tag' in structure 'TaggedComponent'.\n"
			unless (exists $value->{tag});
	croak "no member 'component_data' in structure 'TaggedComponent'.\n"
			unless (exists $value->{component_data});
	CORBA::Perl::IOP::ComponentId__marshal($r_buffer, $value->{tag});
	CORBA::Perl::IOP::sequence_CORBA_Perl_CORBA_octet__marshal($r_buffer, $value->{component_data});
}

sub TaggedComponent__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{tag} = CORBA::Perl::IOP::ComponentId__demarshal($r_buffer, $r_offset, $endian);
	$value->{component_data} = CORBA::Perl::IOP::sequence_CORBA_Perl_CORBA_octet__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub TaggedComponent__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'TaggedComponent'.\n"
			unless (defined $value);
	croak "invalid struct for 'TaggedComponent' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'tag' in structure 'TaggedComponent'.\n"
			unless (exists $value->{tag});
	croak "no member 'component_data' in structure 'TaggedComponent'.\n"
			unless (exists $value->{component_data});
	my $str = "struct TaggedComponent {";
	$str .= "\n$tab  ComponentId tag = ";
	$str .= CORBA::Perl::IOP::ComponentId__stringify($value->{tag}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  sequence_CORBA_Perl_CORBA_octet component_data = ";
	$str .= CORBA::Perl::IOP::sequence_CORBA_Perl_CORBA_octet__stringify($value->{component_data}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub TaggedComponent__id () {
	return "IDL:omg.org/IOP/TaggedComponent:1.0";
}

# CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_TaggedComponent (sequence)
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

# CORBA::Perl::IOP::MultipleComponentProfile (typedef)
sub MultipleComponentProfile__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'MultipleComponentProfile'.\n"
			unless (defined $value);
	CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_TaggedComponent__marshal($r_buffer, $value);
}

sub MultipleComponentProfile__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_TaggedComponent__demarshal($r_buffer, $r_offset, $endian);
}

sub MultipleComponentProfile__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'MultipleComponentProfile'.\n"
			unless (defined $value);
	return CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_TaggedComponent__stringify($value, $tab);
}

sub MultipleComponentProfile__id () {
	return "IDL:omg.org/IOP/MultipleComponentProfile:1.0";
}

# CORBA::Perl::IOP::TAG_ORB_TYPE
sub TAG_ORB_TYPE () {
	return 0;
}

# CORBA::Perl::IOP::TAG_CODE_SETS
sub TAG_CODE_SETS () {
	return 1;
}

# CORBA::Perl::IOP::TAG_POLICIES
sub TAG_POLICIES () {
	return 2;
}

# CORBA::Perl::IOP::TAG_ALTERNATE_IIOP_ADDRESS
sub TAG_ALTERNATE_IIOP_ADDRESS () {
	return 3;
}

# CORBA::Perl::IOP::TAG_ASSOCIATION_OPTIONS
sub TAG_ASSOCIATION_OPTIONS () {
	return 13;
}

# CORBA::Perl::IOP::TAG_SEC_NAME
sub TAG_SEC_NAME () {
	return 14;
}

# CORBA::Perl::IOP::TAG_SPKM_1_SEC_MECH
sub TAG_SPKM_1_SEC_MECH () {
	return 15;
}

# CORBA::Perl::IOP::TAG_SPKM_2_SEC_MECH
sub TAG_SPKM_2_SEC_MECH () {
	return 16;
}

# CORBA::Perl::IOP::TAG_KerberosV5_SEC_MECH
sub TAG_KerberosV5_SEC_MECH () {
	return 17;
}

# CORBA::Perl::IOP::TAG_CSI_ECMA_Secret_SEC_MECH
sub TAG_CSI_ECMA_Secret_SEC_MECH () {
	return 18;
}

# CORBA::Perl::IOP::TAG_CSI_ECMA_Hybrid_SEC_MECH
sub TAG_CSI_ECMA_Hybrid_SEC_MECH () {
	return 19;
}

# CORBA::Perl::IOP::TAG_SSL_SEC_TRANS
sub TAG_SSL_SEC_TRANS () {
	return 20;
}

# CORBA::Perl::IOP::TAG_CSI_ECMA_Public_SEC_MECH
sub TAG_CSI_ECMA_Public_SEC_MECH () {
	return 21;
}

# CORBA::Perl::IOP::TAG_GENERIC_SEC_MECH
sub TAG_GENERIC_SEC_MECH () {
	return 22;
}

# CORBA::Perl::IOP::TAG_FIREWALL_TRANS
sub TAG_FIREWALL_TRANS () {
	return 23;
}

# CORBA::Perl::IOP::TAG_SCCP_CONTACT_INFO
sub TAG_SCCP_CONTACT_INFO () {
	return 24;
}

# CORBA::Perl::IOP::TAG_JAVA_CODEBASE
sub TAG_JAVA_CODEBASE () {
	return 25;
}

# CORBA::Perl::IOP::TAG_TRANSACTION_POLICY
sub TAG_TRANSACTION_POLICY () {
	return 26;
}

# CORBA::Perl::IOP::TAG_MESSAGE_ROUTER
sub TAG_MESSAGE_ROUTER () {
	return 30;
}

# CORBA::Perl::IOP::TAG_OTS_POLICY
sub TAG_OTS_POLICY () {
	return 31;
}

# CORBA::Perl::IOP::TAG_INV_POLICY
sub TAG_INV_POLICY () {
	return 32;
}

# CORBA::Perl::IOP::TAG_CSI_SEC_MECH_LIST
sub TAG_CSI_SEC_MECH_LIST () {
	return 33;
}

# CORBA::Perl::IOP::TAG_NULL_TAG
sub TAG_NULL_TAG () {
	return 34;
}

# CORBA::Perl::IOP::TAG_SECIOP_SEC_TRANS
sub TAG_SECIOP_SEC_TRANS () {
	return 35;
}

# CORBA::Perl::IOP::TAG_TLS_SEC_TRANS
sub TAG_TLS_SEC_TRANS () {
	return 36;
}

# CORBA::Perl::IOP::TAG_ACTIVITY_POLICY
sub TAG_ACTIVITY_POLICY () {
	return 37;
}

# CORBA::Perl::IOP::TAG_COMPLETE_OBJECT_KEY
sub TAG_COMPLETE_OBJECT_KEY () {
	return 5;
}

# CORBA::Perl::IOP::TAG_ENDPOINT_ID_POSITION
sub TAG_ENDPOINT_ID_POSITION () {
	return 6;
}

# CORBA::Perl::IOP::TAG_LOCATION_POLICY
sub TAG_LOCATION_POLICY () {
	return 12;
}

# CORBA::Perl::IOP::TAG_DCE_STRING_BINDING
sub TAG_DCE_STRING_BINDING () {
	return 100;
}

# CORBA::Perl::IOP::TAG_DCE_BINDING_NAME
sub TAG_DCE_BINDING_NAME () {
	return 101;
}

# CORBA::Perl::IOP::TAG_DCE_NO_PIPES
sub TAG_DCE_NO_PIPES () {
	return 102;
}

# CORBA::Perl::IOP::TAG_DCE_SEC_MECH
sub TAG_DCE_SEC_MECH () {
	return 103;
}

# CORBA::Perl::IOP::TAG_INET_SEC_TRANS
sub TAG_INET_SEC_TRANS () {
	return 123;
}

# CORBA::Perl::IOP::ServiceId (typedef)
sub ServiceId__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'ServiceId'.\n"
			unless (defined $value);
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $value);
}

sub ServiceId__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
}

sub ServiceId__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'ServiceId'.\n"
			unless (defined $value);
	return CORBA::Perl::CORBA::unsigned_long__stringify($value, $tab);
}

sub ServiceId__id () {
	return "IDL:omg.org/IOP/ServiceId:1.0";
}

# CORBA::Perl::IOP::ServiceContext (struct)
sub ServiceContext__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'ServiceContext'.\n"
			unless (defined $value);
	croak "invalid struct for 'ServiceContext' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'context_id' in structure 'ServiceContext'.\n"
			unless (exists $value->{context_id});
	croak "no member 'context_data' in structure 'ServiceContext'.\n"
			unless (exists $value->{context_data});
	CORBA::Perl::IOP::ServiceId__marshal($r_buffer, $value->{context_id});
	CORBA::Perl::IOP::sequence_CORBA_Perl_CORBA_octet__marshal($r_buffer, $value->{context_data});
}

sub ServiceContext__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $value = {};
	$value->{context_id} = CORBA::Perl::IOP::ServiceId__demarshal($r_buffer, $r_offset, $endian);
	$value->{context_data} = CORBA::Perl::IOP::sequence_CORBA_Perl_CORBA_octet__demarshal($r_buffer, $r_offset, $endian);
	return $value;
}

sub ServiceContext__stringify {
	my ($value, $tab) = @_;
	$tab = q{} unless defined ($tab);
	croak "undefined value for 'ServiceContext'.\n"
			unless (defined $value);
	croak "invalid struct for 'ServiceContext' (not a HASH reference).\n"
			unless (ref $value eq 'HASH');
	croak "no member 'context_id' in structure 'ServiceContext'.\n"
			unless (exists $value->{context_id});
	croak "no member 'context_data' in structure 'ServiceContext'.\n"
			unless (exists $value->{context_data});
	my $str = "struct ServiceContext {";
	$str .= "\n$tab  ServiceId context_id = ";
	$str .= CORBA::Perl::IOP::ServiceId__stringify($value->{context_id}, $tab . "  ");
	$str .= ',';
	$str .= "\n$tab  sequence_CORBA_Perl_CORBA_octet context_data = ";
	$str .= CORBA::Perl::IOP::sequence_CORBA_Perl_CORBA_octet__stringify($value->{context_data}, $tab . "  ");
	$str .= "\n$tab}";
	return $str;
}

sub ServiceContext__id () {
	return "IDL:omg.org/IOP/ServiceContext:1.0";
}

# CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_ServiceContext (sequence)
sub sequence_CORBA_Perl_IOP_ServiceContext__marshal {
	my ($r_buffer, $value, $max) = @_;
	croak "undefined value for 'sequence_CORBA_Perl_IOP_ServiceContext'.\n"
			unless (defined $value);
	my $len = scalar(@{$value});
	croak "too long sequence for 'sequence_CORBA_Perl_IOP_ServiceContext' (max:$max).\n"
			if (defined $max and $len > $max);
	CORBA::Perl::CORBA::unsigned_long__marshal($r_buffer, $len);
	foreach (@{$value}) {
		CORBA::Perl::IOP::ServiceContext__marshal($r_buffer, $_);
	}
}

sub sequence_CORBA_Perl_IOP_ServiceContext__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	my $len = CORBA::Perl::CORBA::unsigned_long__demarshal($r_buffer, $r_offset, $endian);
	my @seq = ();
	while ($len--) {
		push @seq,CORBA::Perl::IOP::ServiceContext__demarshal($r_buffer, $r_offset, $endian);
	}
	return \@seq;
}

sub sequence_CORBA_Perl_IOP_ServiceContext__stringify {
	my ($value, $tab, $max) = @_;
	$tab = q{} unless (defined $tab);
	croak "undefined value for 'sequence_CORBA_Perl_IOP_ServiceContext'.\n"
			unless (defined $value);
	my $len = scalar(@{$value});
	croak "too long sequence for 'sequence_CORBA_Perl_IOP_ServiceContext' (max:$max).\n"
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
		$str .= CORBA::Perl::IOP::ServiceContext__stringify($_, $tab . q{ } x 2);
	}
	$str .= "\n$tab";
	$str .= '}';
	return $str;
}

# CORBA::Perl::IOP::ServiceContextList (typedef)
sub ServiceContextList__marshal {
	my ($r_buffer, $value) = @_;
	croak "undefined value for 'ServiceContextList'.\n"
			unless (defined $value);
	CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_ServiceContext__marshal($r_buffer, $value);
}

sub ServiceContextList__demarshal {
	my ($r_buffer, $r_offset, $endian) = @_;
	return CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_ServiceContext__demarshal($r_buffer, $r_offset, $endian);
}

sub ServiceContextList__stringify {
	my ($value, $tab) = @_;
	croak "undefined value for 'ServiceContextList'.\n"
			unless (defined $value);
	return CORBA::Perl::IOP::sequence_CORBA_Perl_IOP_ServiceContext__stringify($value, $tab);
}

sub ServiceContextList__id () {
	return "IDL:omg.org/IOP/ServiceContextList:1.0";
}

# CORBA::Perl::IOP::TransactionService
sub TransactionService () {
	return 0;
}

# CORBA::Perl::IOP::CodeSets
sub CodeSets () {
	return 1;
}

# CORBA::Perl::IOP::ChainBypassCheck
sub ChainBypassCheck () {
	return 2;
}

# CORBA::Perl::IOP::ChainBypassInfo
sub ChainBypassInfo () {
	return 3;
}

# CORBA::Perl::IOP::LogicalThreadId
sub LogicalThreadId () {
	return 4;
}

# CORBA::Perl::IOP::BI_DIR_IIOP
sub BI_DIR_IIOP () {
	return 5;
}

# CORBA::Perl::IOP::SendingContextRunTime
sub SendingContextRunTime () {
	return 6;
}

# CORBA::Perl::IOP::INVOCATION_POLICIES
sub INVOCATION_POLICIES () {
	return 7;
}

# CORBA::Perl::IOP::FORWARDED_IDENTITY
sub FORWARDED_IDENTITY () {
	return 8;
}

# CORBA::Perl::IOP::UnknownExceptionInfo
sub UnknownExceptionInfo () {
	return 9;
}

# CORBA::Perl::IOP::RTCorbaPriority
sub RTCorbaPriority () {
	return 10;
}

# CORBA::Perl::IOP::RTCorbaPriorityRange
sub RTCorbaPriorityRange () {
	return 11;
}

# CORBA::Perl::IOP::FT_GROUP_VERSION
sub FT_GROUP_VERSION () {
	return 12;
}

# CORBA::Perl::IOP::FT_REQUEST
sub FT_REQUEST () {
	return 13;
}

# CORBA::Perl::IOP::ExceptionDetailMessage
sub ExceptionDetailMessage () {
	return 14;
}

# CORBA::Perl::IOP::SecurityAttributeService
sub SecurityAttributeService () {
	return 15;
}

# CORBA::Perl::IOP::ActivityService
sub ActivityService () {
	return 16;
}


#
#   end of module CORBA::Perl::IOP
#

package main;

1;

#   end of file : IOP.pm

# Local variables:
#   buffer-read-only: t
# End:
