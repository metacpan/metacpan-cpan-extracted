use strict;
use Path::Tiny 'path';
use Test::More;

plan skip_all => "$^O is not supported" if $^O eq 'MSWin32';
plan skip_all => 'openssl is required'  if system 'openssl version >/dev/null';

my @unlink = map {
  my $i = $_;
  map {"client$i.example.com.$_.pem"} qw(cert csr key)
} 1 .. 2;
my $home = path('local/tmp/sslmaker');
my $script;

unlink @unlink;
delete $ENV{OPENSSL_CONF};

subtest 'silent' => sub {
  local @ARGV = qw(--silent);
  do './script/sslmaker' or plan skip_all => $@;
  $script = App::sslmaker::script->new;
  $script->{silent} = 1;
  $home->remove_tree({safe => 0});
  $home->mkpath;
  ok !-d $home->child('root'), 'nothing exists';
};

subtest 'sslmaker root' => sub {
  $script->{home}    = $home;
  $script->{subject} = '/C=US/ST=Texas/L=Dallas/O=Company/OU=Department/CN=superduper';
  is eval { $script->subcommand_root }, 0, 'ran' or diag $@;
  ok -e $home->child('root/ca.cert.pem'), 'root/ca.cert.pem';
  ok -e $home->child('root/index.txt'),   'index.txt';
  ok -e $home->child('root/ca.key.pem'),  'root/ca.key.pem';
  ok -e $home->child('root/passphrase'),  'root/passphrase';
  ok -e $home->child('root/serial'),      'root/serial';
};

subtest 'sslmaker intermediate' => sub {
  $script->{subject} = '';    # read subject from root CA
  is eval { $script->subcommand_intermediate }, 0, 'ran' or diag $@;

  ok -e $home->child('root/ca.cert.pem'), 'root/ca.cert.pem';
  ok -e $home->child('root/index.txt'),   'root/index.txt';
  ok -e $home->child('root/ca.key.pem'),  'root/ca.key.pem';
  ok -e $home->child('root/passphrase'),  'root/passphrase';
  ok -e $home->child('root/serial'),      'root/serial';

  ok -e $home->child('certs/ca.cert.pem'),       'certs/ca.cert.pem';
  ok -e $home->child('certs/ca.csr.pem'),        'certs/ca.csr.pem';
  ok -e $home->child('certs/ca-chain.cert.pem'), 'certs/ca-chain.cert.pem';
  ok -e $home->child('index.txt'),               'index.txt';
  ok -e $home->child('private/ca.key.pem'),      'private/ca.key.pem';
  ok -e $home->child('private/passphrase'),      'private/passphrase';
  ok -e $home->child('serial'),                  'serial';
};

subtest 'sslmaker generate example.com' => sub {
  is eval { $script->subcommand_generate('client1.example.com') }, 0, 'client1.example.com' or diag $@;
  is eval { $script->subcommand_generate('client2.example.com') }, 0, 'client2.example.com' or diag $@;
  ok -e 'client1.example.com.key.pem',   'client1.example.com.key.pem';
  ok -e 'client1.example.com.csr.pem',   'client1.example.com.csr.pem';
  ok !-e 'client1.example.com.cert.pem', 'client1.example.com.cert.pem need to be created from intermediate';
};

subtest 'sslmaker sign example.com.csr.pem' => sub {
  is eval { $script->subcommand_sign('client1.example.com.csr.pem') }, 0, 'ran' or diag $@;
  is eval { $script->subcommand_sign('client2.example.com.csr.pem') }, 0, 'ran' or diag $@;
  ok -e 'client2.example.com.cert.pem', 'client2.example.com.cert.pem was created from intermediate';

  my $index = $home->child('index.txt')->slurp;
  like $index, qr{^V.*CN=client1\.example\.com$}m, 'index.txt has V client1.example.com';
  like $index, qr{^V.*CN=client2\.example\.com$}m, 'index.txt has V client2.example.com';

  my ($csr, $crt);
  App::sslmaker::openssl(qw(req -noout -text -in)  => 'client1.example.com.csr.pem',  sub { $csr = pop });
  App::sslmaker::openssl(qw(x509 -noout -text -in) => 'client1.example.com.cert.pem', sub { $crt = pop });
  like $csr, qr{DNS:client1.example.com}, 'csr subjectAltName';
  like $crt, qr{DNS:client1.example.com}, 'crt subjectAltName';
};

subtest 'sslmaker revoke example.com' => sub {
  is eval { $script->subcommand_revoke('client2.example.com.cert.pem') }, 0, 'ran' or diag $@;
  is eval { $script->subcommand_revoke('client1.example.com.cert.pem') }, 0, 'ran' or diag $@;

  my $index = $home->child('index.txt')->slurp;
  like $index, qr{^R.*CN=client1\.example\.com$}m, 'index.txt has R client1.example.com';
  like $index, qr{^R.*CN=client2\.example\.com$}m, 'index.txt has R client2.example.com';
};

unlink @unlink;
$home->remove_tree({safe => 0});
done_testing;
