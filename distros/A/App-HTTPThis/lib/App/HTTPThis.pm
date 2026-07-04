package App::HTTPThis;

# ABSTRACT: Export the current directory over HTTP

use strict;
use warnings;
use Plack::App::DirectoryIndex;
use Plack::Runner;
use Getopt::Long;
use Pod::Usage;
use Config::Tiny;
use IO::Socket::INET;

our $VERSION = '1.0.1';

=head1 NAME

App::HTTPThis - A simple local web server.

=head1 SYNOPSIS

    # Not to be used directly, see http_this command

=head1 DESCRIPTION

This class implements all the logic of the L<http_this> command.

Actually, this is just a very thin wrapper around
L<Plack::App::DirectoryIndex>, that is where the magic really is.

=head1 METHODS

=head2 new

Creates a new App::HTTPThis object, parsing the command line arguments
into object attribute values.

=cut

sub new {
  my $class = shift;
  my $self = bless {host => '127.0.0.1', port => 7007, root => '.'}, $class;

  my $default_config_file = '.http_thisrc';

  my $config_file = $self->{config} || $ENV{HTTP_THIS_CONFIG};
  {
    my %early;
    local @ARGV = @ARGV;
    Getopt::Long::Configure(qw(pass_through));
    GetOptions(\%early, "config=s") || pod2usage(2);
    Getopt::Long::Configure(qw(default));
    $config_file = $early{config} if defined $early{config};
  }

  # There are apparently OSes where $ENV{HOME} is undefined
  for my $dir ('.', $ENV{HOME}) {
    next unless defined $dir;
    if (!$config_file && -f "$dir/$default_config_file") {
      $config_file = "$dir/$default_config_file";
      last;
    }
  }

  if ($config_file) {
    my $config = Config::Tiny->read($config_file)
      or die "FATAL: failed to read config file '$config_file'\n";
    for my $key (qw(port host name autoindex pretty wsl)) {
      if (defined $config->{_}->{$key} && $config->{_}->{$key} ne '') {
        $self->{$key} = $config->{_}->{$key};
      }
    }
    if ($config->{_}->{all}) {
      $self->{host} = q{0.0.0.0};
    }
    delete $self->{config};
  }

  my %cli;
  GetOptions(
    \%cli, "help", "man", "config=s", "host=s", "port=i", "name=s", "autoindex!", "pretty!",
    "all|promiscuous", "wsl"
  ) || pod2usage(2);
  pod2usage(1) if $cli{help};
  pod2usage(-verbose => 2) if $cli{man};

  for my $key (keys %cli) {
    $self->{$key} = $cli{$key};
  }

  $self->{host} = q{0.0.0.0} if $self->{all};
  $self->{host} = $self->_wsl_host
    if $cli{wsl} || ($self->{wsl} && !exists $cli{host} && !exists $cli{all});

  if (@ARGV > 1) {
    pod2usage("$0: Too many roots, only single root supported");
  }
  elsif (@ARGV) {
    $self->{root} = shift @ARGV;
  }

  return $self;
}

=head2 run

Start the HTTP server.

=cut

sub run {
  my ($self) = @_;

  my $runner = Plack::Runner->new;
  $runner->parse_options(
    '--host'         => $self->{host},
    '--port'         => $self->{port},
    '--env'          => 'production',
    '--server_ready' => sub { $self->_server_ready(@_) },
    '--autoindex'    => 0,
    '--pretty'       => 0,
  );

  my $app_config = {
    root      => $self->{root},
    pretty    => $self->{pretty},
    dir_index => '',
  };
  $app_config->{dir_index} = 'index.html' if $self->{autoindex};

  eval {
    $runner->run(Plack::App::DirectoryIndex->new( $app_config )->to_app);
  };
  if (my $e = $@) {
    die "FATAL: port $self->{port} is already in use, try another one\n"
      if $e =~ /failed to listen to port/;
    die "FATAL: internal error - $e\n";
  }
}

sub _wsl_host {
  my ($self) = @_;

  for my $addr ($self->_wsl_addresses) {
    return $addr
      if $addr =~ /\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/
      && $addr ne '127.0.0.1';
  }

  die "FATAL: cannot find a non-loopback IPv4 address for WSL\n";
}

sub _wsl_addresses {
  my ($self) = @_;

  my @addresses;
  my %seen;
  my %seen_addr;

  for my $peer ($self->_wsl_default_gateway, '1.1.1.1') {
    next unless defined $peer && length $peer;
    next if $seen{$peer}++;

    my $sock = IO::Socket::INET->new(
      PeerAddr => $peer,
      PeerPort => 9,
      Proto    => 'udp',
    );
    next unless $sock;

    my $addr = $sock->sockhost;
    push @addresses, $addr
      if defined $addr && length $addr && !$seen_addr{$addr}++;
  }

  die "FATAL: cannot determine WSL IP address from the network route\n"
    unless @addresses;

  return @addresses;
}

sub _wsl_default_gateway {
  open my $fh, '<', '/proc/net/route' or return;

  while (my $line = <$fh>) {
    next if $line =~ /\AIface\b/;

    my @fields = split ' ', $line;
    next unless @fields >= 3;
    next unless $fields[1] eq '00000000';
    next unless $fields[2] =~ /\A[0-9A-Fa-f]{8}\z/;

    return join '.', reverse map { hex } $fields[2] =~ /(..)/g;
  }

  return;
}

sub _server_ready {
  my ($self, $args) = @_;

  my $host  = $args->{host};
  my $proto = $args->{proto} || 'http';
  my $port  = $args->{port};

  # An unspecified, zero, or wildcard host means the server is listening on
  # every network interface, not just this machine.
  my $all_interfaces =
       !defined $host
    || $host eq ''
    || $host eq '0'
    || $host eq '0.0.0.0'
    || $host eq '::';

  my $ipv6     = defined $host && $host eq '::';
  my $loopback = $ipv6 ? '::1' : '127.0.0.1';
  my $display  = $all_interfaces ? $loopback : $host;
  my $url_host = $display =~ /:/ ? "[$display]" : $display;

  print "Exporting '$self->{root}', available at:\n";
  print "   $proto://$url_host:$port/\n";

  if ($all_interfaces) {
    print "\n";
    print "WARNING: this server is reachable on all network interfaces, so\n";
    print "other machines on your network can access it. To limit access to\n";
    print "this computer only, restart with: --host $loopback\n";
  }

  return unless my $name = $self->{name};

  eval {
    require Net::Rendezvous::Publish;
    Net::Rendezvous::Publish->new->publish(
      name   => $name,
      type   => '_http._tcp',
      port   => $port,
      domain => 'local',
    );
  };
  if ($@) {
    print "\nWARNING: your server will not be published over Bonjour\n";
    print "    Install one of the Net::Rendezvous::Publish::Backend\n";
    print "    modules from CPAN\n"
  }
}

1;



=head1 SEE ALSO

L<http_this>, L<Plack>, L<Plack::App::DirectoryIndex>, and L<Net::Rendezvous::Publish>.


=head1 THANKS

And the Oscar goes to: Tatsuhiko Miyagawa.

For L<Plack>, L<Plack::App::Directory> and many many others.
