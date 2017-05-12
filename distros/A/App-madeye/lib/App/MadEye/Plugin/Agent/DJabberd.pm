package App::MadEye::Plugin::Agent::DJabberd;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use Socket qw(IPPROTO_TCP TCP_NODELAY SOL_SOCKET SOCK_STREAM);
use IO::Socket::INET;
use IO::Select;

sub is_dead {
    my ($self, $host) = @_;

    my $conf = $self->config->{config};
    my $admin_port = $conf->{admin_port} or die "missing admin port";
    my $open_socket_timeout = $conf->{open_socket_timeout} || 10;
    my $select_timeout      = $conf->{select_timeout}      || 3;

    my $sock = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $admin_port,
        Timeout  => $open_socket_timeout,
    );
    unless ($sock) {
        return "Cannot open Socket to $host:$admin_port : $!";
    }
    $sock->blocking(0);
    $sock->setsockopt( IPPROTO_TCP, TCP_NODELAY, pack( "l", 1 ) ) or die;
    $sock->autoflush(1);

    $sock->print("version\r\n");

    my $select = IO::Select->new;
    $select->add($sock);

    my ( $can_read, ) = $select->can_read($select_timeout);
    unless ($can_read) {
        $sock->close;

        return "connection timeout : $host";
    }

    my $line = <$sock>;
    $sock->close();

    if ( $line =~ /\d+\.\d+/ ) {
        return;
    }
    else {
        return "djabberd response is invaild : $line";
    }
}

1;
__END__

=for stopwords DJabberd

=head1 NAME

App::MadEye::Plugin::Agent::DJabberd - monitoring DJabberd

=head1 SYNOPSIS

    - module: Agent::DJabberd
      config:
        admin_port: 1000
        open_socket_timeout: 10
        select_timeout: 3

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        admin_port:
            required: yes
            type: int
        open_socket_timeout:
            required: no
            type: int
        select_timeout:
            required: no
            type: int

=head1 SEE ALSO

L<App::MadEye>, L<DJabberd>

