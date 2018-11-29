package Data::Radius::Encode;

use strict;
use warnings;
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
}

# value limits for numeric types
my %limits_map = (
    integer     => [0,      2**32 - 1],
    integer_tag => [0,      2**24 - 1],
    byte        => [0,      2**8  - 1],
    short       => [0,      2**16 - 1],
    signed      => [-2**31, 2**31 - 1],
    # unix timestamp
    date        => [0,      2**32 - 1],
);

sub encode_string {
    my ($value, $attr, $dict) = @_;
    my $max_size = ($attr && $attr->{vendor}) ? MAX_VSA_STRING_SIZE : MAX_STRING_SIZE;
    if (length($value) > $max_size) {
        warn "Too long value of ".$attr->{name};
        return undef;
    }
    return $value;
}

sub encode_string_tag {
    my ($value, $attr, $dict, $tag) = @_;
    my $max_size = ($attr && $attr->{vendor}) ? MAX_VSA_STRING_SIZE : MAX_STRING_SIZE;

    if (defined $tag) {
        if ($tag > 31) {
            warn sprintf('Too big tag value %d for %s', $tag, $attr->{name});
        }
        $max_size--;
    }

    if (length($value) > $max_size) {
        warn "Too long value of ".$attr->{name};
        return undef;
    }

    if (defined $tag) {
        $value = pack('C', $tag) . $value;
    }

    return $value;
}

sub encode_int    { pack('N',  int($_[0])) }
sub encode_byte   { pack('C',  int($_[0])) }
sub encode_short  { pack('S>', int($_[0])) }
sub encode_signed { pack('l>', int($_[0])) }

sub encode_int_tag {
    my ($value, $attr, $dict, $tag) = @_;
    $value = pack('N', int($value));
    if (defined $tag) {
        if ($tag > 31) {
            warn sprintf('Too big tag value %d for %s', $tag, $attr->{name});
        }
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
        warn 'Invalid octet string for '.$attr->{name};
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
        warn "Too long value of ".$attr->{name};
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
            warn "Unknown tlv-attribute ".$v->{Name};
            next;
        }

        # no vendor for sub-attributes

        # verify that corrent sub-attribute is used
        if ( ($attr->{parent} // '') ne $parent->{name}) {
            warn "Attribute $v->{Name} cannot be used with $parent->{name}";
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

# main exported function
sub encode {
    my ($attr, $value, $dict, $tag) = @_;

    if (! defined $value) {
        warn "Value is not defined for " . $attr->{name};
        return undef;
    }

    my $encoder = $attr->{type} . ($attr->{has_tag} ? '_tag' : '');

    my $limits = $limits_map{ $encoder };
    if ($limits) {
        # integer types
        if ($value !~ /^-?\d+$/) {
            warn "Value is not number for " . $attr->{name};
            return undef;
        }

        my ($min, $max) = @$limits;
        if ($value < $min || $value > $max) {
            warn "Value out of range for " . $attr->{name};
            return undef;
        }
    }

    my $encoded = $encode_map{ $encoder }->($value, $attr, $dict, $tag);
    return $encoded;
}

1;
