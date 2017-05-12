package Test::RedisRunner;

use strict;
use warnings;

our $VERSION = '0.1404';

use File::Temp;
use POSIX qw( SIGTERM WNOHANG );
use Time::HiRes qw( sleep );
use Carp;
use Errno ();

sub new {
  my $class  = shift;
  my %params = @_;

  my $self = bless {}, $class;

  $self->{pid}     = $params{pid};
  $self->{conf}    = $params{conf};
  $self->{timeout} = $params{timeout} || 3;

  $self->{auto_start} = 1;
  if ( exists $params{auto_start} ) {
    $self->{auto_start} = $params{auto_start};
  }

  unless ( defined $params{tmpdir} ) {
    $params{tmpdir} = File::Temp->newdir( CLEANUP => 1 );
  }
  $self->{tmpdir} = $params{tmpdir};

  $self->{_owner_pid} = $$;

  my $tmpdir = $self->{tmpdir};
  my $conf   = $self->{conf};
  unless ( defined $conf->{port} || defined $conf->{unixsocket} ) {
    $conf->{unixsocket} = $tmpdir . '/redis.sock';
    $conf->{port}       = '0';
  }
  unless ( defined $conf->{dir} ) {
    $conf->{dir} = "$tmpdir/";
  }
  if ( $conf->{loglevel} && $conf->{loglevel} eq 'warning' ) {
    warn "Test::RedisRunner does not support \"loglevel warning\","
        . " using \"notice\" instead.\n";
    $conf->{loglevel} = 'notice';
  }

  if ( $self->{auto_start} ) {
    $self->start();
  }

  return $self;
}

sub start {
  my $self = shift;

  return if defined $self->{pid};

  my $tmpdir = $self->{tmpdir};
  open( my $logfh, '>>', "$tmpdir/redis-server.log" )
      or croak "failed to create log file: $tmpdir/redis-server.log";

  my $pid = fork();

  croak "fork(2) failed: $!" unless defined $pid;

  if ( $pid == 0 ) {
    open( STDOUT, '>&', $logfh ) or croak "dup(2) failed: $!";
    open( STDERR, '>&', $logfh ) or croak "dup(2) failed: $!";

    $self->exec();
  }
  close $logfh;

  my $ready;
  my $elapsed = 0;
  $self->{pid} = $pid;

  while ( $elapsed <= $self->{timeout} ) {
    if ( waitpid( $pid, WNOHANG ) > 0 ) {
      undef $self->{pid};
      last;
    }
    else {
      my $log = q[];
      if ( open( $logfh, '<', "$tmpdir/redis-server.log" ) ) {
        $log = do { local $/; <$logfh> };
        close $logfh;
      }

      # confirmed this message is included from v1.3.6 (older version in
      # git repo) to current HEAD (2012-07-30)
      if ( $log =~ /The server is now ready to accept connections/ ) {
        $ready = 1;
        last;
      }
    }

    sleep $elapsed += 0.1;
  }

  unless ( $ready ) {
    if ( $self->{pid} ) {
      undef $self->{pid};
      kill( SIGTERM, $pid );
      while ( waitpid( $pid, WNOHANG ) >= 0 ) {
      }
    }

    croak "*** failed to launch redis-server ***\n" . do {
      my $log = q[];
      if ( open( $logfh, '<', "$tmpdir/redis-server.log" ) ) {
        $log = do { local $/; <$logfh> };
        close $logfh;
      }
      $log;
    };
  }

  $self->{pid} = $pid;

  return;
}

sub exec {
  my $self = shift;

  my $tmpdir = $self->{tmpdir};

  open( my $conffh, '>', "$tmpdir/redis.conf" ) or croak "cannot write conf: $!";
  print $conffh $self->_conf_string;
  close $conffh;

  exec 'redis-server', "$tmpdir/redis.conf" or do {
    if ( $! == Errno::ENOENT ) {
      print STDERR "exec failed: no such file or directory\n";
    }
    else {
      print STDERR "exec failed: unexpected error: $!\n";
    }
    exit( $? );
  };

  return;
}

sub stop {
  my $self = shift;
  my $sig  = shift;

  local $?; # waitpid may change this value :/
  return unless defined $self->{pid};

  $sig ||= SIGTERM;

  kill( $sig, $self->{pid} );
  while ( waitpid( $self->{pid}, WNOHANG ) >= 0 ) {
  }

  undef $self->{pid};

  return;
}

