package App::MadEye::Plugin::Agent::Memcached;
use strict;
use warnings;
use Cache::Memcached::Fast;
use App::MadEye::Plugin::Agent::Base;

sub is_dead {
    my ($self, $host) = @_;

    my $conf    = $self->config->{config};
    my $port    = $conf->{port} || 11211;
    my $timeout = $conf->{timeout} || 1;
    my $namespace = $conf->{namespace} || 'madeye';

    my $sock = Cache::Memcached::Fast->new({
        servers => ["$host:$port"],
        namespace => $namespace,
        connect_timeout => $timeout,
    });

    $sock->set($host, 1) or
        return "Can't set data";
    return "Can't get data" unless $sock->get($host);

    return; # success!!
}

1;
__END__

=for stopwords Memcached

=head1 NAME

App::MadEye::Plugin::Agent::Memcached - check Memcached.

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
            required: no
            type: int
        namespace:
            required: no
            type: str

=head1 AUTHOR

Keiji Yoshimi

=head1 SEE ALSO

L<App::MadEye>, L<Cache::Memcached::Fast>

