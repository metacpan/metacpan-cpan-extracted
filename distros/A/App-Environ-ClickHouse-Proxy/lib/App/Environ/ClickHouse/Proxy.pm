package App::Environ::ClickHouse::Proxy;

our $VERSION = '0.3';

use strict;
use warnings;
use v5.10;
use utf8;

use App::Environ;
use App::Environ::Config;
use Cpanel::JSON::XS;
use IO::Socket;

my $INSTANCE;

my $JSON = Cpanel::JSON::XS->new->utf8;

App::Environ::Config->register(qw(clickhouse_proxy.yml));

sub instance {
  my $class = shift;

  unless ($INSTANCE) {
    my $config = App::Environ::Config->instance;

    my $sock = IO::Socket::INET->new(
      Proto    => 'udp',
      PeerAddr => $config->{clickhouse_proxy}{host},
      PeerPort => $config->{clickhouse_proxy}{port},
    ) or die "Could not create socket: $!\n";

    $INSTANCE = bless { sock => $sock }, $class;
  }

  return $INSTANCE;
}

sub send {
  my __PACKAGE__ $self = shift;
  my $query = shift;

  no warnings 'numeric';

  my @types;
  foreach (@_) {
    if ( defined($_)
      && length( ( my $dummy = '' ) & $_ )
      && 0 + $_ eq $_
      && $_ * 0 == 0 )
    {
      if (/^[+-]?\d+\z/) {
        push @types, 'int';
      }
      else {
        push @types, 'float';
      }
    }
    else {
      push @types, 'string';
    }
  }

  use warnings 'numeric';

  my %val = (
    query   => $query,
    data    => \@_,
    types   => \@types,
    version => 1,
  );

  $self->{sock}->send( $JSON->encode( \%val ) ) or warn "Send error: $!\n";

  return;
}

1;

__END__

=head1 NAME

App::Environ::ClickHouse::Proxy - communicate with ClickHouse UDP proxy

=head1 SYNOPSIS

  use App::Environ;
  use App::Environ::ClickHouse::Proxy;

  App::Environ->send_event('initialize');

  my $ch_proxy = App::Environ::ClickHouse::Proxy->instance;

  $ch_proxy->send( 'INSERT INTO test (dt_part,dt,id) VALUES (?,?,?);',
    '2017-09-09', '2017-09-09 12:26:03', 1 );

  App::Environ->send_event('finalize:r');

=head1 DESCRIPTION

App::Environ::ClickHouse::Proxy used to get object to communicate with ClickHouse UDP proxy in App::Environ environment.

=head1 AUTHOR

Andrey Kuzmin, E<lt>kak-tus@mail.ruE<gt>

=head1 SEE ALSO

L<https://github.com/kak-tus/App-Environ-ClickHouse-Proxy>.

L<https://hub.docker.com/r/kaktuss/clickhouse-udp-proxy/>.

L<https://github.com/kak-tus/clickhouse-udp-proxy>.

=cut
