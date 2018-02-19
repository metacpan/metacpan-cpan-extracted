package API::MikroTik;
use Mojo::Base '-base';

use API::MikroTik::Response;
use API::MikroTik::Sentence qw(encode_sentence);
use Carp ();
use Mojo::Collection;
use Mojo::IOLoop;
use Mojo::Util 'md5_sum';
use Scalar::Util 'weaken';

use constant CONN_TIMEOUT => $ENV{API_MIKROTIK_CONNTIMEOUT};
use constant DEBUG        => $ENV{API_MIKROTIK_DEBUG} || 0;
use constant PROMISES     => !!(eval { require Mojo::Promise; 1 });

our $VERSION = '0.24';

has error    => '';
has host     => '192.168.88.1';
has ioloop   => sub { Mojo::IOLoop->new() };
has password => '';
has port     => 0;
has timeout  => 10;
has tls      => 1;
has user     => 'admin';
has _tag     => 0;

# Aliases
Mojo::Util::monkey_patch(__PACKAGE__, 'cmd',   \&command);
Mojo::Util::monkey_patch(__PACKAGE__, 'cmd_p', \&command_p);
Mojo::Util::monkey_patch(__PACKAGE__, '_fail', \&_finish);

sub DESTROY { Mojo::Util::_global_destruction() or shift->_cleanup() }

sub cancel {
    my $cb = ref $_[-1] eq 'CODE' ? pop : sub { };
    return shift->_command(Mojo::IOLoop->singleton, '/cancel', {'tag' => shift},
        undef, $cb);
}

sub command {
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my ($self, $cmd, $attr, $query) = @_;

    # non-blocking
    return $self->_command(Mojo::IOLoop->singleton, $cmd, $attr, $query, $cb)
        if $cb;

    # blocking
    my $res;
    $self->_command($self->ioloop, $cmd, $attr, $query,
        sub { $_[0]->ioloop->stop(); $res = $_[2]; });
    $self->ioloop->start();

    return $res;
}

sub command_p {
    Carp::croak 'Mojolicious v7.54+ is required for using promises.'
        unless PROMISES;
    my ($self, $cmd, $attr, $query) = @_;

    my $p = Mojo::Promise->new();
    $self->_command(
        Mojo::IOLoop->singleton,
        $cmd, $attr, $query,
        sub {
            return $p->reject($_[1], $_[2]) if $_[1];
            $p->resolve($_[2]);
        }
    );

    return $p;
}

sub subscribe {
    do { $_[0]->{error} = 'can\'t subscribe in blocking mode'; return; }
        unless ref $_[-1] eq 'CODE';
    my $cb = pop;
    my ($self, $cmd, $attr, $query) = @_;
    $attr->{'.subscription'} = 1;
    return $self->_command(Mojo::IOLoop->singleton, $cmd, $attr, $query, $cb);
}

sub _cleanup {
    my $self = shift;
    $_->{timeout} && $_->{loop}->remove($_->{timeout})
        for values %{$self->{requests}};
    $_ && $_->unsubscribe('close')->close() for values %{$self->{handles}};
    delete $self->{handles};
}

sub _close {
    my ($self, $loop) = @_;
    $self->_fail_all($loop, 'closed prematurely');
    delete $self->{handles}{$loop};
    delete $self->{responses}{$loop};
}

sub _command {
    my ($self, $loop, $cmd, $attr, $query, $cb) = @_;

    my $tag = ++$self->{_tag};
    my $r = $self->{requests}{$tag} = {tag => $tag, loop => $loop, cb => $cb};
    $r->{subscription} = delete $attr->{'.subscription'};

    warn "-- got request for command '$cmd' (tag: $tag)\n" if DEBUG;

    $r->{sentence} = encode_sentence($cmd, $attr, $query, $tag);
    return $self->_send_request($r);
}

sub _connect {
    my ($self, $r) = @_;

    warn "-- creating new connection\n" if DEBUG;

    my $queue = $self->{queues}{$r->{loop}} = [$r];

    my $tls = $self->tls;
    my $port = $self->port ? $self->{port} : $tls ? 8729 : 8728;

    $r->{loop}->client(
        {
            address     => $self->host,
            port        => $port,
            timeout     => CONN_TIMEOUT,
            tls         => $tls,
            tls_ciphers => 'HIGH'
        } => sub {
            my ($loop, $err, $stream) = @_;

            delete $self->{queues}{$loop};

            if ($err) { $self->_fail($_, $err) for @$queue; return }

            warn "-- connection established\n" if DEBUG;

            $self->{handles}{$loop} = $stream;

            weaken $self;
            $stream->on(read => sub { $self->_read($loop, $_[1]) });
            $stream->on(
                error => sub { $self and $self->_fail_all($loop, $_[1]) });
            $stream->on(close => sub { $self && $self->_close($loop) });

            $self->_login(
                $loop,
                sub {
                    if ($_[1]) {
                        $_[0]->_fail($_, $_[1]) for @$queue;
                        $stream->close();
                        return;
                    }
                    $self->_write_sentence($stream, $_) for @$queue;
                }
            );
        }
    );

    return $r->{tag};
}

