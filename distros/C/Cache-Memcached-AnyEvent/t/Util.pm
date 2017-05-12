# use Devel::NYTProf;
package
    t::Util;
use strict;
use Cache::Memcached::AnyEvent;
use IO::Socket::INET;
use Test::More;
use base qw(Exporter);

our @EXPORT = qw(
    test_client
    test_servers
    random_key
);

sub import {
    my $class = shift;
    Test::More->export_to_level(1, @_);
    $class->Exporter::export_to_level(1, @_);
}

sub random_key {
    return join ".", "cm-ae-test", {}, rand(), $$;
}

sub test_servers {
    my $servers = $ENV{PERL_ANYEVENT_MEMCACHED_SERVERS};
    $servers ||= 'localhost:11211';
    return split(/\s*,\s*/, $servers);
}

sub test_client {
    my %args = @_;
    my @servers;
    foreach my $server ( test_servers() ) {
        my ($host, $port) = split(/:/, $server);
        my $socket = IO::Socket::INET->new(
            PeerHost => $host,
            PeerPort => $port,
        );
        if ($socket) {
            push @servers, $server;
        } else {
            warn "failed: $@";
        }
    }

    if (! @servers) {
        plan skip_all => "Can't talk to any memcached servers";
    }

    return Cache::Memcached::AnyEvent->new(
        namespace => join('.', time(), $$, ''),
        %args,
        servers => \@servers,
    );
}
    

1;

1;