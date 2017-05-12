package App::MadEye::Plugin::Agent::DNS;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;
use Net::DNS;

sub is_dead {
    my ($self, $target) = @_;

    my $host = $target->{host} or die "missing host";
    my $name = $target->{name} or die "missing name";
    my $ip   = $target->{ip}   or die "missing ip";
    my $timeout = $target->{timeout} || 10;

    my $dns = Net::DNS::Resolver->new(
        recurse     => 0,
        nameservers => ref($host) eq 'ARRAY' ? $host :  [$host],
    );
    $dns->tcp_timeout($timeout);
    $dns->udp_timeout($timeout);
    my $packet = $dns->search($name);
    if ($packet) {
        if ($packet->string =~ /$ip/) {
            return; # alive.
        } else {
            return "invalid IP : " . $packet->string;
        }
    } else {
        return 'DEAD';
    }
}

1;
