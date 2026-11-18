#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Config;
use Path::Tiny;
use API::Docker;

# karr k26. This file used to pin the opposite of what it now pins: tls and
# cert_path were attributes nothing read, so a tcp:// daemon was addressed in
# cleartext whatever tls said, and tls => 1 croaked at construction rather
# than pretending otherwise. TLS is wired now -- IO::Socket::SSL in the
# tcp:// branch of the socket builder, certificates from the directory
# cert_path always pointed at -- so every one of those claims is replaced by
# its inverse here.
#
# The handshake subtests at the bottom fork a TLS server on 127.0.0.1 and
# generate their own certificates; nothing here reaches a Docker daemon or
# the network, and no certificate is read from anywhere but a temporary
# directory this file created.

my $HAVE_SSL = eval { require IO::Socket::SSL; 1 };

sub client {
  return API::Docker->new(
    host        => 'tcp://dockerhost:2376',
    api_version => '1.41',
    @_,
  );
}

# ===========================================================================
# Construction
# ===========================================================================

subtest 'tls => 1 constructs, and cert_path is what it acts on' => sub {
  # The claim this replaces: "tls => 1 croaks at construction ... TLS is
  # still not implemented", and "cert_path does not rescue tls => 1".
  my $docker = eval { client(tls => 1) };
  is $@, '', 'no croak';
  ok $docker, 'a client comes back';
  is $docker->tls, 1, 'and it knows it is a TLS client';

  my $dir = Path::Tiny->tempdir;
  $dir->child('ca.pem')->spew('');
  my $with_certs = eval { client(tls => 1, cert_path => "$dir") };
  is $@, '', 'tls => 1 with a cert_path constructs too';
  is $with_certs->cert_path, "$dir", 'and keeps the path, to act on it';
};

subtest 'every falsy form of tls is still accepted' => sub {
  for my $off (0, undef, '') {
    my $docker = eval { client(tls => $off) };
    is $@, '', 'tls => ' . (defined $off ? "'$off'" : 'undef') . ' constructs';
    ok $docker, 'and returns a client';
  }

  # Pinned against the developer's own shell: the default now reads
  # DOCKER_TLS_VERIFY (karr k42), and the claim being made here is the one
  # that has always been made -- with nothing set, a tcp:// host is plaintext.
  delete local $ENV{DOCKER_TLS_VERIFY};
  is client()->tls, 0, 'the default is still 0: a tcp:// host is plaintext '
    . 'unless TLS is asked for';
};

# ===========================================================================
# DOCKER_TLS_VERIFY (karr k42)
# ===========================================================================

subtest 'the default is DOCKER_TLS_VERIFY, on the docker CLI rule' => sub {
  # Measured against docker/cli rather than guessed. cli/flags/options.go:
  #
  #     dockerTLSVerify = os.Getenv(client.EnvTLSVerify) != ""
  #
  # so the test is "non-empty", not "true", and non-empty means TLS on *and*
  # verification on (InsecureSkipVerify = !o.TLSVerify). The one place Perl
  # truthiness and that rule disagree is the string '0' -- which is exactly
  # what a user types for "off".
  {
    local $ENV{DOCKER_TLS_VERIFY} = '1';
    is client()->tls, 1, "'1' turns TLS on";
  }
  {
    local $ENV{DOCKER_TLS_VERIFY} = '0';
    is client()->tls, 1, "'0' turns TLS ON as well: the CLI reads != \"\", not "
      . 'truthiness, and this is the case a naive port gets backwards';
  }
  for my $value (qw( false no off true yes 2 )) {
    local $ENV{DOCKER_TLS_VERIFY} = $value;
    is client()->tls, 1, "'$value' is non-empty, so it is on too";
  }
  {
    local $ENV{DOCKER_TLS_VERIFY} = '';
    is client()->tls, 0, 'the empty string is the only set value that is off';
  }
  {
    delete local $ENV{DOCKER_TLS_VERIFY};
    is client()->tls, 0, 'and unset is off, which is the old default unchanged';
  }

  {
    local $ENV{DOCKER_TLS_VERIFY} = '1';
    is client(tls => 0)->tls, 0, 'an explicit tls => 0 outranks the variable';
    delete local $ENV{DOCKER_TLS_VERIFY};
    is client(tls => 1)->tls, 1, 'and an explicit tls => 1 needs no variable';
  }
};

