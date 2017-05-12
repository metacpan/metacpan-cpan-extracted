package App::MadEye::Plugin::Agent::FTP;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use Socket qw(IPPROTO_TCP TCP_NODELAY SOL_SOCKET SOCK_STREAM);
use IO::Socket::INET;
use IO::Select;

sub is_dead {
    my ($self, $host) = @_;

    my $conf = $self->config->{config};
    my $message         = $conf->{message} or die "missing message";
    my $port            = $conf->{port}            || 21;
    my $connect_timeout = $conf->{connect_timeout} || 10;
    my $select_timeout  = $conf->{select_timeout}  || 10;

    my $sock = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Timeout  => $connect_timeout,
    );
    unless ($sock) {
        return "Cannot connect Socket to $host:$port : $!";
    }
    $sock->blocking(0);
    setsockopt($sock, IPPROTO_TCP, TCP_NODELAY, pack("l", 1)) or die;
    $sock->autoflush(1);

    my $select = IO::Select->new;
    $select->add($sock);

    my ($can_read,) = $select->can_read($select_timeout);
    if ($can_read) {
        my $line = <$sock>;
        $sock->close;

        if ($line =~ /$message/) {
            return; # This server is still alive!
        } else {
            return "this ftp server is dead!! : $line";
        }
    } else {
        $sock->close;
        return "pure-ftpd connection timeout : $host";
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::FTP - monitoring FTP

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        message:
            required: yes
            type: str
        port:
            required: yes
            type: int
        connect_timeout:
            required: no
            type: int
        select_timeout:
            required: no
            type: int

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<App::MadEye>

