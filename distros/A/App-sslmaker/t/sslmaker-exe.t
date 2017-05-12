use strict;
use Path::Tiny 'path';
use Test::More;

$ENV{SSLMAKER_SUBJECT} = '/C=US/ST=Texas/L=Dallas/O=Company/OU=Department/CN=superduper';

plan skip_all => 'linux is required' unless $^O =~ /linux|darwin/;
plan skip_all => 'openssl is required' if system 'openssl -h 2>/dev/null';

my @unlink = map { my $i = $_; map { "client$i.example.com.$_.pem" } qw( cert csr key ) } 1..2;
my $root = path('local/tmp/sslmaker-exe');
my $script;

unlink @unlink;

{
  local @ARGV = qw( --silent );
  $script = do 'script/sslmaker' or plan skip_all => $@;
  $script->bits(1024); # speed up testing
  $script->silent(1);
  $root->remove_tree({safe => 0});
  $root->mkpath;
  ok !-d $root->child('CA'), 'nothing exists';
}

{
  diag 'sslmaker root';
  $script->home($root->child('CA'));
  $script->run('root');
  ok -e $root->child('CA/certs/ca.cert.pem'), 'CA/certs/ca.cert.pem';
  ok -e $root->child('CA/index.txt'), 'CA/index.txt';
  ok -e $root->child('CA/private/ca.key.pem'), 'CA/private/ca.key.pem';
  ok -e $root->child('CA/private/passphrase'), 'CA/private/passphrase';
  ok -e $root->child('CA/serial'), 'CA/serial';
}

{
  diag 'sslmaker intermediate';
  $script->root_home($root->child('CA'));
  $script->home($root->child('intermediate'));
  $script->run('intermediate');
  ok -e $root->child('intermediate/certs/ca.cert.pem'), 'intermediate/certs/ca.cert.pem';
  ok -e $root->child('intermediate/certs/ca.csr.pem'), 'intermediate/certs/ca.csr.pem';
  ok -e $root->child('intermediate/certs/ca-chain.cert.pem'), 'intermediate/certs/ca-chain.cert.pem';
  ok -e $root->child('intermediate/index.txt'), 'intermediate/index.txt';
  ok -e $root->child('intermediate/private/ca.key.pem'), 'intermediate/private/ca.key.pem';
  ok -e $root->child('intermediate/private/passphrase'), 'intermediate/private/passphrase';
  ok -e $root->child('intermediate/serial'), 'intermediate/serial';
}

{
  diag 'sslmaker generate example.com';
  $script->root_home('');
  $script->run(qw( generate client1.example.com ));
  $script->run(qw( generate client2.example.com ));
  ok -e 'client1.example.com.key.pem', 'client1.example.com.key.pem';
  ok -e 'client1.example.com.csr.pem', 'client1.example.com.csr.pem';
  ok !-e 'client1.example.com.cert.pem', 'client1.example.com.cert.pem need to be created by intermediate';

  diag 'sslmaker sign example.com.csr.pem';
  $script->root_home('');
  $script->run(qw( sign client1.example.com.csr.pem ));
  $script->run(qw( sign client2.example.com.csr.pem ));
  ok -e 'client2.example.com.cert.pem', 'client2.example.com.cert.pem was created by intermediate';

  my $index = $root->child('intermediate/index.txt')->slurp;
  like $index, qr{^V.*CN=client1\.example\.com$}m, 'index.txt has V client1.example.com';
  like $index, qr{^V.*CN=client2\.example\.com$}m, 'index.txt has V client2.example.com';
}

{
  diag 'sslmaker revoke example.com';
  $script->run(qw( revoke client2.example.com.cert.pem ));
  $script->run(qw( revoke client1.example.com.cert.pem ));

  my $index = $root->child('intermediate/index.txt')->slurp;
  like $index, qr{^R.*CN=client1\.example\.com$}m, 'index.txt has R client1.example.com';
  like $index, qr{^R.*CN=client2\.example\.com$}m, 'index.txt has R client2.example.com';
}

unlink @unlink;

$root->remove_tree({safe => 0});
done_testing;
