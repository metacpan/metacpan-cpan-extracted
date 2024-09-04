package ArcusTestCommon;

use strict;
use warnings;
use Exporter 'import';

use IO::Socket::PortState qw(check_ports);
use Arcus::Client;

use FindBin;
use lib "$FindBin::Bin";

my $host = '127.0.0.1';
my $port = 2181;

sub is_zk_port_opened {
  my %porthash = (
    tcp => {
      2181  => { name => 'ZK' },
    }
  );

  my $timeout = 5;
  check_ports($host, $timeout, \%porthash);

  for my $proto (keys %porthash) {
    for my $port (keys %{ $porthash{$proto} }) {
      if ($porthash{$proto}{$port}{open}) {
        return 1;
      } else {
        warn "$proto port $port ($porthash{$proto}{$port}{name}) is closed.\n";
        return 0;
      }
    }
  }

  return 0;
}

sub create_client {
  my ($namespace) = @_;
  $namespace = "" unless defined($namespace);

  my $cache = undef;
  eval {
    $cache = Arcus::Client->new({
      zk_address => [ "$host:$port" ],
      service_code => "test",
      namespace => $namespace,
    });
  };

  return $cache;
}

1;
