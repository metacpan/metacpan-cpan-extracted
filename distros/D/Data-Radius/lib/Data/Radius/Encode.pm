package Data::Radius::Encode;

use strict;
use warnings;
use Carp ();
use bytes;
use Socket qw(inet_pton AF_INET AF_INET6);

use constant {
    MAX_STRING_SIZE      => 253,
    MAX_VSA_STRING_SIZE  => 247,
    ATTR_CISCO_AVPAIR    => 'Cisco-AVPair',
    ATTR_CISCO_AVPAIR_ID => 1,
    VENDOR_CISCO         => 'Cisco',
};

use Exporter qw(import);

our @EXPORT_OK = qw(
    encode

    encode_string
    encode_int
    encode_byte
    encode_short
    encode_signed
    encode_ipaddr
    encode_ipv6addr
    encode_combo_ip
    encode_octets
    encode_avpair
    encode_tlv
);

use Data::Radius::Util qw(is_enum_type);

our ($PrintError, $RaiseError) = (1, 0);

sub _error {
    my $msg = shift;
    Carp::croak($msg) if $RaiseError;
    Carp::carp ($msg) if $PrintError;
    return;
}

# type encoders
#  $coderef->($value, $attr, $dictionary)
my %encode_map = (
    string      => \&encode_string,
    string_tag  => \&encode_string_tag,
    integer     => \&encode_int,
    integer_tag => \&encode_int_tag,
    byte        => \&encode_byte,
    short       => \&encode_short,
    signed      => \&encode_signed,
    ipaddr      => \&encode_ipaddr,
    ipv6addr    => \&encode_ipv6addr,
    ipv4prefix  => \&encode_ipv4prefix,
    ipv6prefix  => \&encode_ipv6prefix,
    avpair      => \&encode_avpair,
    'combo-ip'  => \&encode_combo_ip,
    octets      => \&encode_octets,
    tlv         => \&encode_tlv,
    # Unix timestamp
    date        => \&encode_int,
    #TODO Ascend binary encoding
    # abinary   => ...
);

if (!defined inet_pton(AF_INET6, '::1')) {
    require Net::IP;
    $encode_map{ipv6addr} = \&encode_ipv6addr_pp,
    $encode_map{ipv6prefix} = \&encode_ipv6prefix_pp,
}

sub encode_string {
    my ($value, $attr, $dict) = @_;
    my $max_size = ($attr && $attr->{vendor}) ? MAX_VSA_STRING_SIZE : MAX_STRING_SIZE;
    if ( length($value) > $max_size) {
        _error( "Too long value for attribute '$attr->{name}'" );
        $value = undef; # substr($value, $max_size); # forgiving option?
    }
    return $value;
}

sub encode_string_tag {
    my ($value, $attr, $dict, $tag) = @_;

    if (! defined $tag ) {
        _error( "Undefined tag value for attribute '$attr->{name}'");
    }
    elsif ( $tag !~ /^\d+$/ ) {
        _error( "Invalid tag value '$tag' for attribute '$attr->{name}'" );
    }
    elsif ( $tag == 0 ) {
        # it should be possible to correctly indicate to not to utilize tag
    }
    elsif ($tag < 1 || $tag > 31) {
        _error( "Tag value $tag out of range 1..31 for attribute '$attr->{name}'" );
    }
    else {
        $value = pack('C', $tag) . $value;
    }

    my $max_size = ($attr && $attr->{vendor}) ? MAX_VSA_STRING_SIZE : MAX_STRING_SIZE;
    if ( length($value) > $max_size) {
        _error( "Too long value for attribute '$attr->{name}'" );
        $value = undef; # substr($value, $max_size); # forgiving option?
    }

    return $value;
}

sub check_numeric {
    my ($value, $attr, $range) = @_;
    if ($value !~ /^-?\d+$/) {
        _error( "Invalid value for numeric attribute '$attr->{name}'" );
        return;
    }
    if ($range) {
        if ($value < $range->[0] || $value > $range->[1]) {
            _error( "Value out of range for $attr->{type} attribute '$attr->{name}'" );
            return undef;
        }
    }
    return 1;
}

