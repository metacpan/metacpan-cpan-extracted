use strict;
use IO::Socket::INET;
use Time::HiRes 'usleep';
use Test::More;
use App::sslmaker;

$ENV{SSLMAKER_SUBJECT}
  = '/C=NO/ST=Oslo/L=Oslo/O=Example/OU=Prime/CN=example.com/emailAddress=admin@example.com';

=commands

These commands can come in handy if something fail:

openssl verify -CAfile local/tmp/real/ca/certs/ca.cert.pem local/tmp/real/intermediate/certs/intermediate.cert.pem
openssl verify -CAfile local/tmp/real/intermediate/certs/ca-chain.cert.pem local/tmp/real/client.cert.pem
openssl x509 -noout -text -in local/tmp/real/ca/certs/ca.cert.pem
openssl x509 -noout -text -in local/tmp/real/intermediate/certs/intermediate.cert.pem
openssl x509 -noout -text -in local/tmp/real/client.cert.pem | grep 'Issuer\|Subject'
openssl x509 -noout -text -in local/tmp/real/server.cert.pem | grep 'Issuer\|Subject'

=cut

plan skip_all => "$^O is not supported" if $^O eq 'MSWin32';
plan skip_all => 'IO::Socket::IP 0.20 required' unless eval 'use IO::Socket::IP 0.20; 1';
plan skip_all => 'IO::Socket::SSL 1.84 required' unless eval 'use IO::Socket::SSL 1.84; 1';

my $home = Path::Tiny->new('local/tmp/real');
$home->remove_tree({safe => 0});    # remove old files

# create ssl certificates
create_root_ca();
create_intermediate_ca();
create_cert($_) for qw(server client);

$IO::Socket::SSL::DEBUG = $ENV{SSL_DEBUG} || 0;

my $host = '127.0.0.1';
my $port = IO::Socket::INET->new(Listen => 5, LocalAddr => $host)->sockport;    # random port
my $pid  = fork // plan skip_all => "Could not fork: $!";

# run server in child process
exit run_echo_server() if $pid == 0;

# run tests in parent process
eval {
  my $client = connect_to_echo_server();
  ok $client, 'connected to server';
  print $client "CAN HAZ SSL?\n";
  is(
    readline($client),
    "You (/C=NO/ST=Oslo/L=Oslo/O=Example/OU=Prime/CN=client.example.com/emailAddress=admin\@example.com) sent: CAN HAZ SSL?\n",
    'got echo data'
  );
};

plan skip_all => $@ if $@;

# end server
kill 9, $pid;
is wait, $pid, 'waited for child process';

$home->remove_tree({safe => 0});    # remove old files
done_testing;

#==============================================================================

sub create_root_ca {
  my $sslmaker = App::sslmaker->new;
  my $args     = {
    bits       => 1024,                                    # really bad bits
    cert       => $home->child('ca/certs/ca.cert.pem'),
    key        => $home->child('ca/private/ca.key.pem'),
    passphrase => $home->child('ca/private/passphrase'),
    subject    => '/CN=root.example.com',
    templates  => 1,
  };

  $sslmaker->make_directories($args);
  $sslmaker->with_config(make_key  => $args);
  $sslmaker->with_config(make_cert => $args);
}

sub create_intermediate_ca {
  my $sslmaker = App::sslmaker->new;
  my $args     = {
    bits       => 1024,                                                        # really bad bits
    csr        => $home->child('intermediate/certs/intermediate.csr.pem'),
    key        => $home->child('intermediate/private/intermediate.key.pem'),
    passphrase => $home->child('intermediate/private/passphrase'),
    subject    => '/CN=intermediate.example.com',
    templates  => 1,
  };

  $sslmaker->make_directories($args);
  $sslmaker->with_config(make_key => $args);
  $sslmaker->with_config(make_csr => $args);
  $sslmaker->with_config(
    sign_csr => {
      extensions => 'v3_ca',
      ca_cert    => $home->child('ca/certs/ca.cert.pem'),
      ca_key     => $home->child('ca/private/ca.key.pem'),
      cert       => $home->child('intermediate/certs/intermediate.cert.pem'),
      csr        => $args->{csr},
      passphrase => $home->child('ca/private/passphrase'),
    }
  );

  $sslmaker->_cat(
    $home->child('intermediate/certs/intermediate.cert.pem'),
    $home->child('ca/certs/ca.cert.pem'),
    $home->child('intermediate/certs/ca-chain.cert.pem'),
  );
}

sub create_cert {
  my $type     = shift;
  my $sslmaker = App::sslmaker->new;
  my $args     = {
    bits    => 1024,                            # really bad bits
    csr     => $home->child("$type.csr.pem"),
    key     => $home->child("$type.key.pem"),
    subject => "/CN=$type.example.com",
  };

  $sslmaker->with_config(make_key => $args);
  $sslmaker->with_config(make_csr => $args);
  $sslmaker->with_config(
    sign_csr => {
      extensions => 'usr_cert',
      ca_cert    => $home->child('intermediate/certs/intermediate.cert.pem'),
      ca_key     => $home->child('intermediate/private/intermediate.key.pem'),
      cert       => $home->child("$type.cert.pem"),
      csr        => $args->{csr},
      passphrase => $home->child('intermediate/private/passphrase'),
    }
  );
}

sub run_echo_server {
  my %args = (
    Listen                 => 10,
    LocalAddr              => $host,
    LocalPort              => $port,
    SSL_ca_file            => $home->child('intermediate/certs/ca-chain.cert.pem')->stringify,
    SSL_cert_file          => $home->child('server.cert.pem')->stringify,
    SSL_key_file           => $home->child('server.key.pem')->stringify,
    SSL_honor_cipher_order => 1,
    SSL_verify_mode        => 1,
  );

  my $s = IO::Socket::SSL->new(%args)
    or die "[SERVER] Failed to listen: $! ($IO::Socket::SSL::SSL_ERROR)";

  while (1) {
    note "Waiting for client to connect";
    my $client = $s->accept
      or die "[SERVER] Failed to accept or ssl handshake: $! ($IO::Socket::SSL::SSL_ERROR)";
    my $buf     = $client->readline;
    my $subject = $client->peer_certificate('subject');
    note $subject;
    $client->print("You ($subject) sent: $buf");
  }
}

sub connect_to_echo_server {
  my $guard = 3;
  my %args  = (
    PeerHost        => $host,
    PeerPort        => $port,
    SSL_ca_file     => $home->child('intermediate/certs/ca-chain.cert.pem')->stringify,
    SSL_cert_file   => $home->child('client.cert.pem')->stringify,
    SSL_key_file    => $home->child('client.key.pem')->stringify,
    SSL_verify_mode => 0,
  );

  while ($guard--) {
    note "Trying to connect to server ($pid)";
    usleep 300e3;
    my $client = IO::Socket::SSL->new(%args) or next;
    return $client;
  }

  die "[CLIENT] Failed connect or ssl handshake: $! ($IO::Socket::SSL::SSL_ERROR)";
}
