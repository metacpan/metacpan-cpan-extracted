package App::AquariumHive;
BEGIN {
  $App::AquariumHive::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Temporary Daemon - will later be replaced by HiveHub
$App::AquariumHive::VERSION = '0.003';
our $VERSION ||= '0.000';

use MooX qw(
  Options
);

use Path::Tiny;
use PocketIO;
use Plack::Builder;
use Twiggy::Server;
use AnyEvent;
use AnyEvent::SerialPort;
use AnyEvent::HTTP;
use File::ShareDir::ProjectDistDir;
use File::HomeDir;
use JSON::MaybeXS;
use DateTime;
use Config::INI::Reader;
use Config::INI::Writer;
use Carp qw( croak );
use DDP;
use Module::Runtime qw( use_module );
use Module::Pluggable
  sub_name => 'plugin_classes',
  search_path => ['App::AquariumHive::Plugin'],
  max_depth => 4,
  require => 1;

use HiveJSO;
use AnyEvent::HiveJSO;
use AquariumHive::Simulator;
use App::AquariumHive::DB;

use Log::Any::Adapter ('Stdout');

with 'App::AquariumHive::LogRole';

sub BUILD {
  my ( $self ) = @_;
  path($self->cfg)->mkpath unless -d $self->cfg;
}

option 'cfg' => (
  is => 'ro',
  format => 'i',
  default => sub {
    return path(File::HomeDir->my_home,'.aqhive')->absolute->stringify;
  },
  doc => 'directory for config',
);

option 'port' => (
  is => 'ro',
  format => 'i',
  default => '8888',
  doc => 'port for the webserver',
);

option 'simulation' => (
  is => 'ro',
  default => 0,
  doc => 'Simulate Aquarium Hive hardware',
);

option 'name' => (
  is => 'ro',
  format => 's',
  default => 'AQHIVE',
  doc => 'Name on top of interface',
);

option 'sensor_rows' => (
  is => 'ro',
  format => 's',
  default => 2,
  doc => 'Number of sensor rows in use',
);

option 'no_pwm' => (
  is => 'ro',
  default => 0,
  doc => 'No pwm controls',
);

option 'no_power' => (
  is => 'ro',
  default => 0,
  doc => 'No power controls',
);

option 'serial' => (
  is => 'ro',
  format => 's',
  default => '/dev/ttyAMA0',
  doc => 'serial port for the HiveJSO stream',
);

option 'baud' => (
  is => 'ro',
  format => 's',
  default => '19200',
  doc => 'baud rate for the serial port',
);

option 'agent' => (
  is => 'ro',
  format => 's',
  default => 'App::AquariumHive/'.$VERSION,
  doc => 'user agent for the web requests',
);

has config_ini => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_config_ini {
  my ( $self ) = @_;
  return path($self->cfg,'aqhive.ini')->stringify;
}

has config => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_config {
  my ( $self ) = @_;
  return {} unless -f $self->config_ini;
  return Config::INI::Reader->read_file($self->config_ini);
}

has db => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_db {
  my ( $self ) = @_;
  return App::AquariumHive::DB->connect($self);
}

sub save_config {
  my ( $self ) = @_;
  Config::INI::Writer->write_file($self->config, $self->config_ini);
}

has plugins => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_plugins {
  my ( $self ) = @_;
  $self->debug('Building plugins...');
  my @plugins;
  for my $class ($self->plugin_classes) {
    $self->debug('Loading '.$class);
    push @plugins, use_module($class)->new( app => $self );
  }
  for (@plugins) {
    if ($_->can('configure')) {
      $_->configure;
    }
  }
  return \@plugins;
}

has pocketio => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_pocketio {
  my ( $self ) = @_;
  return PocketIO->new( handler => sub {
    $self->debug('PocketIO connect');
    my $pio = shift;
    for my $key (keys %{$self->pocketio_handler}) {
      my @ons = @{$self->pocketio_handler->{$key}};
      $pio->on($key, sub {
        my ( $pio, $message ) = @_;
        $self->debug('PocketIO incoming '.$key);
        for my $sub (@ons) {
          $sub->($self, $message);
        }
      });
    }
  });
}

has pocketio_handler => (
  is => 'rw',
  init_arg => undef,
  default => sub {{}},
);

sub on_socketio {
  my ( $self, $key, $sub ) = @_;
  $self->pocketio_handler->{$key} = [] unless defined $self->pocketio_handler->{$key};
  push @{$self->pocketio_handler->{$key}}, $sub;
}

has data_handler => (
  is => 'rw',
  init_arg => undef,
  default => sub {[]},
);

sub on_data {
  my ( $self, $sub ) = @_;
  push @{$self->data_handler}, $sub;
}

has simulator => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_simulator {
  my ( $self ) = @_;
  return AquariumHive::Simulator->new(
    sensor_rows => $self->sensor_rows,
  );
}

has uart => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_uart {
  my ( $self ) = @_;
  my $uart;
  if ($self->simulation) {
    $uart = AnyEvent::Handle->new(
      fh => $self->simulator->fh,
    );
  } else {
    $uart = AnyEvent::SerialPort->new(
      serial_port => [
        $self->serial,
        [ baudrate => $self->baud ],
      ],
      read_size => 1,
    );
  }
  $uart->on_read(sub {
    $_[0]->push_read(hivejso => sub {
      my ( $uart, $data ) = @_;
      if (ref $data eq 'HiveJSO::Error') {
        p($data->error); p($data->garbage);
        return;
      }
      my $hivejso = $data->hivejso_short;
      $self->debug('HiveJSO IN '.$hivejso);
      if ($data->has_data) {
        $self->send( data => $data->data );
        for my $sub (@{$self->data_handler}) {
          $sub->($self, $data->data);
        }
      }
    });
  });
  return $uart;
}

sub http {
  my ( $self, $method, $url, @args ) = @_;
  my $cb = pop @args;
  my ( %arg ) = @args;
  $arg{headers} = {} unless defined $arg{headers};
  $arg{headers}->{'user-agent'} = $self->agent unless defined $arg{headers}->{'user-agent'};
  $arg{timeout} = 30 unless defined $arg{timeout};
  return http_request($method, $url, %arg, $cb);
}

sub send {
  my ( $self, $key, $data ) = @_;
  if ($self->pocketio->pool->{connections} && %{$self->pocketio->pool->{connections}}) {
    my @keys = keys %{$self->pocketio->pool->{connections}};
    return $self->pocketio->pool->{connections}->{$keys[0]}->sockets->emit($key,$data);
  }
  return;
}

has web_root => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_web_root {
  my ( $self ) = @_;
  return path(dist_dir('AquariumHive'),'root')->absolute->realpath->stringify;
}

has web_mounts => (
  is => 'rw',
  init_arg => undef,
  default => sub {{}},
);

sub web_mount {
  my ( $self, $mount, $psgi ) = @_;
  $self->web_mounts->{$mount} = $psgi;
}

has tiles => (
  is => 'rw',
  init_arg => undef,
  default => sub {{}},
);

sub tile {
  my ( $self, $key ) = @_;
  return $self->tiles->{$key};
}

sub add_tile {
  my ( $self, $key, $tile ) = @_;
  $self->tiles->{$key} = $tile;
}

has web => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_web {
  my ( $self ) = @_;
  my $server = Twiggy::Server->new(
    port => $self->port,
  );
  $server->register_service(builder {
    enable sub {
      my $app = shift;
      sub {
        $self->debug('Web Request '.$_[0]->{PATH_INFO});
        my $res = $app->($_[0]);
        return $res;
      };
    };
    mount '/shutdown' => sub { exit 0 };
    mount '/socket.io' => $self->pocketio;
    for my $mount (sort { length($a) <=> length($b) || $a cmp $b } keys %{$self->web_mounts}) {
      mount '/'.$mount, $self->web_mounts->{$mount};
    }
    mount '/tile' => sub {
      my ( $tile ) = $_[0]->{PATH_INFO} =~ m!/(.*)!;
      if ($self->tile($tile)) {
        return [ 200, [ "Content-Type" => "application/json" ], [encode_json({
          html => $self->tile($tile)->html,
          $self->tile($tile)->has_js ? ( js => $self->tile($tile)->js ) : (),
        })] ];
      } else {
        return [ 404, [ "Content-Type" => "application/json" ], [encode_json({
          not => 'found',
        })] ];
      }
    };
    mount '/name' => sub {
      return [ 200, [ "Content-Type" => "application/json" ], ['"'.$self->name.'"'] ];
    };
    mount '/tiles' => sub {
      return [ 200, [ "Content-Type" => "application/json" ], [encode_json([sort { $a cmp $b } keys %{$self->tiles}])] ];
    };
    mount '/' => builder {
      enable 'Rewrite',
        rules => sub { s{^/$}{/index.html}; };
      enable "Plack::Middleware::Static",
        path => qr{^/},
        root => $self->web_root;
    };
  });
  return $server;
}

sub command_aqhive {
  my ( $self, $command, @args ) = @_;
  return unless defined $command;
  my $hivejso;
  if ($self->simulation) {
    $hivejso = HiveJSO->new(
      unit => 'rasputin',
      command => scalar @args ? ([ $command, @args ]) : ($command),
    )->hivejso_short;
  } else {
    $hivejso = encode_json({
      o => scalar @args ? ([ $command, @args ]) : ($command),
    });
  }
  $self->debug('HiveJSO OUT '.$hivejso);
  $self->uart->push_write($hivejso);
}

sub run {
  my ( $self ) = @_;

  $self->plugins;
  $self->web;
  $self->uart;
  $self->db;

  $self->info("Starting App::AquariumHive (port ".$self->port.")...");

  my $t = AE::timer 0, 15, sub { $self->command_aqhive('data') };

  AE::cv->recv;
}

sub run_cmd {
  my ( $self, $command ) = @_;
  my @lines;
  if ($command) {
    require IPC::Open3;  # core
    # autoflush STDOUT so we can see command output right away
    local $| = 1;
    # combine stdout and stderr for ease of proxying through the logger
    my $pid = IPC::Open3::open3(my ($in, $out), undef, $command);
    while(defined(my $line = <$out>)){
      chomp($line);
      push @lines, $line;
    }
    # zombie repellent
    waitpid($pid, 0);
    my $status = ($? >> 8);
  }
  return @lines;
}

1;

__END__

=pod

=head1 NAME

App::AquariumHive - Temporary Daemon - will later be replaced by HiveHub

=head1 VERSION

version 0.003

=head1 DESCRIPTION

B<IN DEVELOPMENT, DO NOT USE YET>

See L<http://aquariumhive.com/> for now.

=head1 SUPPORT

IRC

  Join #AquariumHive on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  https://github.com/homehivelab/aquariumhive
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/homehivelab/aquariumhive/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
