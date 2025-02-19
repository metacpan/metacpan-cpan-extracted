package App::ReslirpTunnel::RPC;

use Socket::MsgHdr;
use IO::Socket::UNIX;

use strict;
use warnings;
use JSON;
use POSIX;

sub new {
    my $class = shift;
    my $socket = shift;
    my $self = \$socket;
    bless $self, $class;
    return $self;
}

sub recv_packet {
    my $self = shift;
    my $header = $self->_read_bytes(4);
    my $len = unpack("N", $header);
    my $data = $self->_read_bytes($len);
    utf8::decode($data);
    # warn "Packet received: $data\n";
    my $r = JSON::decode_json($data);
    return $r;
}

sub _read_bytes {
    my ($self, $len) = @_;
    my $buf = "";

    while (length $buf < $len) {
        my $n = sysread($$self, $buf, $len - length $buf, length $buf);
        if (!defined $n) {
            # warn "read error, ignoring it: $!";
            sleep 1;
        } elsif ($n == 0) {
            die "unexpected EOF";
        }
    }
    return $buf;
}

sub send_packet {
    my ($self, $data) = @_;
    my $json = JSON::encode_json($data);
    # warn "sending $json\n";
    utf8::encode($json);
    my $bytes = pack("N", length $json) . $json;
    while (length $bytes) {
        my $n = syswrite($$self, $bytes);
        if (!defined $n) {
            # warn "write error, ignoring: $!";
            sleep 1;
        }
        substr($bytes, 0, $n) = "";
    }
}

sub recv_fd {
    my $self = shift;
    # receive tap file descriptor through $parent_socket
    my $msg_mdr = Socket::MsgHdr->new(buflen => 8192, controllen => 256);
    recvmsg($$self, $msg_mdr);
    my ($level, $type, $data) = $msg_mdr->cmsghdr();
    unpack('i', $data) // die "Failed to receive tap file descriptor: $!";
}

sub send_fd {
    my ($self, $fd) = @_;
    my $msg_hdr = Socket::MsgHdr->new(buflen => 512);
    $msg_hdr->cmsghdr(SOL_SOCKET,              # cmsg_level
                      SCM_RIGHTS,              # cmsg_type
                      pack("i", fileno($fd))); # cmsg_data
    sendmsg($$self, $msg_hdr)
        or die "sendmsg failed: $!";
}

1;