sub _enqueue {
    my ($self, $r) = @_;
    return $self->_connect($r) unless my $queue = $self->{queues}{$r->{loop}};
    push @$queue, $r;
    return $r->{tag};
}

sub _fail_all {
    $_[0]->_fail($_, $_[2])
        for grep { $_->{loop} eq $_[1] } values %{$_[0]->{requests}};
}

sub _finish {
    my ($self, $r, $err) = @_;
    delete $self->{requests}{$r->{tag}};
    if (my $timer = $r->{timeout}) { $r->{loop}->remove($timer) }
    $r->{cb}->($self, ($self->{error} = $err // ''), $r->{data});
}

sub _login {
    my ($self, $loop, $cb) = @_;
    warn "-- trying to log in\n" if DEBUG;

    $loop->delay(
        sub {
            $self->_command($loop, '/login', {}, undef, $_[0]->begin());
        },
        sub {
            my ($delay, $err, $res) = @_;
            return $self->$cb($err) if $err;
            my $secret
                = md5_sum("\x00", $self->password, pack 'H*', $res->[0]{ret});
            $self->_command($loop, '/login',
                {name => $self->user, response => "00$secret"},
                undef, $delay->begin());
        },
        sub {
            $self->$cb($_[1]);
        },
    );
}

sub _read {
    my ($self, $loop, $bytes) = @_;

    warn "-- read bytes from socket: " . (length $bytes) . "\n" if DEBUG;

    my $response = $self->{responses}{$loop} ||= API::MikroTik::Response->new();
    my $data = $response->parse(\$bytes);

    for (@$data) {
        next unless my $r = $self->{requests}{delete $_->{'.tag'}};
        my $type = delete $_->{'.type'};
        push @{$r->{data} ||= Mojo::Collection->new()}, $_
            if %$_ && !$r->{subscription};

        if ($type eq '!re' && $r->{subscription}) {
            $r->{cb}->($self, '', $_);

        }
        elsif ($type eq '!done') {
            $r->{data} ||= Mojo::Collection->new();
            $self->_finish($r);

        }
        elsif ($type eq '!trap' || $type eq '!fatal') {
            $self->_fail($r, $_->{message});
        }
    }
}

sub _send_request {
    my ($self, $r) = @_;
    return $self->_enqueue($r) unless my $stream = $self->{handles}{$r->{loop}};
    return $self->_write_sentence($stream, $r);
}

sub _write_sentence {
    my ($self, $stream, $r) = @_;
    warn "-- writing sentence for tag: $r->{tag}\n" if DEBUG;

    $stream->write($r->{sentence});

    return $r->{tag} if $r->{subscription};

    weaken $self;
    $r->{timeout} = $r->{loop}
        ->timer($self->timeout => sub { $self->_fail($r, 'response timeout') });

    return $r->{tag};
}

1;


=encoding utf8

=head1 NAME

API::MikroTik - Non-blocking interface to MikroTik API

=head1 SYNOPSIS

  my $api = API::MikroTik->new();

  # Blocking
  my $list = $api->command(
      '/interface/print',
      {'.proplist' => '.id,name,type'},
      {type        => ['ipip-tunnel', 'gre-tunnel'], running => 'true'}
  );
  if (my $err = $api->error) { die "$err\n" }
  printf "%s: %s\n", $_->{name}, $_->{type} for @$list;


  # Non-blocking
  my $tag = $api->command(
      '/system/resource/print',
      {'.proplist' => 'board-name,version,uptime'} => sub {
          my ($api, $err, $list) = @_;
          ...;
      }
  );
  Mojo::IOLoop->start();

  # Subscribe
  $tag = $api->subscribe(
      '/interface/listen' => sub {
          my ($api, $err, $el) = @_;
          ...;
      }
  );
  Mojo::IOLoop->timer(3 => sub { $api->cancel($tag) });
  Mojo::IOLoop->start();

  # Errors handling
  $api->command(
      '/random/command' => sub {
          my ($api, $err, $list) = @_;

          if ($err) {
              warn "Error: $err, category: " . $list->[0]{category};
              return;
          }

          ...;
      }
  );
  Mojo::IOLoop->start();

  # Promises
  $api->cmd_p('/interface/print')
      ->then(sub { my $res = shift }, sub { my ($err, $attr) = @_ })
      ->finally(sub { Mojo::IOLoop->stop() });
  Mojo::IOLoop->start();

=head1 DESCRIPTION

Both blocking and non-blocking interface to a MikroTik API service. With queries,
command subscriptions and Promises/A+ (courtesy of an I/O loop). Based on
L<Mojo::IOLoop> and would work alongside L<EV>.

=head1 ATTRIBUTES

L<API::MikroTik> implements the following attributes.

=head2 error

  my $last_error = $api->error;

Keeps an error from last L</command> call. Empty string on successful commands.

=head2 host

  my $host = $api->host;
  $api     = $api->host('border-gw.local');

Host name or IP address to connect to. Defaults to C<192.168.88.1>.

=head2 ioloop

  my $loop = $api->ioloop;
  $api     = $api->loop(Mojo::IOLoop->new());

Event loop object to use for blocking operations, defaults to L<Mojo::IOLoop>
object.

=head2 password

  my $pass = $api->password;
  $api     = $api->password('secret');

Password for authentication. Empty string by default.

=head2 port

  my $port = $api->port;
  $api     = $api->port(8000);

API service port for connection. Defaults to C<8729> and C<8728> for TLS and
clear text connections respectively.

=head2 timeout

  my $timeout = $api->timeout;
  $api        = $api->timeout(15);

Timeout in seconds for sending request and receiving response before command
will be canceled. Default is C<10> seconds.

=head2 tls

  my $tls = $api->tls;
  $api    = $api->tls(1);

Use TLS for connection. Enabled by default.

=head2 user

  my $user = $api->user;
  $api     = $api->user('admin');

User name for authentication purposes. Defaults to C<admin>.

=head1 METHODS

=head2 cancel

  # subscribe to a command output
  my $tag = $api->subscribe('/ping', {address => '127.0.0.1'} => sub {...});

  # cancel command after 10 seconds
  Mojo::IOLoop->timer(10 => sub { $api->cancel($tag) });

  # or with callback
  $api->cancel($tag => sub {...});

Cancels background commands. Can accept a callback as last argument.

=head2 cmd

  my $list = $api->cmd('/interface/print');

An alias for L</command>.

=head2 cmd_p

  my $promise = $api->cmd_p('/interface/print');

An alias for L</command_p>.

=head2 command

  my $command = '/interface/print';
  my $attr    = {'.proplist' => '.id,name,type'};
  my $query   = {type => ['ipip-tunnel', 'gre-tunnel'], running => 'true'};

  my $list = $api->command($command, $attr, $query);
  die $api->error if $api->error;
  for (@$list) {...}

  $api->command('/user/set', {'.id' => 'admin', comment => 'System admin'});

  # Non-blocking
  $api->command('/ip/address/print' => sub {
      my ($api, $err, $list) = @_;

      return if $err;

      for (@$list) {...}
  });

  # Omit attributes
  $api->command('/user/print', undef, {name => 'admin'} => sub {...});

  # Errors handling
  $list = $api->command('/random/command');
  if (my $err = $api->error) {
      die "Error: $err, category: " . $list->[0]{category};
  }

Executes a command on a remote host and returns L<Mojo::Collection> with hashrefs
containing elements returned by a host. You can append a callback for non-blocking
calls.

In a case of error it may return extra attributes to C<!trap> or C<!fatal> API
replies in addition to error messages in an L</error> attribute or an C<$err>
argument. You should never rely on defines of the result to catch errors.

For a query syntax refer to L<API::MikroTik::Query>.

=head2 command_p

  my $promise = $api->command_p('/interface/print');

  $promise->then(
  sub {
      my $res = shift;
      ...
  })->catch(sub {
      my ($err, $attr) = @_;
  });

Same as L</command>, but always performs requests non-blocking and returns a
L<Mojo::Promise> object instead of accepting a callback. L<Mojolicious> v7.54+ is
required for promises functionality.

=head2 subscribe

  my $tag = $api->subscribe('/ping',
      {address => '127.0.0.1'} => sub {
        my ($api, $err, $res) = @_;
      });

  Mojo::IOLoop->timer(
      3 => sub { $api->cancel($tag) }
  );

Subscribe to an output of commands with continuous responses such as C<listen> or
C<ping>. Should be terminated with L</cancel>.

=head1 DEBUGGING

You can set the API_MIKROTIK_DEBUG environment variable to get some debug output
printed to stderr.

Also, you can change connection timeout with the API_MIKROTIK_CONNTIMEOUT variable.

=head1 COPYRIGHT AND LICENSE

Andre Parker, 2017-2018.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<https://wiki.mikrotik.com/wiki/Manual:API>, L<https://github.com/anparker/api-mikrotik>

=cut