sub encode_int    { return check_numeric($_[0], $_[1], [0, 2**32 - 1]) ? pack('N',  int($_[0])) : undef }
sub encode_byte   { return check_numeric($_[0], $_[1], [0, 2**8  - 1]) ? pack('C',  int($_[0])) : undef }
sub encode_short  { return check_numeric($_[0], $_[1], [0, 2**16 - 1]) ? pack('S>', int($_[0])) : undef }
sub encode_signed { return check_numeric($_[0], $_[1], [-2**31, 2**31 - 1]) ? pack('l>', int($_[0])) : undef }

sub encode_int_tag {
    my ($value, $attr, $dict, $tag) = @_;
    return undef if !check_numeric($value, $attr, [0, 2**24 - 1]);
    $value = pack('N', int($value));
    if (! defined $tag ) {
        _error( "Undefined tag value for attribute '$attr->{name}'");
    }
    elsif ( $tag !~ /^\d+$/ ) {
        _error( "Invalid tag value '$tag' for attribute '$attr->{name}'" );
    }
    elsif ( $tag == 0 ) {
        # it should be possible to correctly indicate to not to utilize tag
    }
    elsif ($tag < 1 || $tag > 31) {
        _error( "Tag value $tag out of range 1..31 for attribute '$attr->{name}'" );
    }
    else {
        # tag added to 1st byte, not extending the value length
        substr($value, 0, 1, pack('C', $tag) );
    }
    return $value;
}

sub encode_ipaddr { inet_pton(AF_INET, $_[0]) }
sub encode_ipv6addr { inet_pton(AF_INET6, $_[0]) }

sub encode_ipv6addr_pp {
    my $value = shift;
    my $expanded_value = Net::IP::ip_expand_address( $value, 6 );
    return undef if (! $expanded_value);
    my $bin_value = Net::IP::ip_iptobin( $expanded_value, 6 );
    return undef if (! defined $bin_value);
    return pack( 'B*', $bin_value );
}

sub encode_octets {
    my ($value, $attr, $dict) = @_;

    if ($value !~ /^0x(?:[0-9A-Fa-f]{2})+$/) {
        _error( "Invalid octet string value for attribute '$attr->{name}'" );
        return undef;
    }

    $value =~ s/^0x//;
    return pack("H*", $value);
}

sub encode_combo_ip {
    my $ip = shift;

    if ($ip =~ /^\d+\.\d+.\d+.\d+$/) {
        return $encode_map{ipaddr}->($ip);
    }

    return $encode_map{ipv6addr}->($ip);
}