subtest 'DOCKER_TLS_VERIFY is ignored on a socket host' => sub {
  # The CLI ignores it there too -- cli/context/docker/load.go, "there's no
  # need to configure TLS for a socket connection", true for unix, npipe and
  # fd. Here it MUST be ignored rather than merely being tidy: BUILD croaks on
  # tls => 1 with a non-tcp:// host, so a host-blind default would make a bare
  # API::Docker->new die on every machine that talks to a local socket and
  # happens to export the variable -- this repo's own default host included.
  local $ENV{DOCKER_TLS_VERIFY} = '1';

  for my $host (
    'unix:///var/run/docker.sock',
    'unix:///run/user/1000/podman/podman.sock',
  ) {
    my $docker = eval { API::Docker->new(host => $host, api_version => '1.41') };
    is $@, '', $host . ' still constructs';
    is $docker->tls, 0, 'and TLS stayed off, so BUILD had nothing to croak about';
  }

  my ($bare, $err) = do {
    local $ENV{DOCKER_HOST} = 'unix:///var/run/docker.sock';
    local $@;
    my $client = eval { API::Docker->new };
    ($client, $@);
  };
  is $err, '', 'including the no-argument constructor a consumer writes';
  is $bare->tls, 0,
    'which is the shape ../p5-dist-zilla-plugin-docker-api builds its client in';
};

subtest 'DOCKER_TLS_VERIFY with no certificates is the system trust store' => sub {
  # The third constraint: non-empty means encrypt and verify, and the CLI asks
  # for no DOCKER_CERT_PATH alongside it. Not a croak and not a new code path
  # -- it is already what tls => 1 with cert_path => undef means here.
  local $ENV{DOCKER_TLS_VERIFY} = '1';
  delete local $ENV{DOCKER_CERT_PATH};

  my $docker = eval { client() };
  is $@, '', 'a tcp:// client with no certificates anywhere constructs';
  is $docker->tls, 1, 'with TLS on';
  is $docker->cert_path, undef, 'and no certificate directory to read';
  is $docker->tls_insecure, 0,
    'verification is still on: the CLI sets InsecureSkipVerify = !TLSVerify, '
    . 'so non-empty is encrypt AND verify';
};

subtest 'tls => 1 on a unix:// host croaks' => sub {
  # A Unix socket is a file, not a wire. Accepting the option would answer a
  # request for an encrypted transport with an unencrypted one, which is the
  # exact failure this ticket was raised about.
  my $err = do {
    local $@;
    eval { API::Docker->new(host => 'unix:///var/run/docker.sock', tls => 1) };
    $@;
  };
  like $err, qr/only meaningful for a tcp:\/\/ host/, 'it says which half is wrong';
  like $err, qr/unix:\/\/\/var\/run\/docker\.sock/, 'and names the host it got';
  like $err, qr/ at \S+ line \d+/, 'croaked, so the caller\'s line is named';
};

subtest 'tls_insecure without tls croaks' => sub {
  # Only reachable while tls is off, and the default is read from the
  # environment now, so the environment is what this subtest pins first.
  delete local $ENV{DOCKER_TLS_VERIFY};

  my $err = do {
    local $@;
    eval { client(tls_insecure => 1) };
    $@;
  };
  like $err, qr/tls_insecure => 1 without tls => 1/,
    'an option that could not do anything is refused, not accepted quietly';

  is client()->tls_insecure, 0, 'the default is off';
  is client(tls => 1, tls_insecure => 1)->tls_insecure, 1,
    'and it is settable alongside tls';
};

subtest 'cert_path on its own still transmits nothing' => sub {
  # Kept from the file this replaces, and still true: cert_path defaults from
  # DOCKER_CERT_PATH, which machines running the docker CLI export, so it must
  # not change anything for a client that never asked for TLS.
  delete local $ENV{DOCKER_TLS_VERIFY};
  my $docker = eval { client(cert_path => '/etc/docker/certs') };
  is $@, '', 'no croak, even though the path does not exist';
  is $docker->cert_path, '/etc/docker/certs', 'the value is kept';
  is $docker->tls, 0, 'and TLS is still off, so nothing reads it';

  local $ENV{DOCKER_CERT_PATH} = '/from/env';
  my $from_env = eval { API::Docker->new(api_version => '1.41') };
  is $@, '', 'a machine with DOCKER_CERT_PATH set still constructs';
  is $from_env->cert_path, '/from/env', 'defaulted from the environment';
};

