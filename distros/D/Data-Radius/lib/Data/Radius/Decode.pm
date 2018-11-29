package Data::Radius::Decode;

use v5.10;
use strict;
use warnings;
use bytes;
use Socket qw(inet_ntop inet_pton AF_INET AF_INET6);

use constant {
    ATTR_CISCO_AVPAIR   => 1,
    VENDOR_CISCO        => 'Cisco',
};

use Exporter qw(import);
our @EXPORT_OK = qw(
    decode

    decode_string
    decode_int
    decode_byte
    decode_short
    decode_signed
    decode_ipaddr
    decode_ipv6addr
    decode_combo_ip
    decode_octets
    decode_avpair
    decode_tlv
);

use Data::Radius::Util qw(is_enum_type);

# type decoders
#  $coderef->($value, $attr, $dictionary)
my %decode_map = (
    string      => \&decode_string,
    string_tag  => \&decode_string_tag,
    integer     => \&decode_int,
    integer_tag => \&decode_int_tag,
    byte        => \&decode_byte,
    short       => \&decode_short,
    signed      => \&decode_signed,
    ipaddr      => \&decode_ipaddr,
    ipv6addr    => \&decode_ipv6addr,
    avpair      => \&decode_avpair,
    'combo-ip'  => \&decode_combo_ip,
    octets      => \&decode_octets,
    tlv         => \&decode_tlv,
    # Unix timestamp
    date        => \&decode_int,
    #TODO Ascend binary encoding
    # abinary   => ...
);

if (!defined inet_pton(AF_INET6, '::1')) {
    require Net::IP;
    $decode_map{ipv6addr} = \&decode_ipv6addr_pp;
}

sub decode_string   { $_[0] }

sub decode_string_tag {
    my $value = shift;
    # https://tools.ietf.org/html/rfc2868#section-3.3
    # If the Tag field is greater than 0x1F, it SHOULD be
    # interpreted as the first byte of the following String field
    return if (length($value) < 1);

    my $tag = unpack('C', substr($value, 0, 1));
    if ($tag > 0x1F) {
        return ($value, undef);
    }
    return (substr($value, 1), $tag);
}

sub decode_int      { unpack('N', $_[0]) }
sub decode_byte     { unpack('C', $_[0]) }
sub decode_short    { unpack('S>', $_[0]) }
sub decode_signed   { unpack('l>', $_[0]) }

sub decode_int_tag {
    my $value = shift;
    # https://tools.ietf.org/html/rfc6158#section-3.2.2
    # when integer values are tagged, the value portion is reduced to three bytes

    # replace tag by 0 to make unpack() value work
    my $tag = unpack('C', substr($value, 0, 1, "\x00"));
    return (unpack('N', $value), $tag);
}

sub decode_ipaddr   { inet_ntop(AF_INET, $_[0]) }
sub decode_ipv6addr { inet_ntop(AF_INET6, $_[0]) }

sub decode_ipv6addr_pp {
    my $value = shift;

    my $binary = unpack( 'B*', $value );
    return undef if (! $binary);
    my $ip_val = Net::IP::ip_bintoip( $binary, 6 );
    return undef if (! $ip_val);
    return Net::IP::ip_compress_address( $ip_val, 6 );
}

sub decode_octets   { '0x'.unpack("H*", $_[0]) }

sub decode_combo_ip {
    my $ip = shift;

    if (length($ip) == 4) {
        return $decode_map{ipaddr}->($ip);
    }
    return $decode_map{ipv6addr}->($ip);
}

sub decode_avpair {
    my ($value, $attr, $dict) = @_;
    if ( ($attr->{vendor} // '') eq VENDOR_CISCO) {
        # Cisco hack
        if ( $attr->{id} == ATTR_CISCO_AVPAIR ) {
            # Cisco-AVPair = "h323-foo-bar=baz"
            # leave it as-is
        }
        else {
            # h323-foo-bar = "h323-foo-bar = baz"
            # cut attribute name
            $value =~ s/^\Q$attr->{name}\E\s*=//;
        }
    }

    return $value;
}

sub decode_tlv {
    my ($value, $parent, $dict) = @_;

    my $pos = 0;
    my $len = length($value);

    my @list = ();
    while ($pos < $len) {
        my ($attr_id, $attr_len) = unpack('C C', substr($value, $pos, 2));
        my $attr_val = substr($value, $pos + 2, $attr_len - 2);

        my $attr = $dict->tlv_attribute_name($parent, $attr_id);
        if (! $attr) {
            push @list, {Name => $attr_id, Value => $attr_val, Unknown => 1};
        }
        else {
            my $decoded = decode($attr, $attr_val, $dict);
            if (is_enum_type($attr->{type})) {
                $decoded = $dict->constant($attr->{name}, $decoded) // $decoded;
            }

            push @list, {Name => $attr->{name}, Value => $decoded, Type => $attr->{type}};
        }

        $pos += $attr_len;
    }

    return \@list;
}

sub decode {
    my ($attr, $value, $dict) = @_;

    my $decoder = $attr->{type} . ($attr->{has_tag} ? '_tag' : '');
    my ($decoded, $tag) = $decode_map{ $decoder }->($value, $attr, $dict);
    return wantarray ? ($decoded, $tag) : $decoded;
}

1;
