
package XPT;

use strict;
use warnings;

our $VERSION = '0.20';

use Carp;

our $demarshal_retcode;
our $demarshal_not_abort;
our $stringify_verbose;
our $data_pool_offset;
our $data_pool;
our $param_problems;

use constant int8                               => 0;
use constant int16                              => 1;
use constant int32                              => 2;
use constant int64                              => 3;
use constant uint8                              => 4;
use constant uint16                             => 5;
use constant uint32                             => 6;
use constant uint64                             => 7;
use constant float                              => 8;
use constant double                             => 9;
use constant boolean                            => 10;
use constant char                               => 11;
use constant wchar_t                            => 12;
use constant void                               => 13;
use constant nsIID                              => 14;
use constant domstring                          => 15;
use constant pstring                            => 16;
use constant pwstring                           => 17;
use constant InterfaceTypeDescriptor            => 18;
use constant InterfaceIsTypeDescriptor          => 19;
use constant ArrayTypeDescriptor                => 20;
use constant StringWithSizeTypeDescriptor       => 21;
use constant WideStringWithSizeTypeDescriptor   => 22;
use constant utf8string                         => 23;
use constant cstring                            => 24;
use constant astring                            => 25;


sub ReadBuffer {
    my ($r_buffer, $r_offset, $n) = @_;
    my $str = substr $$r_buffer, $$r_offset, $n;
    croak "not enough data.\n"
            if (length($str) != $n);
    $$r_offset += $n;
    return $str;
}

sub Read8 {
    my ($r_buffer, $r_offset) = @_;
    my $str = ReadBuffer($r_buffer, $r_offset, 1);
    return unpack 'C', $str;
}

sub Write8 {
    my ($value) = @_;
    return pack 'C', $value;
}

sub Read16 {
    my ($r_buffer, $r_offset) = @_;
    my $str = ReadBuffer($r_buffer, $r_offset, 2);
    return unpack 'n', $str;
}

sub Write16 {
    my ($value) = @_;
    return pack 'n', $value;
}

sub Read32 {
    my ($r_buffer, $r_offset) = @_;
    my $str = ReadBuffer($r_buffer, $r_offset, 4);
    return unpack 'N', $str;
}

sub Write32 {
    my ($value) = @_;
    return pack 'N', $value;
}

sub Read64 {
    my ($r_buffer, $r_offset) = @_;
    my $str = ReadBuffer($r_buffer, $r_offset, 8);
    # unsupported
    return 0;
}

sub Write64 {
    my ($value) = @_;
    return chr(0) x 8;
}

sub ReadStringInline {
    my ($r_buffer, $r_offset) = @_;
    my $len = Read16($r_buffer, $r_offset);
    my $str = ReadBuffer($r_buffer, $r_offset, $len);
    return $str;
}

sub WriteStringInline {
    my ($value) = @_;
    return Write16(length($value)) . $value;
}

sub ReadCString {
    my ($r_buffer, $r_offset) = @_;
    my $offset = Read32($r_buffer, $r_offset);
    return q{} unless ($offset);
    my $start = $data_pool_offset + $offset - 1;
    my $end = index $$r_buffer, "\0", $start;
    my $str = substr $$r_buffer, $start, $end - $start;
    return $str;
}

sub WriteCString {
    my ($value) = @_;
    return Write32(0) unless ($value);
    my $offset = 1 + length($data_pool);
    $data_pool .= $value . "\0";
    return Write32($offset);
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %attr = @_;
    my $self = \%attr;
    bless $self, $class;
    return $self
}

use CORBA::XPIDL::XPT::File;
use CORBA::XPIDL::XPT::InterfaceDirectoryEntry;
use CORBA::XPIDL::XPT::InterfaceDescriptor;
use CORBA::XPIDL::XPT::ConstDescriptor;
use CORBA::XPIDL::XPT::MethodDescriptor;
use CORBA::XPIDL::XPT::ParamDescriptor;
use CORBA::XPIDL::XPT::TypeDescriptor;
use CORBA::XPIDL::XPT::Annotation;
use CORBA::XPIDL::XPT::IID;

1;

