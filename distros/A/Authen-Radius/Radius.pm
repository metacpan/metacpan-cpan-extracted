#############################################################################
#                                                                           #
# Radius Client module for Perl 5                                           #
#                                                                           #
# Written by Carl Declerck <carl@miskatonic.inbe.net>, (c)1997              #
# All Rights Reserved. See the Perl Artistic License 2.0                    #
# for copying & usage policy.                                               #
#                                                                           #
# Modified by Olexander Kapitanenko, Andrew Zhilenko                        #
#             and the rest of PortaOne team (c) 2002-2013                   #
#             Current maintainer's contact: perl-radius@portaone.com        #
#                                                                           #
# See the file 'Changes' in the distribution archive.                       #
#                                                                           #
#############################################################################

package Authen::Radius;

use strict;
use warnings;
use v5.10;
use FileHandle;
use IO::Socket;
use IO::Select;
use Digest::MD5;
use Data::Dumper;
use Data::HexDump;
use Net::IP qw(ip_bintoip ip_compress_address ip_expand_address ip_iptobin);
use Time::HiRes qw(time);

use vars qw($VERSION @ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(ACCESS_REQUEST ACCESS_ACCEPT ACCESS_REJECT ACCESS_CHALLENGE
            ACCOUNTING_REQUEST ACCOUNTING_RESPONSE ACCOUNTING_STATUS
            DISCONNECT_REQUEST DISCONNECT_ACCEPT DISCONNECT_REJECT
            STATUS_SERVER
            COA_REQUEST COA_ACCEPT COA_REJECT COA_ACK COA_NAK);

$VERSION = '0.29';

my (%dict_id, %dict_name, %dict_val, %dict_vendor_id, %dict_vendor_name );
my ($request_id) = $$ & 0xff;   # probably better than starting from 0
my ($radius_error, $error_comment) = ('ENONE', '');
my $debug = 0;

use constant WIMAX_VENDOR => '24757';
use constant WIMAX_CONTINUATION_BIT => 0b10000000;

use constant NO_VENDOR => 'not defined';

use constant DEFAULT_DICTIONARY => '/etc/raddb/dictionary';

#
# we'll need to predefine these attr types so we can do simple password
# verification without having to load a dictionary
#

# ATTRIBUTE   User-Name      1 string
# ATTRIBUTE   User-Password  2 string
# ATTRIBUTE   NAS-IP-Address 4 ipaddr
$dict_id{ NO_VENDOR() }{1}{type} = 'string';
$dict_id{ NO_VENDOR() }{2}{type} = 'string';
$dict_id{ NO_VENDOR() }{4}{type} = 'ipaddr';

# ATTRIBUTE Vendor-Specific 26 octets
use constant ATTR_VENDOR => 26;

use constant ACCESS_REQUEST               => 1;
use constant ACCESS_ACCEPT                => 2;
use constant ACCESS_REJECT                => 3;
use constant ACCOUNTING_REQUEST           => 4;
use constant ACCOUNTING_RESPONSE          => 5;
use constant ACCOUNTING_STATUS            => 6;
use constant ACCESS_CHALLENGE             => 11;
use constant STATUS_SERVER                => 12;
use constant DISCONNECT_REQUEST           => 40;
use constant DISCONNECT_ACCEPT            => 41;
use constant DISCONNECT_REJECT            => 42;
use constant COA_REQUEST                  => 43;
use constant COA_ACCEPT                   => 44;
use constant COA_ACK                      => 44;
use constant COA_REJECT                   => 45;
use constant COA_NAK                      => 45;

my $HMAC_MD5_BLCKSZ = 64;
my $RFC3579_MSG_AUTH_ATTR_ID = 80;
my $RFC3579_MSG_AUTH_ATTR_LEN = 18;
my %SERVICES = (
    'radius' => 1812,
    'radacct' => 1813,
    'radius-acct' => 1813,
);

sub new {
    my $class = shift;
    my %h = @_;
    my ($host, $port, $service);
    my $self = {};

    bless $self, $class;

    $self->set_error;
    $debug = $h{'Debug'};

    if (!$h{'Host'} && !$h{'NodeList'}) {
        return $self->set_error('ENOHOST');
    }

    $service = $h{'Service'} ? $h{'Service'} : 'radius';
    my $serv_port = getservbyname($service, 'udp');
    if (!$serv_port && !exists($SERVICES{$service})) {
        return $self->set_error('EBADSERV');
    } elsif (!$serv_port) {
        $serv_port = $SERVICES{$service};
    }

    ($host, $port) = split(/:/, $h{'Host'});
    if (!$port) {
        $port = $serv_port;
    }

    $self->{'timeout'} = $h{'TimeOut'} ? $h{'TimeOut'} : 5;
    $self->{'localaddr'} = $h{'LocalAddr'};
    $self->{'secret'} = $h{'Secret'};
    $self->{'message_auth'}  = $h{'Rfc3579MessageAuth'};
    print STDERR "Using Radius server $host:$port\n" if $debug;
    my %io_sock_args = (
                Type => SOCK_DGRAM,
                Proto => 'udp',
                Timeout => $self->{'timeout'},
                LocalAddr => $self->{'localaddr'},
    );
    if ($h{'NodeList'}) {
        # contains resolved node list in text representation
        $self->{'node_list_a'} = {};
        foreach my $node_a (@{$h{'NodeList'}}) {
            my ($n_host, $n_port) = split(/:/, $node_a);
            if (!$n_port) {
                $n_port = $serv_port;
            }
            my @hostinfo = gethostbyname($n_host);
            if (!scalar(@hostinfo)) {
                print STDERR "Can't resolve node hostname '$n_host': $! - skipping it!\n" if $debug;
                next;
            }
            print STDERR "Adding ".inet_ntoa($hostinfo[4]).':'.$n_port." to node list.\n" if $debug;
            # store split address to avoid additional parsing later
            $self->{'node_list_a'}->{inet_ntoa($hostinfo[4]).':'.$n_port} =
                    [inet_ntoa($hostinfo[4]), $n_port];
        }
        if (!scalar(keys %{$self->{'node_list_a'}})) {
            return $self->set_error('ESOCKETFAIL', 'Empty node list.');
        }
        if ($host) {
            my @hostinfo = gethostbyname($host);
            if (scalar(@hostinfo)) {
                my $act_addr_a = inet_ntoa($hostinfo[4]).':'.$port;
                if (exists($self->{'node_list_a'}->{$act_addr_a})) {
                    $self->{'node_addr_a'} = $act_addr_a;
                } else {
                    print STDERR "'$host' doesn't exist in node list - ignoring it!\n" if $debug;
                }
            } else {
                print STDERR "Can't resolve active node hostname '$host': $! - ignoring it!\n" if $debug;
            }
        }
    } else {
        my @hostinfo = gethostbyname($host);
        if (!scalar(@hostinfo)) {
            return $self->set_error('ESOCKETFAIL', "Can't resolve hostname '".$host."'.");
        }
        $self->{'node_addr_a'} = inet_ntoa($hostinfo[4]).':'.$port;
    }
    if ($host) {
        $io_sock_args{'PeerAddr'} = $host;
        $io_sock_args{'PeerPort'} = $port;
        $self->{'sock'} = IO::Socket::INET->new(%io_sock_args)
            or return $self->set_error('ESOCKETFAIL', $@);
    }
    $self;
}

sub send_packet {
    my ($self, $type, $retransmit) = @_;
    my $data;
    my $length = 20 + length($self->{attributes});

    if (!$retransmit) {
        $request_id = ($request_id + 1) & 0xff;
    }

    $self->set_error;
    if ($type == ACCOUNTING_REQUEST || $type == DISCONNECT_REQUEST || $type == COA_REQUEST) {
        $self->{authenticator} = "\0" x 16;
        $self->{authenticator} = $self->calc_authenticator($type, $request_id, $length);
    } else {
        $self->gen_authenticator unless defined $self->{authenticator};
    }

    if (($self->{message_auth} && ($type == ACCESS_REQUEST)) || ($type == STATUS_SERVER)) {
        $length += $RFC3579_MSG_AUTH_ATTR_LEN;
        $data = pack('C C n', $type, $request_id, $length)
                . $self->{authenticator}
                . $self->{attributes}
                . pack('C C', $RFC3579_MSG_AUTH_ATTR_ID, $RFC3579_MSG_AUTH_ATTR_LEN)
                . "\0" x ($RFC3579_MSG_AUTH_ATTR_LEN - 2);

        my $msg_authenticator = $self->hmac_md5($data, $self->{secret});
        $data = pack('C C n', $type, $request_id, $length)
                . $self->{authenticator}
                . $self->{attributes}
                . pack('C C', $RFC3579_MSG_AUTH_ATTR_ID, $RFC3579_MSG_AUTH_ATTR_LEN)
                . $msg_authenticator;
        if ($debug) {
            print STDERR "RFC3579 Message-Authenticator: "._ascii_to_hex($msg_authenticator)." was added to request.\n";
        }
    } else {
        $data = pack('C C n', $type, $request_id, $length)
                . $self->{authenticator}
                . $self->{attributes};
    }

    if ($debug) {
        print STDERR "Sending request:\n";
        print STDERR HexDump($data);
    }
    my $res;
    if (!defined($self->{'node_list_a'})) {
        if ($debug) { print STDERR 'Sending request to: '.$self->{'node_addr_a'}."\n"; }
        $res = $self->{'sock'}->send($data) || $self->set_error('ESENDFAIL', $!);
    } else {
        if (!$retransmit && defined($self->{'sock'})) {
            if ($debug) { print STDERR 'Sending request to active node: '.$self->{'node_addr_a'}."\n"; }
            $res = $self->{'sock'}->send($data) || $self->set_error('ESENDFAIL', $!);
        } else {
            if ($debug) { print STDERR "ReSending request to all cluster nodes.\n"; }
            $self->{'sock'} = undef;
            $self->{'sock_list'} = [];
            my %io_sock_args = (
                        Type => SOCK_DGRAM,
                        Proto => 'udp',
                        Timeout => $self->{'timeout'},
                        LocalAddr => $self->{'localaddr'},
            );
            foreach my $node (keys %{$self->{'node_list_a'}}) {
                if ($debug) { print STDERR 'Sending request to: '.$node."\n"; }
                $io_sock_args{'PeerAddr'} = $self->{'node_list_a'}->{$node}->[0];
                $io_sock_args{'PeerPort'} = $self->{'node_list_a'}->{$node}->[1];
                my $new_sock = IO::Socket::INET->new(%io_sock_args)
                    or return $self->set_error('ESOCKETFAIL', $@);
                $res = $new_sock->send($data) || $self->set_error('ESENDFAIL', $!);
                if ($res) {
                    push @{$self->{'sock_list'}}, $new_sock;
                }
                $res ||= $res;
            }
        }
    }
    return $res;
}

sub recv_packet {
    my ($self, $detect_bad_id) = @_;
    my ($data, $type, $id, $length, $auth, $sh, $resp_attributes);

    $self->set_error;

    if (defined($self->{'sock_list'}) && scalar(@{$self->{'sock_list'}})) {
        $sh = IO::Select->new(@{$self->{'sock_list'}}) or return $self->set_error('ESELECTFAIL');
    } elsif (defined($self->{'sock'})) {
        $sh = IO::Select->new($self->{'sock'}) or return $self->set_error('ESELECTFAIL');
    } else {
        return $self->set_error('ESELECTFAIL');
    }
    my $timeout = $self->{'timeout'};
    my @ready;
    my $from_addr_n;
    my ($start_time, $end_time);
    while ($timeout > 0){
        $start_time = time();
        @ready = $sh->can_read($timeout) or return $self->set_error('ETIMEOUT', $!);
        $end_time = time();
        $timeout -= $end_time - $start_time;
        $from_addr_n = $ready[0]->recv($data, 65536);
        if (defined($from_addr_n)) {
            last;
        }
        if (!defined($from_addr_n) && !defined($self->{'sock_list'})) {
            return $self->set_error('ERECVFAIL', $!);
        }elsif ($debug) {
            print STDERR "Received error/event from one peer:".$!."\n";
        }
    }

    if ($debug) {
        print STDERR "Received response:\n";
        print STDERR HexDump($data);
    }

    if (defined($self->{'sock_list'})) {
        # the sending attempt was 'broadcast' to all cluster nodes
        # switching to single active node
        $self->{'sock'} = $ready[0];
        $self->{'sock_list'} = undef;
        my ($node_port, $node_iaddr) = sockaddr_in($from_addr_n);
        $self->{'node_addr_a'} = inet_ntoa($node_iaddr).':'.$node_port;
        if ($debug) {  print STDERR "Registering new active peeer:".$self->{'node_addr_a'}."\n"; }
    }

    ($type, $id, $length, $auth, $resp_attributes ) = unpack('C C n a16 a*', $data);
    if ($detect_bad_id && defined($id) && ($id != $request_id) ) {
        return $self->set_error('EBADID');
    }

    if ($auth ne $self->calc_authenticator($type, $id, $length, $resp_attributes)) {
        return $self->set_error('EBADAUTH');
    }
    # rewrite attributes only in case of a valid response
    $self->{'attributes'} = $resp_attributes;
    my $rfc3579_msg_auth;
    foreach my $a ($self->get_attributes()) {
        if ($a->{Code} == $RFC3579_MSG_AUTH_ATTR_ID) {
            $rfc3579_msg_auth = $a->{Value};
            last;
        }
    }
    if (defined($rfc3579_msg_auth)) {
        $self->replace_attr_value($RFC3579_MSG_AUTH_ATTR_ID,
                "\0" x ($RFC3579_MSG_AUTH_ATTR_LEN - 2));
        my $hmac_data = pack('C C n', $type, $id, $length)
                        . $self->{'authenticator'}
                        . $self->{'attributes'};
        my $calc_hmac = $self->hmac_md5($hmac_data, $self->{'secret'});
        if ($calc_hmac ne $rfc3579_msg_auth) {
            if ($debug) {
                print STDERR "Received response with INVALID RFC3579 Message-Authenticator.\n";
                print STDERR 'Received   '._ascii_to_hex($rfc3579_msg_auth)."\n";
                print STDERR 'Calculated '._ascii_to_hex($calc_hmac)."\n";
            }
            return $self->set_error('EBADAUTH');
        } elsif ($debug) {
            print STDERR "Received response with VALID RFC3579 Message-Authenticator.\n";
        }
    }

    return $type;
}

sub check_pwd {
    my ($self, $name, $pwd, $nas) = @_;

    $nas = eval { $self->{'sock'}->sockhost() } unless defined($nas);
    $self->clear_attributes;
    $self->add_attributes (
        { Name => 1, Value => $name, Type => 'string' },
        { Name => 2, Value => $pwd, Type => 'string' },
        { Name => 4, Value => $nas || '127.0.0.1', Type => 'ipaddr' }
    );

    $self->send_packet(ACCESS_REQUEST);
    my $rcv = $self->recv_packet();
    return (defined($rcv) and $rcv == ACCESS_ACCEPT);
}

sub clear_attributes {
    my ($self) = @_;

    $self->set_error;

    delete $self->{'attributes'};
    delete $self->{'authenticator'};

    1;
}

sub _decode_enum {
    my ( $name, $value) = @_;

    if ( defined $value && defined( $dict_val{$name}{$value} ) ) {
        $value = $dict_val{$name}{$value}{name};
    }

    return $value;
}

sub _decode_string {
    my ( $self, $vendor, $id, $name, $value, $has_tag ) = @_;

    if ( $id == 2 && $vendor eq NO_VENDOR ) {
        return '<encrypted>';
    }

    if ($has_tag) {
        my $tag = unpack('C', substr($value, 0, 1));
        # rfc2868 section-3.3
        # If the Tag field is greater than 0x1F, it SHOULD be
        # interpreted as the first byte of the following String field.
        if ($tag > 31) {
            print STDERR "Attribute $name has tag value $tag bigger than 31 - ignoring it!\n" if $debug;
            $tag = undef;
        }
        else {
            # cut extracted tag
            substr($value, 0, 1, '');
        }
        return ($value, $tag);
    }

    return ($value);
}

sub _decode_integer {
    my ( $self, $vendor, $id, $name, $value, $has_tag ) = @_;

    my $tag;
    if ($has_tag) {
        $tag = unpack('C', substr($value, 0, 1));
        if ($tag > 31) {
            print STDERR "Attribute $name has tag value $tag bigger than 31 - ignoring it!\n" if $debug;
            $tag = undef;
        }
        else {
            substr($value, 0, 1, "\x00");
        }
    }

    $value = unpack('N', $value);
    return (_decode_enum( $name, $value), $tag);
}

sub _decode_ipaddr {
    my ( $self, $vendor, $id, $name, $value ) = @_;
    return inet_ntoa($value);
}

sub _decode_ipv6addr {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    my $binary_val = unpack( 'B*', $value );
    if ($binary_val) {
        my $ip_val = ip_bintoip( $binary_val, 6 );
        if ($ip_val) {
            return ip_compress_address( $ip_val, 6 );
        }
    }

    return undef;
}

sub _decode_ipv6prefix {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    my ( $skip, $prefix_len, $prefix_val ) = unpack( 'CCB*', $value );
    if ( defined($prefix_len) && $prefix_len < 128 ) {
        my $ip_val = ip_bintoip( $prefix_val, 6 );
        if ($ip_val) {
            $value = ip_compress_address( $ip_val, 6 );
            if ( defined $value ) {
                return "$value/$prefix_len";
            }
        }
    }

    return undef;
}

sub _decode_ifid {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    my @shorts = unpack( 'S>S>S>S>', $value );
    if ( @shorts == 4 ) {
        return sprintf( '%x:%x:%x:%x', @shorts );
    }

    return undef;
}

sub _decode_integer64 {
    my ( $self, $vendor, $id, $name, $value ) = @_;
    return unpack( 'Q>', $value );
}

sub _decode_avpair {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    $value =~ s/^.*=//;
    return $value;
}

sub _decode_sublist {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    # never got a chance to test it, since it seems that Digest attributes only come from clients

    my ( $subid, $subvalue, $sublength, @values );
    while ( length($value) ) {
        ( $subid, $sublength, $value ) = unpack( 'CCa*', $value );
        ( $subvalue, $value ) = unpack( 'a' . ( $sublength - 2 ) . ' a*', $value );
        push @values, "$dict_val{$name}{$subid}{name} = \"$subvalue\"";
    }

    return join( '; ', @values );
}

sub _decode_octets {
    my ( $self, $vendor, $id, $name, $value ) = @_;
    return '0x'.unpack("H*", $value);
}

my %decoder = (
    # RFC2865
    string  => \&_decode_string,
    integer => \&_decode_integer,
    ipaddr  => \&_decode_ipaddr,
    date    => \&_decode_integer,
    time    => \&_decode_integer,
    octets  => \&_decode_octets,
    # RFC3162
    ipv6addr   => \&_decode_ipv6addr,
    ipv6prefix => \&_decode_ipv6prefix,
    ifid       => \&_decode_ifid,
    # RFC6929
    integer64 => \&_decode_integer64,
    # internal
    avpair  => \&_decode_avpair,
    sublist => \&_decode_sublist,
);

sub _decode_value {
    my ( $self, $vendor, $id, $type, $name, $value, $has_tag ) = @_;

    if ( defined $type ) {
        if ( exists $decoder{$type} ) {
            my ($decoded, $tag) = $decoder{$type}->( $self, $vendor, $id, $name, $value, $has_tag );
            return wantarray ? ($decoded, $tag) : $decoded;
        }
        else {
            if ($debug) {
                print {*STDERR} "Unsupported type '$type' for attribute with id: '$id'.\n";
            }
        }
    }
    else {
        if ($debug) {
            print {*STDERR} "Unknown type for attribute with id: '$id'. Check RADIUS dictionaries!\n";
        }
    }

    return undef;
} ## end sub _decode_value

sub get_attributes {
    my $self = shift;
    my ( $vendor, $vendor_id, $name, $id, $length, $value, $type, $rawvalue, $tag, @a );
    my ($attrs) = $self->{attributes};

    $self->set_error;

    while ( length($attrs) ) {
        ( $id, $length, $attrs ) = unpack( 'CCa*', $attrs );
        ( $rawvalue, $attrs ) = unpack( 'a' . ( $length - 2 ) . 'a*', $attrs );

        if ( $id == ATTR_VENDOR ) {
            ( $vendor_id, $id, $length, $rawvalue ) = unpack( 'NCCa*', $rawvalue );
            $vendor = $dict_vendor_id{$vendor_id}{name} // $vendor_id;
        }
        else {
            $vendor = NO_VENDOR;
        }

        my $r = $dict_id{ $vendor }{ $id } // {};

        $name  = $r->{name} // $id;
        $type  = $r->{type};

        ($value, $tag) = $self->_decode_value( $vendor, $id, $type, $name, $rawvalue, $r->{has_tag} );

        push(
            @a, {
                Name     => $tag ? $name . ':' . $tag : $name,
                AttrName => $name,
                Code     => $id,
                Value    => $value,
                RawValue => $rawvalue,
                Vendor   => $vendor,
                Tag      => $tag,
            }
        );
    } ## end while ( length($attrs) )

    return @a;
} ## end sub get_attributes

# returns vendor's ID or 'not defined' string for the attribute
sub vendorID ($) {
    my ($attr) = @_;
    if (defined $attr->{'Vendor'}) {
        return ($dict_vendor_name{ $attr->{'Vendor'} }{'id'} // int($attr->{'Vendor'}));
    } else {
        # look up vendor by attribute name
        my $vendor_name = $dict_name{$attr->{'Name'}}{'vendor'} or return NO_VENDOR;
        my $vendor_id = $dict_vendor_name{$vendor_name}{'id'} or return NO_VENDOR;
        return $vendor_id;
    }
}

sub _encode_enum {
    my ( $name, $value, $format ) = @_;

    if ( defined( $dict_val{$name}{$value} ) ) {
        $value = $dict_val{$name}{$value}{id};
    }

    return pack( $format, int($value) );
}

sub _encode_string {
    my ( $self, $vendor, $id, $name, $value, $tag ) = @_;

    if ( $id == 2 && $vendor eq NO_VENDOR ) {
        $self->gen_authenticator();
        return $self->encrypt_pwd($value);
    }

    # if ($vendor eq WIMAX_VENDOR) {
    #   # add the "continuation" byte
    #   # but no support for attribute splitting for now
    #   return pack('C', 0) . substr($_[0], 0, 246);
    # }

    if (defined $tag) {
        $value = pack('C', $tag) . $value;
    }

    return $value;
}

sub _encode_integer {
    my ( $self, $vendor, $id, $name, $value, $tag ) = @_;
    $value = _encode_enum( $name, $value, 'N' );
    if (defined $tag) {
        # tag added to 1st byte, not extending the value length
        substr($value, 0, 1, pack('C', $tag) );
    }
    return $value;
}

sub _encode_ipaddr {
    my ( $self, $vendor, $id, $name, $value ) = @_;
    return inet_aton($value);
}

sub _encode_ipv6addr {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    my $expanded_val = ip_expand_address( $value, 6 );
    if ($expanded_val) {
        $value = ip_iptobin( $expanded_val, 6 );
        if ( defined $value ) {
            return pack( 'B*', $value );
        }
    }

    return undef;
}

sub _encode_ipv6prefix {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    my ( $prefix_val, $prefix_len ) = split( /\//, $value, 2 );
    if ( defined $prefix_len ) {
        my $expanded_val = ip_expand_address( $prefix_val, 6 );
        if ($expanded_val) {
            $value = ip_iptobin( $expanded_val, 6 );
            if ( defined $value ) {
                return pack( 'CCB*', 0, $prefix_len, $value );
            }
        }
    }

    return undef;
}

sub _encode_ifid {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    my @shorts = map { hex() } split( /:/, $value, 4 );
    if ( @shorts == 4 ) {
        return pack( 'S>S>S>S>', @shorts );
    }

    return undef;
}

sub _encode_integer64 {
    my ( $self, $vendor, $id, $name, $value ) = @_;
    return pack( 'Q>', $value );
}

sub _encode_avpair {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    $value = "$name=$value";
    return substr( $value, 0, 253 );
}

sub _encode_sublist {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    # Digest attributes look like:
    # Digest-Attributes = 'Method = "REGISTER"'

    my @pairs;
    if ( ref($value) ) {
        # hashref
        return undef if ( ref($value) ne 'HASH' );
        foreach my $key ( keys %{$value} ) {
            push @pairs, [ $key => $value->{$key} ];
        }
    }
    else {
        # string
        foreach my $z ( split( /\"\; /, $value ) ) {
            my ( $subname, $subvalue ) = split( /\s+=\s+\"/, $z, 2 );
            $subvalue =~ s/\"$//;
            push @pairs, [ $subname => $subvalue ];
        }
    }

    $value = '';
    foreach my $da (@pairs) {
        my ( $subname, $subvalue ) = @{$da};
        my $subid = $dict_val{$name}->{$subname}->{id};
        next if ( !defined($subid) );
        $value .= pack( 'CC', $subid, length($subvalue) + 2 ) . $subvalue;
    }

    return $value;
} ## end sub _encode_sublist

sub _encode_octets {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    my $new_value = '';
    foreach my $c ( split( //, $value ) ) {
        $new_value .= pack( 'C', ord($c) );
    }

    return $new_value;
}

sub _encode_byte {
    my ( $self, $vendor, $id, $name, $value ) = @_;
    return _encode_enum( $name, $value, 'C' );
}

sub _encode_short {
    my ( $self, $vendor, $id, $name, $value ) = @_;
    return _encode_enum( $name, $value, 'n' );
}

sub _encode_signed {
    my ( $self, $vendor, $id, $name, $value ) = @_;
    return pack( 'l>', $value );
}

sub _encode_comboip {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    if ( $value =~ m/^\d+\.\d+\.\d+.\d+/ ) {
        # IPv4 address
        return inet_aton($value);
    }

    # currently unsupported, use IPv4
    return undef;
}

sub _encode_tlv {
    my ( $self, $vendor, $id, $name, $value ) = @_;

    return undef if ( ref($value) ne 'ARRAY' );

    my $new_value = '';
    foreach my $sattr ( sort { $a->{TLV_ID} <=> $b->{TLV_ID} } @{$value} ) {
        my $sattr_name = $sattr->{Name};
        my $sattr_type = $sattr->{Type} // $dict_name{$sattr_name}{type};
        my $sattr_id   = $dict_name{$sattr_name}{id} // int($sattr_name);

        my $svalue = $self->_encode_value( $vendor, $sattr_id, $sattr_type, $sattr_name, $sattr->{Value} );
        if ( defined $svalue ) {
            $new_value .= pack( 'CC', $sattr_id, length($svalue) + 2 ) . $svalue;
        }
    }

    return $new_value;
}

my %encoder = (
    # RFC2865
    string  => \&_encode_string,
    integer => \&_encode_integer,
    ipaddr  => \&_encode_ipaddr,
    date    => \&_encode_integer,
    time    => \&_encode_integer,
    # RFC3162
    ipv6addr   => \&_encode_ipv6addr,
    ipv6prefix => \&_encode_ipv6prefix,
    ifid       => \&_encode_ifid,
    # RFC6929
    integer64 => \&_encode_integer64,
    # internal
    avpair  => \&_encode_avpair,
    sublist => \&_encode_sublist,
    octets  => \&_encode_octets,
    # WiMAX
    byte       => \&_encode_byte,
    short      => \&_encode_short,
    signed     => \&_encode_signed,
    'combo-ip' => \&_encode_comboip,
    tlv        => \&_encode_tlv,
);

sub _encode_value {
    my ( $self, $vendor, $id, $type, $name, $value, $tag ) = @_;

    if ( defined $type ) {
        if ( exists $encoder{$type} ) {
            return $encoder{$type}->( $self, $vendor, $id, $name, $value, $tag );
        }
        else {
            if ($debug) {
                print {*STDERR} "Unsupported type '$type' for attribute with name: '$name'.\n";
            }
        }
    }
    else {
        if ($debug) {
            print {*STDERR} "Unknown type for attribute with name: '$name'. Check RADIUS dictionaries!\n";
        }
    }

    return undef;
} ## end sub _encode_value

sub add_attributes {
    my ($self, @attr) = @_;
    my ($a, $vendor, $id, $type, $value);
    my @a = ();
    $self->set_error;

    # scan for WiMAX TLV
    my %request_tlvs;
    for my $attr (@attr) {
        my $attr_name = $attr->{Name};
        # tagged attribute in 'name:tag' form
        if ($attr_name =~ /^([\w-]+):(\d+)$/) {
            $attr->{Name} = $1;
            $attr->{Tag} = $2;
            $attr_name = $1;
        }

        die 'unknown attr name '.$attr_name if (! exists $dict_name{$attr_name});

        $id = $dict_name{$attr_name}{id} // int($attr_name);
        $vendor = vendorID($attr);
        if (exists($dict_name{$attr_name}{'tlv'})) {
            # this is a TLV attribute
            my $tlv = $dict_name{$attr_name}{'tlv'};
            # insert TLV type so we can order them by type inside of the container attribute
            $attr->{'TLV_ID'} = $id;

            unless (exists($request_tlvs{$tlv})) {
                # this is a first attribute of this TLV in the request
                my $new_attr = {
                    Name => $tlv, Type => 'tlv',
                    Value => [ $attr ]
                };
                $request_tlvs{$tlv} = $new_attr;
                push @a, $new_attr;
            } else {
                my $tlv_list = $request_tlvs{$tlv}->{'Value'};
                next unless ref($tlv_list); # should not happen
                push @{$tlv_list}, $attr;
            }
        } else {
            # normal attribute, just copy over
            push @a, $attr;
        }
    }

    for $a (@a) {
        $id = $dict_name{ $a->{Name} }{id} // int($a->{Name});
        $type = $a->{Type} // $dict_name{ $a->{Name} }{type};
        $vendor = vendorID($a);
        my $need_tag = (defined $a->{Tag}) || $dict_name{ $a->{Name} }{has_tag};
        if ($need_tag) {
            $a->{Tag} //= 0;
            if ($a->{Tag} < 1 || $a->{Tag} > 31) {
                print STDERR "Tag value is out of range [1..31] for attribute ".$a->{Name} if $debug;
                next;
            }
        }

        if ($vendor eq WIMAX_VENDOR) {
            # WiMAX uses non-standard VSAs - include the continuation byte
        }

        unless (defined($value = $self->_encode_value($vendor, $id, $type, $a->{Name}, $a->{Value}, $a->{Tag}))) {
            print STDERR "Unable to encode attribute $a->{Name} ($id, $type, $vendor) with value '$a->{Value}'\n" if $debug;
            next;
        }

        if ($debug) {
            printf STDERR "Adding attribute %s (%s, %s, %s) with value '%s'%s\n",
                    $a->{Name}, $id, $type, $vendor,
                    $a->{Value},
                    ($a->{Tag} ? sprintf(' (tag:%d)', $a->{Tag}) : '');
        }

        if ( $vendor eq NO_VENDOR ) {
            # tag already included in $value, if any
            $self->{'attributes'} .= pack('C C', $id, length($value) + 2) . $value;
        } else {
            # VSA
            # pack vendor-ID + vendor-type + vendor-length
            if ($vendor eq WIMAX_VENDOR) {
                # add continuation byte
                $value = pack('N C C C', $vendor, $id, length($value) + 3, 0) . $value;
            } else {
                # tag already included in $value, if any
                $value = pack('N C C', $vendor, $id, length($value) + 2) . $value;
            }

            # add the normal RADIUS attribute header: type + length
            $self->{'attributes'} .= pack('C C', ATTR_VENDOR, length($value) + 2) . $value;
        }
    }

    return 1;
}

sub replace_attr_value {
    my ($self, $id, $value) = @_;
    my $length = length($self->{'attributes'});
    my $done = 0;
    my $cur_pos = 0;
    while ($cur_pos < $length) {
        my ($cur_id, $cur_len) = unpack('C C', substr($self->{'attributes'}, $cur_pos, 2));
        if ($cur_id == $id) {
            if (length($value) != ($cur_len - 2)) {
                if ($debug) {
                    print STDERR "Trying to replace attribute ($id) with value which has different length\n";
                }
                last;
            }
            substr($self->{'attributes'}, $cur_pos + 2, $cur_len - 2, $value);
            $done = 1;
            last;
        }
        $cur_pos += $cur_len;
    }
    return $done;
}

sub calc_authenticator {
    my ($self, $type, $id, $length, $attributes) = @_;
    my ($hdr, $ct);

    $self->set_error;

    $hdr = pack('C C n', $type, $id, $length);
    $ct = Digest::MD5->new;
    $ct->add ($hdr, $self->{'authenticator'},
                (defined($attributes)) ? $attributes : $self->{'attributes'},
                $self->{'secret'});
    $ct->digest();
}

sub gen_authenticator {
    my ($self) = @_;
    my ($ct);

    $self->set_error;
    sub rint { int rand(2 ** 32 - 1) };
    $self->{'authenticator'} =
        pack "L4", rint(), rint(), rint(), rint();
}

sub encrypt_pwd {
    my ($self, $pwd) = @_;
    my ($i, $ct, @pwdp, @encrypted);

    $self->set_error;
    $ct = Digest::MD5->new();

    my $non_16 = length($pwd) % 16;
    $pwd .= "\0" x (16 - $non_16) if $non_16;
    @pwdp = unpack('a16' x (length($pwd) / 16), $pwd);
    for $i (0..$#pwdp) {
        my $authent = $i == 0 ? $self->{'authenticator'} : $encrypted[$i - 1];
        $ct->add($self->{'secret'},  $authent);
        $encrypted[$i] = $pwdp[$i] ^ $ct->digest();
    }
    return join('',@encrypted);
}
use vars qw(%included_files);

sub load_dictionary {
    shift;
    my $file = shift;
    # options, format => {freeradius|gnuradius|default}
    my %opt = @_;
    my $freeradius_dict = (($opt{format} // '') eq 'freeradius') ? 1 : 0;
    my $gnuradius_dict = (($opt{format} // '') eq 'gnuradius') ? 1 : 0;

    my ($cmd, $name, $id, $type, $vendor, $tlv, $extra, $has_tag);
    my $dict_def_vendor = NO_VENDOR;

    $file ||= DEFAULT_DICTIONARY;

    # prevent infinite loop in the include files
    return undef if exists($included_files{$file});
    $included_files{$file} = 1;
    my $fh = FileHandle->new($file) or die "Can't open dictionary '$file' ($!)\n";
    printf STDERR "Loading dictionary %s using %s format\n", $file, ($freeradius_dict ? 'FreeRADIUS' : 'default')  if $debug;

    while (my $line = <$fh>) {
        chomp $line;
        next if ($line =~ /^\s*$/ || $line =~ /^#/);

        if ($freeradius_dict) {
            # ATTRIBUTE name number type [options]
            ($cmd, $name, $id, $type, $extra) = split(/\s+/, $line);
            $vendor = undef;
        }
        elsif ($gnuradius_dict) {
            # ATTRIBUTE name number type [vendor] [flags]
            ($cmd, $name, $id, $type, $vendor, undef) = split(/\s+/, $line);
            # flags looks like '[LR-R-R]=P'
            $vendor = NO_VENDOR if ($vendor && ($vendor eq '-' || $vendor =~ /^\[/));
        }
        else {
            # our default format (Livingston radius)
            ($cmd, $name, $id, $type, $vendor) = split(/\s+/, $line);
        }

        $cmd = lc($cmd);
        if ($cmd eq 'attribute') {
            # Vendor was previously defined via BEGIN-VENDOR
            $vendor ||= $dict_def_vendor // NO_VENDOR;

            $has_tag = 0;
            if ($extra && $extra !~ /^#/) {
                my(@p) = split(/,/, $extra);
                $has_tag = grep /has_tag/, @p;
            }

            $dict_name{ $name } = {
                    id      => $id,
                    type    => $type,
                    vendor  => $vendor,
                    has_tag => $has_tag,
                };

            if (defined($tlv)) {
                # inside of a TLV definition
                $dict_id{$vendor}{$id}{'tlv'} = $tlv;
                $dict_name{$name}{'tlv'} = $tlv;
                # IDs of TLVs are only unique within the master attribute, not in the dictionary
                # so we have to use a composite key
                $dict_id{$vendor}{$tlv.'/'.$id}{'name'} = $name;
                $dict_id{$vendor}{$tlv.'/'.$id}{'type'} = $type;
            } else {
                $dict_id{$vendor}{$id} = {
                        name    => $name,
                        type    => $type,
                        has_tag => $has_tag,
                    };
            }
        } elsif ($cmd eq 'value') {
            next unless exists($dict_name{$name});
            $dict_val{$name}->{$type}->{'name'} = $id;
            $dict_val{$name}->{$id}->{'id'} = $type;
        } elsif ($cmd eq 'vendor') {
            $dict_vendor_name{$name}{'id'} = $id;
            $dict_vendor_id{$id}{'name'} = $name;
        } elsif ($cmd eq 'begin-vendor') {
            $dict_def_vendor = $name;
            if (! $freeradius_dict) {
                # force format
                $freeradius_dict = 1;
                print STDERR "Detected BEGIN-VENDOR, switch to FreeRADIUS dictionary format\n" if $debug;
            }
        } elsif ($cmd eq 'end-vendor') {
            $dict_def_vendor = NO_VENDOR;
        } elsif ($cmd eq 'begin-tlv') {
            # FreeRADIUS dictionary syntax for defining WiMAX TLV
            if (exists($dict_name{$name}) and $dict_name{$name}{'type'} eq 'tlv') {
                # This name was previously defined as an attribute with TLV type
                $tlv = $name;
            }
        } elsif ($cmd eq 'end-tlv') {
            undef($tlv);
        } elsif ($cmd eq '$include') {
            my @path = split("/", $file);
            pop @path; # remove the filename at the end
            my $path = ( $name =~ /^\// ) ? $name : join("/", @path, $name);
            load_dictionary('', $path, %opt);
        }
    }
    $fh->close;
#   print Dumper(\%dict_name);
    1;
}

sub clear_dictionary {
    shift;
    %dict_id = ();
    %dict_name = ();
    %dict_val = ();
    %dict_vendor_id = ();
    %dict_vendor_name = ();
    %included_files = ();
}

sub set_timeout {
    my ($self, $timeout) = @_;

    $self->{'timeout'} = $timeout;
    $self->{'sock'}->timeout($timeout) if (defined $self->{'sock'});
    if (defined $self->{'sock_list'}) {
        foreach my $sock (@{$self->{'sock_list'}}) {
            $sock->timeout($timeout);
        }
    }

    1;
}

sub set_error {
    my ($self, $error, $comment) = @_;
    $@ = undef;
    $radius_error = $self->{'error'} = (defined($error) ? $error : 'ENONE');
    $error_comment = $self->{'error_comment'} = (defined($comment) ? $comment : '');
    undef;
}

sub get_error {
    my ($self) = @_;

    if (!ref($self)) {
        return $radius_error;
    } else {
        return $self->{'error'};
    }
}

sub strerror {
    my ($self, $error) = @_;

    my %errors = (
        'ENONE', 'none',
        'ESELECTFAIL', 'select creation failed',
        'ETIMEOUT', 'timed out waiting for packet',
        'ESOCKETFAIL', 'socket creation failed',
        'ENOHOST',  'no host specified',
        'EBADAUTH', 'bad response authenticator',
        'ESENDFAIL', 'send failed',
        'ERECVFAIL', 'receive failed',
        'EBADSERV', 'unrecognized service',
        'EBADID', 'response to unknown request'
    );

    if (!ref($self)) {
        return $errors{$radius_error};
    }
    return $errors{ (defined($error) ? $error : $self->{'error'} ) };
}

sub error_comment {
    my ($self) = @_;

    if (!ref($self)) {
        return $error_comment;
    } else {
        return $self->{'error_comment'};
    }
}

sub get_active_node {
    my ($self) = @_;
    return $self->{'node_addr_a'};
}

sub hmac_md5 {
    my ($self, $data, $key) = @_;
    my $ct = Digest::MD5->new;

    if (length($key) > $HMAC_MD5_BLCKSZ) {
        $ct->add($key);
        $key = $ct->digest();
    }
    my $ipad = $key ^ ("\x36" x $HMAC_MD5_BLCKSZ);
    my $opad = $key ^ ("\x5c" x $HMAC_MD5_BLCKSZ);
    $ct->reset();
    $ct->add($ipad, $data);
    my $digest1 = $ct->digest();
    $ct->reset();
    $ct->add($opad, $digest1);
    return $ct->digest();
}

sub _ascii_to_hex {
    my  ($string) = @_;
    my $hex_res = '';
    foreach my $cur_chr (unpack('C*',$string)) {
        $hex_res .= sprintf("%02X ", $cur_chr);
    }
    return $hex_res;
}


1;
__END__

=head1 NAME

Authen::Radius - provide simple Radius client facilities

=head1 SYNOPSIS

  use Authen::Radius;

  $r = new Authen::Radius(Host => 'myserver', Secret => 'mysecret');
  print "auth result=", $r->check_pwd('myname', 'mypwd'), "\n";

  $r = new Authen::Radius(Host => 'myserver', Secret => 'mysecret');
  Authen::Radius->load_dictionary();
  $r->add_attributes (
        { Name => 'User-Name', Value => 'myname' },
        { Name => 'Password', Value => 'mypwd' },
# RFC 2865 http://www.ietf.org/rfc/rfc2865.txt calls this attribute
# User-Password. Check your local RADIUS dictionary to find
# out which name is used on your system
#       { Name => 'User-Password', Value => 'mypwd' },
        { Name => 'h323-return-code', Value => '0' }, # Cisco AV pair
        { Name => 'Digest-Attributes', Value => { Method => 'REGISTER' } }
  );
  $r->send_packet(ACCESS_REQUEST) and $type = $r->recv_packet();
  print "server response type = $type\n";
  for $a ($r->get_attributes()) {
    print "attr: name=$a->{'Name'} value=$a->{'Value'}\n";
  }

=head1  DESCRIPTION

The C<Authen::Radius> module provides a simple class that allows you to
send/receive Radius requests/responses to/from a Radius server.

=head1 CONSTRUCTOR

=over 4

=item new ( Host => HOST, Secret => SECRET [, TimeOut => TIMEOUT]
    [,Service => SERVICE] [, Debug => Bool] [, LocalAddr => hostname[:port]]
    [,Rfc3579MessageAuth => Bool] [,NodeList= NodeListArrayRef])

Creates & returns a blessed reference to a Radius object, or undef on
failure.  Error status may be retrieved with C<Authen::Radius::get_error>
(errorcode) or C<Authen::Radius::strerror> (verbose error string).

The default C<Service> is C<radius>, the alternative is C<radius-acct>.
If you do not specify port in the C<Host> as a C<hostname:port>, then port
specified in your F</etc/services> will be used. If there is nothing
there, and you did not specify port either then default is 1645 for
C<radius> and 1813 for C<radius-acct>.

Optional parameter C<Debug> with a Perl "true" value turns on debugging
(verbose mode).

Optional parameter C<LocalAddr> may contain local IP/host bind address from
which RADIUS packets are sent.

Optional parameter C<Rfc3579MessageAuth> with a Perl "true" value turns on generating
of Message-Authenticator for Access-Request (RFC3579, section 3.2).
The Message-Authenticator is always generated for Status-Server packets.

Optional parameter C<NodeList> may contain a Perl reference to an array, containing a list of
Radius Cluster nodes. Each nodes in the list can be specified using a hostname or IP (with an optional
port number), i.e. 'radius1.mytel.com' or 'radius.myhost.com:1812'. Radius Cluster contains a set of Radius
servers, at any given moment of time only one server is considered to be "active"
(so requests are send to this server).
How the active node is determined? Initially in addition to the C<NodeList>
parameter you may supply the C<Host> parameter and specify which server should
become the first active node. If this parameter is absent, or the current
active node does not reply anymore, the process of "discovery" will be
performed: a request will be sent to all nodes and the consecutive communication
continues with the node, which will be the first to reply.

=back

=head1 METHODS

=over 4

=item load_dictionary ( [ DICTIONARY ], [format => 'freeradius' | 'gnuradius'] )

Loads the definitions in the specified Radius dictionary file (standard
Livingston radiusd format). Tries to load C</etc/raddb/dictionary> when no
argument is specified, or dies. C<format> should be specified if dictionary has
other format (currently supported: FreeRADIUS and GNU Radius)

NOTE: you need to load valid dictionary if you plan to send RADIUS requests
with attributes other than just C<User-Name>/C<Password>.

=item check_pwd ( USERNAME, PASSWORD [,NASIPADDRESS] )

Checks with the RADIUS server if the specified C<PASSWORD> is valid for user
C<USERNAME>. Unless C<NASIPADDRESS> is specified, the script will attempt
to determine it's local IP address (IP address for the RADIUS socket) and
this value will be placed in the NAS-IP-Address attribute.
This method is actually a wrapper for subsequent calls to
C<clear_attributes>, C<add_attributes>, C<send_packet> and C<recv_packet>. It
returns 1 if the C<PASSWORD> is correct, or undef otherwise.

=item add_attributes ( { Name => NAME, Value => VALUE [, Type => TYPE] [, Vendor => VENDOR] [, Tag => TAG ] }, ... )

Adds any number of Radius attributes to the current Radius object. Attributes
are specified as a list of anon hashes. They may be C<Name>d with their
dictionary name (provided a dictionary has been loaded first), or with
their raw Radius attribute-type values. The C<Type> pair should be specified
when adding attributes that are not in the dictionary (or when no dictionary
was loaded). Values for C<TYPE> can be 'C<string>', 'C<integer>', 'C<ipaddr>',
'C<ipv6addr>', 'C<ipv6prefix>', 'C<ifid>' or 'C<avpair>'. The C<VENDOR> may be
Vendor's name from the dictionary or their integer id. For tagged attributes
(RFC2868) tag can be specified in C<Name> using 'Name:Tag' format, or by
using C<Tag> pair. TAG value is expected to be an integer.

=item get_attributes

Returns a list of references to anon hashes with the following key/value
pairs : { Name => NAME, Code => RAWTYPE, Value => VALUE, RawValue =>
RAWVALUE, Vendor => VENDOR, Tag => TAG, AttrName => NAME }. Each hash
represents an attribute in the current object. The C<Name> and C<Value> pairs
will contain values as translated by the dictionary (if one was loaded). The
C<Code> and C<RawValue> pairs always contain the raw attribute type & value as
received from the server.  If some attribute doesn't exist in dictionary or
type of attribute not specified then corresponding C<Value> undefined and
C<Name> set to attribute ID (C<Code> value). For tagged attribute (RFC2868), it
will include the tag into the C<NAME> as 'Name:Tag'. Original Name is stored in
C<AttrName>.  Also value of tag is stored in C<Tag> (undef for non-tagged
attributes).

=item clear_attributes

Clears all attributes for the current object.

=item send_packet ( REQUEST_TYPE, RETRANSMIT )

Packs up a Radius packet based on the current secret & attributes and
sends it to the server with a Request type of C<REQUEST_TYPE>. Exported
C<REQUEST_TYPE> methods are C<ACCESS_REQUEST>, C<ACCESS_ACCEPT>,
C<ACCESS_REJECT>, C<ACCESS_CHALLENGE>, C<ACCOUNTING_REQUEST>, C<ACCOUNTING_RESPONSE>,
C<ACCOUNTING_STATUS>, C<STATUS_SERVER>, C<DISCONNECT_REQUEST>, C<DISCONNECT_ACCEPT>,
C<DISCONNECT_REJECT>, C<COA_REQUEST>, C<COA_ACCEPT>, C<COA_REJECT>, C<COA_ACK>,
and C<COA_NAK>.
Returns the number of bytes sent, or undef on failure.

If the RETRANSMIT parameter is provided and contains a non-zero value, then
it is considered that we are re-sending the request, which was already sent
previously. In this case the previous value of packet identifier is used.

=item recv_packet ( DETECT_BAD_ID )

Receives a Radius reply packet. Returns the Radius Reply type (see possible
values for C<REQUEST_TYPE> in method C<send_packet>) or undef on failure. Note
that failure may be due to a failed recv() or a bad Radius response
authenticator. Use C<get_error> to find out.

If the DETECT_BAD_ID parameter is supplied and contains a non-zero value, then
calculation of the packet identifier is performed before authenticator check
and EBADID error returned in case when packet identifier from the response
doesn't match to the request. If the DETECT_BAD_ID is not provided or contains zero value then
EBADAUTH returned in such case.

=item set_timeout ( TIMEOUT )

Sets socket I/O activity timeout. C<TIMEOUT> should be specified in floating seconds
since the epoch.

=item get_error

Returns the last C<ERRORCODE> for the current object. Errorcodes are one-word
strings always beginning with an 'C<E>'.

=item strerror ( [ ERRORCODE ] )

Returns a verbose error string for the last error for the current object, or
for the specified C<ERRORCODE>.

=item error_comment

Returns the last error explanation for the current object. Error explanation
is generated by system call.

=item get_active_node

Returns currently active radius node in standard numbers-and-dots notation with
port delimited by colon.

=back

=head1 AUTHOR

Carl Declerck <carl@miskatonic.inbe.net> - original design
Alexander Kapitanenko <kapitan at portaone.com> and Andrew
Zhilenko <andrew at portaone.com> - later modifications.

PortaOne Development Team <perl-radius at portaone.com> is
the current module's maintainer at CPAN.

=cut

