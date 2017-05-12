#!/usr/bin/perl

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Socket;

$AnyEvent::PacketReader::debug = -1;

die <<EOU if @ARGV < 2 or @ARGV > 3;
Usage:
    $0 local_port dst_host[:dst_port] [header_templ]

EOU

my ($local_port, $dst, $header_templ) = @ARGV;
my ($dst_host, $dst_port) = $dst =~ /^(.*?)(?::(\d+))?$/;
defined $dst_host or die "invalid destination host expecification\n";
$dst_port = $local_port unless defined $dst_port;

tcp_server undef, $local_port, sub { PacketProxy->new($_[0], $dst_host, $dst_port) };

AE::cv->recv;

package PacketProxy;

use AnyEvent::Socket;
use AnyEvent::PacketForwarder;
use Method::WeakCallback qw(weak_method_callback);

my %pp_by_client_fd;

sub new {
    my ($class, $client_socket, $dst_host, $dst_port) = @_;
    my $self = { client_socket => $client_socket,
                 client_fd => fileno $client_socket };
    bless $self;
    $pp_by_client_fd{$self->{client_fd}} = $self;

    warn "connecting to $dst_host:$dst_port\n";
    tcp_connect $dst_host, $dst_port, weak_method_callback($self, '_on_connected_to_server');

    $self;
}

sub _on_connected_to_server {
    my ($self, $server_socket) = @_;
    if (defined $server_socket) {
        $self->{server_socket} = $server_socket;
        my $client_socket = $self->{client_socket};

        use Data::Dumper;
        print STDERR Data::Dumper->Dump([$self], [qw($self)]);

        $self->{c2s_forwarder} = packet_forwarder $client_socket, $server_socket, $header_templ,
            weak_method_callback($self, '_on_data', 'c2s');
        $self->{s2c_forwarder} = packet_forwarder $server_socket, $client_socket, $header_templ,
            weak_method_callback($self, '_on_data', 's2c');
    }
    else {
        warn "unable to connect to remote server: $!\n";
        delete $pp_by_client_fd{$self->{client_fd}};
    }
}

sub _on_data {
    my ($self, $dir, undef, $fatal) = @_;
    if (defined $_[2]) {
        $self->_on_packet($dir, $_[2]);
    }
    else {
        shutdown($self->{client_socket}, 0);
        if ($fatal) {
            shutdown($self->{server_socket}, 1);
            undef $self->{c2s_forwarder};
        }
        if ($dir eq 's2c') {
            shutdown($self->{server_socket}, 0);
            if ($fatal) {
                shutdown($self->{client_socket}, 1);
                undef $self->{c2s_forwarder};
                delete $pp_by_client_fd{$self->{client_fd}};
            }
        }
    }
}

sub _on_packet {
    my ($self, $dir) = @_;
    _hexdump($_[2], "$dir:");
}

sub _hexdump {
    no warnings qw(uninitialized);
    while ($_[0] =~ /(.{1,32})/smg) {
        my $line = $1;
        my @c= (( map { sprintf "%02x",$_ } unpack('C*', $line)),
                (("  ") x 32))[0..31];
        $line=~s/(.)/ my $c=$1; unpack("c",$c)>=32 ? $c : '.' /egms;
        print STDERR "$_[1] ", join(" ", @c, '|', $line), "\n";
    }
    print STDERR "\n";

}

sub DESTROY {
    my $self = shift;
    warn "proxy for file descriptor $self->{client_fd} destroyed\n";
}