sub encode_avpair {
    my ($value, $attr, $dict) = @_;
    if ( ($attr->{vendor} // '') eq VENDOR_CISCO ) {
        # Looks like it afects only requests from Cisco NAS
        # and probably not required in requests to it
        # Do not applied to Cisco-AVPair attribute itself
        if ($attr->{id} == ATTR_CISCO_AVPAIR_ID && $attr->{name} ne ATTR_CISCO_AVPAIR) {
            $value = $attr->{name} . '=' . $value;
        }
    }

    if (length($value) > MAX_VSA_STRING_SIZE) {
        _error( "Too long value for attribute '$attr->{name}'" );
        return undef;
    }

    return $value;
}

# TODO continuation field is not supported for WiMAX VSA
sub encode_tlv {
    my ($value, $parent, $dict) = @_;

    my @list = ();
    foreach my $v (@{$value}) {
        my $attr = $dict->attribute($v->{Name});
        if (! $attr) {
            _error( "Unknown tlv-attribute '$v->{Name}' for attribute '$parent->{name}'" );
            next;
        }

        # no vendor for sub-attributes

        # verify that corrent sub-attribute is used
        if ( ($attr->{parent} // '') ne $parent->{name}) {
            _error( "Attribute '$v->{Name}' is not a tlv of attribute '$parent->{name}'" );
            next;
        }

        # constant to its value
        my $value;
        if (is_enum_type($attr->{type})) {
            $value = $dict->value($attr->{name}, $v->{Value}) // $v->{Value};
        }
        else {
            $value = $v->{Value};
        }

        my $encoded = encode($attr, $value, $dict);

        push @list, pack('C C', $attr->{id}, length($encoded) + 2) . $encoded;
    }

    return join('', @list);
}

sub encode_ipv4prefix {
    my ($value, $attr) = @_;

    my ($ip, $prefix_len);
    if ($value =~ /^(\d+\.\d+\.\d+\.\d+)(?:\/(\d+))?$/) {
        ($ip, $prefix_len) = ($1, $2 || 0);
    }
    else {
        _error("Invalid IPv4 prefix format for attribute '$attr->{name}'. Expected format: ip/prefix-length or just ip");
        return undef;
    }

    if ($prefix_len < 0 || $prefix_len > 32) {
        _error("Invalid prefix length for IPv4 prefix in attribute '$attr->{name}'. Must be between 0 and 32");
        return undef;
    }

    my $ip_bin = inet_pton(AF_INET, $ip);
    unless (defined $ip_bin) {
        _error("Invalid IPv4 address format for attribute '$attr->{name}': $ip");
        return undef;
    }

    return pack('Ca*', $prefix_len, $ip_bin);
}

sub encode_ipv6prefix {
    my ($value, $attr) = @_;

    my ($ip, $prefix_len);
    if ($value =~ /^([0-9a-fA-F:]+)(?:\/(\d+))?$/) {
        ($ip, $prefix_len) = ($1, $2 || 0);
    }
    else {
        _error("Invalid IPv6 prefix format for attribute '$attr->{name}'. Expected format: ipv6/prefix-length or just ipv6");
        return undef;
    }

    if ($prefix_len < 0 || $prefix_len > 128) {
        _error("Invalid prefix length for IPv6 prefix in attribute '$attr->{name}'. Must be between 0 and 128");
        return undef;
    }

    my $ip_bin = inet_pton(AF_INET6, $ip);
    unless (defined $ip_bin) {
        _error("Invalid IPv6 address format for attribute '$attr->{name}': $ip");
        return undef;
    }

    return pack('Ca*', $prefix_len, $ip_bin);
}

sub encode_ipv6prefix_pp {
    my ($value, $attr) = @_;

    my ($ip, $prefix_len);
    if ($value =~ /^([0-9a-fA-F:]+)(?:\/(\d+))?$/) {
        ($ip, $prefix_len) = ($1, $2 || 0);
    }
    else {
        _error("Invalid IPv6 prefix format for attribute '$attr->{name}'. Expected format: ipv6/prefix-length or just ipv6");
        return undef;
    }

    if ($prefix_len < 0 || $prefix_len > 128) {
        _error("Invalid prefix length for IPv6 prefix in attribute '$attr->{name}'. Must be between 0 and 128");
        return undef;
    }

    my $expanded_value = Net::IP::ip_expand_address($ip, 6);
    unless ($expanded_value) {
        _error("Invalid IPv6 address format for attribute '$attr->{name}': $ip");
        return undef;
    }

    my $bin_value = Net::IP::ip_iptobin($expanded_value, 6);
    unless (defined $bin_value) {
        _error("Failed to convert IPv6 address to binary for attribute '$attr->{name}': $ip");
        return undef;
    }

    return pack('CB*', $prefix_len, $bin_value);
}

# main exported function
sub encode {
    my ($attr, $value, $dict, $tag) = @_;

    if (! defined $value) {
        _error( "Undefined value for attribute '$attr->{name}'" );
        return undef;
    }

    my ($encoder_type, $encoder_sub, $encoded);

    if ($attr->{has_tag}) {
        $encoder_type .= $attr->{type}.'_tag';
    }
    else {
        $encoder_type = $attr->{type};
        _error( "Provided Tag for tagless attribute '$attr->{name}'") if defined $tag;
    }

    if ($encoder_sub = $encode_map{ $encoder_type }) {
        $encoded = $encoder_sub->($value, $attr, $dict, $tag);
    }
    else {
        _error( "Unsupported encoding type '$encoder_type' for attribute '$attr->{name}'" );
    }

    return $encoded;
}

1;
