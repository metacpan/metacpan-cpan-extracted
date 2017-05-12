package App::MadEye::Plugin::Agent::Gearmand;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use Gearman::Util;
use Socket qw(IPPROTO_TCP TCP_NODELAY SOL_SOCKET SOCK_STREAM);
use IO::Socket::INET;
use IO::Select;

my $MSG = "WATCHINGWATCHING";

sub is_dead {
    my ( $self, $host ) = @_;

    my $conf            = $self->config->{config};
    my $port            = $conf->{port}            || 7003;
    my $connect_timeout = $conf->{connect_timeout} || 10;
    my $select_timeout  = $conf->{select_timeout}  || 10;

    my $sock = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Timeout  => $connect_timeout,
    );
    unless ($sock) {
        return "Cannot open Socket to $host:$port\n$!";
    }
    $sock->blocking(0);
    setsockopt( $sock, IPPROTO_TCP, TCP_NODELAY, pack( "l", 1 ) ) or die;
    $sock->autoflush(1);

    my $req = Gearman::Util::pack_req_command( 'echo_req', $MSG );
    Gearman::Util::send_req( $sock, \$req );
    $sock->flush;

    my $select = IO::Select->new;
    $select->add($sock);

    my ( $can_read, ) = $select->can_read($select_timeout);
    unless ($can_read) {
        $sock->close;
        return "gearmand connection timeout : $host";
    }

    my $err;
    my $res = Gearman::Util::read_res_packet( $sock, \$err );
    if ( $res && $res->{type} eq "error" ) {
        die "Error packet from server after get_status: ${$res->{blobref}}\n";
    }

    if ( $res && $res->{type} eq 'echo_res' && ${ $res->{blobref} } eq $MSG ) {
        $sock->close();
        return; # alive
    }
    else {
        $sock->close();
        return "gearmand response is invaild : $res->{type}";
    }
}

1;
__END__

=for stopwords gearmand

=head1 NAME

App::MadEye::Plugin::Agent::Gearmand - monitoring gearmand

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        port:
            required: no
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

L<gearmand>, L<App::MadEye>