sub wait_exit {
  my $self = shift;

  local $?;

  my $kid;
  my $pid = $self->{pid};
  do {
    $kid = waitpid( $pid, WNOHANG );
    sleep 0.1;
  } while $kid >= 0;

  undef $self->{pid};

  return;
}

sub connect_info {
  my $self = shift;

  my $conf = $self->{conf};
  my $host = $conf->{bind} || '0.0.0.0';
  my $port = $conf->{port};

  if ( !$port || $port == 0 ) {
    $host = 'unix/';
    $port = $conf->{unixsocket};
  }

  return (
    host => $host,
    port => $port,
  );
}

sub _conf_string {
  my $self = shift;

  my $conf = q[];
  my %conf = %{ $self->{conf} };
  while ( my ( $k, $v ) = each %conf ) {
    next unless defined $v;
    $conf .= "$k $v\n";
  }

  return $conf;
}

sub DESTROY {
  my $self = shift;

  if ( defined $self->{pid} && $$ == $self->{_owner_pid} ) {
    $self->stop();
  }

  return;
}
__END__

=head1 NAME

Test::RedisRunner - redis-server runner for tests.

=head1 SYNOPSIS

    use Redis;
    use Test::RedisRunner;
    use Test::More;

    my $redis_server;
    eval {
        $redis_server = Test::RedisRunner->new;
    } or plan skip_all => 'redis-server is required to this test';

    my $redis = Redis->new( $redis_server->connect_info );

    is $redis->ping, 'PONG', 'ping pong ok';

    done_testing;

=head1 DESCRIPTION

=head1 METHODS

=head2 new(%options)

    my $redis_server = Test::RedisRunner->new(%options);

Create a new redis-server instance, and start it by default (auto_start option avoid this)

Available options are:

=over

=item * auto_start => 0 | 1 (Default: 1)

Automatically start redis-server instance (by default).
You can disable this feature by C<< auto_start => 0 >>, and start instance
manually by C<start> or C<exec> method below.

=item * conf => 'HashRef'

This is redis.conf key value pair. Any key-value pair supported that redis-server supports.

If you want to use this redis.conf:

    port 9999
    databases 16
    save 900 1

Your conf parameter will be:

    Test::RedisRunner->new( conf => {
        port      => 9999,
        databases => 16,
        save      => '900 1',
    });

=item * timeout => 'Int'

Timeout seconds detecting redis-server is awake or not. (Default: 3)

=item * tmpdir => 'String'

Temporal directory, where redis config will be stored. By default it is created
for you, but you start Test::RedisRunner via exec (e.g. with Test::TCP), you
  should provide it to be automatically deleted:

=back

=head2 start

Start redis-server instance manually.

=head2 exec

Just exec to redis-server instance. This method is useful to use this module
with L<Test::TCP>, L<Proclet> or etc.

    use File::Temp;
    use Test::TCP;
    my $tmp_dir = File::Temp->newdir( CLEANUP => 1 );

    test_tcp(
        client => sub {
            my ($port, $server_pid) = @_;
            ...
        },
        server => sub {
            my ($port) = @_;
            my $redis = Test::RedisRunner->new(
                auto_start => 0,
                conf       => { port => $port },
                tmpdir     => $tmp_dir,
            );
            $redis->exec;
        },
    );

=head2 stop

Stop redis-server instance.

This method automatically called when object was DESTROY.

=head2 connect_info

Return connection info for client library to connect this redis-server instance.

This parameter is designed to pass directly to L<Redis> module.

    my $redis_server = Test::RedisRunner->new;
    my $redis = Redis->new( $redis_server->connect_info );

=head2 pid

Return redis-server instance's process id, or undef when redis-server is not running.

=head2 wait_exit

Block until redis instance exited.

=head1 SEE ALSO

L<Test::mysqld> for mysqld.

L<Test::Memcached> for Memcached.

This module steals lots of stuffs from above modules.

L<Test::Mock::Redis>, another approach for testing redis application.

=head1 INTERNAL METHODS

=head2 BUILD

=head2 DEMOLISH

=head1 AUTHOR

Daisuke Murase, E<lt>typester@cpan.orgE<gt>

Refactored by Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 KAYAC Inc. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
