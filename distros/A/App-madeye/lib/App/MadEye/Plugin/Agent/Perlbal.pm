package App::MadEye::Plugin::Agent::Perlbal;
use strict;
use warnings;
use IO::Socket::INET;
use App::MadEye::Plugin::Agent::Base;

my $req = <<'...';
GET / HTTP/1.0
Host: invalidhostname.example.com

...

sub is_dead {
    my ($self, $host) = @_;

    my $conf    = $self->config->{config};
    my $port    = $conf->{port} || 80;
    my $timeout = $conf->{timeout} || 10;

    my $sock = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Timeout  => $timeout,
    ) or return "cannot open socket";
    $sock->write($req);

    my $content = join '', <$sock>;
    if ($content =~ m{Server: Perlbal.+<h1>404 - Not Found</h1>}s) {
        return; # alive.
    } else {
        return "this is not a perlbal?\n\n$content";
    }
}

1;
__END__

=for stopwords Perlbal

=head1 NAME

App::MadEye::Plugin::Agent::Perlbal - check Perlbal.

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
        timeout:
            required: yes
            type: int
        user_agent:
            required: no
            type: str

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<App::MadEye>, L<LWP::UserAgent>, L<Perlbal>