# ===========================================================================
# The transport now reads both attributes
# ===========================================================================

subtest 'the transport consults tls and cert_path' => sub {
  # The inverse of the claim this replaces, which asserted that
  # API::Docker::Role::HTTP never mentions either attribute and that its
  # tcp:// branch is unconditionally a plain socket.
  my $source = path($INC{'API/Docker/Role/HTTP.pm'})->slurp_utf8;

  ok length($source) > 1000, 'the transport source was actually read';
  like $source, qr/\$self->tls\b/, 'the socket builder asks whether TLS is wanted';
  like $source, qr/\$self->cert_path\b/, 'and reads the certificate directory';
  like $source, qr/IO::Socket::SSL->new/, 'the tcp:// branch can be an SSL socket';
  like $source, qr/IO::Socket::INET->new/, 'and is still a plain one without TLS';
};

SKIP: {
  skip 'IO::Socket::SSL is not installed', 4 unless $HAVE_SSL;

  subtest 'verification is the default' => sub {
    my %ssl = client(tls => 1)->_ssl_options('dockerhost');

    is $ssl{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(),
      'the certificate chain is checked';
    is $ssl{SSL_verifycn_scheme}, 'http',
      'and so is the name on it: a valid certificate for another host is not '
      . 'this host';
    is $ssl{SSL_verifycn_name}, 'dockerhost', 'checked against the host asked for';
    is $ssl{SSL_hostname}, 'dockerhost', 'which is also sent as SNI';

    ok !exists $ssl{SSL_ca_file}, 'no ca file without a cert_path';
    ok !exists $ssl{SSL_cert_file}, 'and no client certificate';
  };

  subtest 'tls_insecure turns verification off, and only that' => sub {
    my %ssl = client(tls => 1, tls_insecure => 1)->_ssl_options('dockerhost');

    is $ssl{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_NONE(),
      'the chain is not checked';
    is $ssl{SSL_verifycn_scheme}, undef, 'nor the name';
    is $ssl{SSL_hostname}, 'dockerhost',
      'SNI is still sent: a terminator serving several names needs it either way';
  };

  subtest 'the cert.pem / key.pem / ca.pem layout' => sub {
    my $dir = Path::Tiny->tempdir;
    $dir->child($_)->spew('') for qw( ca.pem cert.pem key.pem );

    my %ssl = client(tls => 1, cert_path => "$dir")->_ssl_options('dockerhost');
    is $ssl{SSL_ca_file}, $dir->child('ca.pem') . '', 'ca.pem is the trust anchor';
    is $ssl{SSL_cert_file}, $dir->child('cert.pem') . '', 'cert.pem is sent';
    is $ssl{SSL_key_file}, $dir->child('key.pem') . '', 'with key.pem';
    is $ssl{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(),
      'and having certificates does not change the verification policy';

    my $ca_only = Path::Tiny->tempdir;
    $ca_only->child('ca.pem')->spew('');
    my %anchor = client(tls => 1, cert_path => "$ca_only")->_ssl_options('dockerhost');
    is $anchor{SSL_ca_file}, $ca_only->child('ca.pem') . '', 'ca.pem alone is used';
    ok !exists $anchor{SSL_cert_file},
      'and is a daemon this client verifies without authenticating to it';

    my $client_only = Path::Tiny->tempdir;
    $client_only->child($_)->spew('') for qw( cert.pem key.pem );
    my %pair = client(tls => 1, cert_path => "$client_only")->_ssl_options('dockerhost');
    ok !exists $pair{SSL_ca_file},
      'no ca.pem falls back to the system trust store rather than croaking';
    is $pair{SSL_cert_file}, $client_only->child('cert.pem') . '',
      'while the client certificate is still sent';
  };

  subtest 'the layouts that are mistakes' => sub {
    for my $half (['cert.pem', 'key.pem'], ['key.pem', 'cert.pem']) {
      my ($present, $missing) = @$half;
      my $dir = Path::Tiny->tempdir;
      $dir->child($present)->spew('');
      my $err = do {
        local $@;
        eval { client(tls => 1, cert_path => "$dir")->_ssl_options('dockerhost') };
        $@;
      };
      like $err, qr/\Q$missing\E missing/,
        "$present without $missing croaks, naming the half that is gone";
      like $err, qr/Both cert\.pem and key\.pem are needed, or neither/,
        'and says what a complete client certificate is';
    }

    my $err = do {
      local $@;
      eval { client(tls => 1, cert_path => '/no/such/certificate/directory')
        ->_ssl_options('dockerhost') };
      $@;
    };
    like $err, qr{cert_path /no/such/certificate/directory is not a directory},
      'a cert_path naming nothing croaks rather than connecting without the '
      . 'certificates the caller believes are in use';
  };
}

subtest 'IO::Socket::SSL is a recommended dependency, and says so when absent' => sub {
  # It is required at the moment the first TLS connection is opened, not at
  # compile time, because the unix:// transport never needs it. Simulated by
  # hiding it from require rather than by uninstalling it.
  my $err = do {
    local %INC = %INC;
    delete $INC{'IO/Socket/SSL.pm'};
    local @INC = (sub {
      my (undef, $filename) = @_;
      die "Can't locate $filename in \@INC\n" if $filename eq 'IO/Socket/SSL.pm';
      return;
    }, @INC);
    local $@;
    eval { client(tls => 1)->_load_ssl };
    $@;
  };

  like $err, qr/needs IO::Socket::SSL/, 'the croak names the module';
  like $err, qr/cpanm IO::Socket::SSL/, 'and how to install it';
  like $err, qr/recommended rather than a required/,
    'and why it was not there already';
};

# ===========================================================================
# A real handshake, against a TLS server this file starts
# ===========================================================================

SKIP: {
  skip 'IO::Socket::SSL is not installed', 1 unless $HAVE_SSL;
  skip 'IO::Socket::SSL::Utils cannot generate certificates', 1
    unless eval { require IO::Socket::SSL::Utils; 1 };
  skip 'no fork on this platform', 1 unless $Config{d_fork};

  my $dir = Path::Tiny->tempdir;
  my ($ca, $cakey) = IO::Socket::SSL::Utils::CERT_create(
    CA => 1, subject => { CN => 'API-Docker test CA' });
  my ($server, $server_key) = IO::Socket::SSL::Utils::CERT_create(
    issuer          => [$ca, $cakey],
    subject         => { CN => 'localhost' },
    purpose         => 'server',
    subjectAltNames => [ [ DNS => 'localhost' ], [ IP => '127.0.0.1' ] ],
  );
  my ($other, $other_key) = IO::Socket::SSL::Utils::CERT_create(
    issuer          => [$ca, $cakey],
    subject         => { CN => 'otherhost.example' },
    purpose         => 'server',
    subjectAltNames => [ [ DNS => 'otherhost.example' ] ],
  );
  my ($cert, $key) = IO::Socket::SSL::Utils::CERT_create(
    issuer => [$ca, $cakey], subject => { CN => 'a-client' }, purpose => 'client');

  IO::Socket::SSL::Utils::PEM_cert2file($ca, $dir->child('ca.pem') . '');
  IO::Socket::SSL::Utils::PEM_cert2file($cert, $dir->child('cert.pem') . '');
  IO::Socket::SSL::Utils::PEM_key2file($key, $dir->child('key.pem') . '');
  IO::Socket::SSL::Utils::PEM_cert2file($server, $dir->child('server.pem') . '');
  IO::Socket::SSL::Utils::PEM_key2file($server_key, $dir->child('server-key.pem') . '');
  IO::Socket::SSL::Utils::PEM_cert2file($other, $dir->child('other.pem') . '');
  IO::Socket::SSL::Utils::PEM_key2file($other_key, $dir->child('other-key.pem') . '');

  # One connection, one canned /version response, and the client certificate
  # CN the server saw handed back over a pipe.
  my $serve = sub {
    my (%o) = @_;
    my $listen = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
      Listen => 1, ReuseAddr => 1) or die "listen: $!";
    my $port = $listen->sockport;
    pipe(my $read, my $write) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
      close $read;
      my $conn = $listen->accept;
      if ($conn && IO::Socket::SSL->start_SSL($conn,
        SSL_server    => 1,
        SSL_cert_file => $dir->child($o{cert} || 'server.pem') . '',
        SSL_key_file  => $dir->child($o{key} || 'server-key.pem') . '',
        ($o{demand_client_cert} ? (
          SSL_ca_file     => $dir->child('ca.pem') . '',
          SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER()
            | IO::Socket::SSL::SSL_VERIFY_FAIL_IF_NO_PEER_CERT(),
        ) : ()),
      )) {
        my $cn = $conn->peer_certificate('cn');
        print $write (defined $cn ? $cn : '(none)'), "\n";
        close $write;
        while (my $line = <$conn>) { last if $line =~ /^\r?\n\z/ }
        my $body = '{"ApiVersion":"1.41"}';
        print $conn "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
          . 'Content-Length: ' . length($body) . "\r\nConnection: close\r\n\r\n"
          . $body;
        close $conn;
      }
      close $listen;
      exit 0;
    }
    close $write;
    return ($port, $pid, $read);
  };

  subtest 'a real TLS handshake' => sub {
    subtest 'ca.pem verifies the daemon' => sub {
      my ($port, $pid, $read) = $serve->();
      my $docker = API::Docker->new(host => "tcp://localhost:$port",
        api_version => '1.41', tls => 1, cert_path => "$dir");
      my $version = eval { $docker->get('/version') };
      is $@, '', 'the request went through';
      is $version->{ApiVersion}, '1.41',
        'and the JSON came back decoded, so HTTP runs over the TLS socket unchanged';
      waitpid $pid, 0;
    };

    subtest 'cert.pem and key.pem identify the client' => sub {
      my ($port, $pid, $read) = $serve->(demand_client_cert => 1);
      my $docker = API::Docker->new(host => "tcp://localhost:$port",
        api_version => '1.41', tls => 1, cert_path => "$dir");
      my $version = eval { $docker->get('/version') };
      is $@, '', 'a daemon demanding a client certificate is satisfied';
      is $version->{ApiVersion}, '1.41', 'and answers';
      chomp(my $cn = <$read> // '');
      is $cn, 'a-client', 'the server saw the CN out of cert.pem';
      waitpid $pid, 0;
    };

    subtest 'without the CA the connection is refused' => sub {
      # tls => 1 with no certificates means the system trust store, and a
      # daemon signed by a private CA is not in it. This is the intended
      # failure, not a silent downgrade.
      my ($port, $pid, $read) = $serve->();
      my $docker = API::Docker->new(host => "tcp://localhost:$port",
        api_version => '1.41', tls => 1, cert_path => undef);
      my $err = do { local $@; eval { $docker->get('/version') }; $@ };
      like $err, qr/over TLS/, 'it croaks as a connection failure';
      like $err, qr/verify failed/i, 'naming certificate verification';
      kill 'TERM', $pid;
      waitpid $pid, 0;
    };

    subtest 'tls_insecure connects to that same daemon anyway' => sub {
      my ($port, $pid, $read) = $serve->();
      my $docker = API::Docker->new(host => "tcp://localhost:$port",
        api_version => '1.41', tls => 1, cert_path => undef, tls_insecure => 1);
      my $version = eval { $docker->get('/version') };
      is $@, '', 'an unverifiable certificate is accepted';
      is $version->{ApiVersion}, '1.41', 'and the request completes';
      waitpid $pid, 0;
    };

    subtest 'a certificate for another name is refused' => sub {
      # Signed by the trusted CA, so only the name check can catch it.
      my ($port, $pid, $read) = $serve->(cert => 'other.pem', key => 'other-key.pem');
      my $docker = API::Docker->new(host => "tcp://localhost:$port",
        api_version => '1.41', tls => 1, cert_path => "$dir");
      my $err = do { local $@; eval { $docker->get('/version') }; $@ };
      like $err, qr/hostname verification failed/,
        'a valid certificate for otherhost.example is not one for localhost';
      kill 'TERM', $pid;
      waitpid $pid, 0;
    };
  };
}

done_testing;
