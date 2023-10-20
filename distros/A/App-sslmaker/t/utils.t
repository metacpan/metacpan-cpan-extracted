use strict;
use Test::More;
use App::sslmaker;

plan skip_all => "$^O is not supported" if $^O eq 'MSWin32';
plan skip_all => 'openssl is required'  if system 'openssl version >/dev/null';
mkdir 'local';

my $sslmaker = App::sslmaker->new;

{
  ok $sslmaker->isa('App::sslmaker'), 'App::sslmaker';
  is $sslmaker->subject, '', 'default subject';
  like $sslmaker->_random_passphrase(63), qr/^[A-Za-z0-9]{63}$/, 'generated passphrase';
  is(
    $sslmaker->subject('/C=NO/ST=Oslo/L=Oslo/O=Example/OU=Prime/CN=example.com/emailAddress=admin@example.com',
      '/C=US/CN=/emailAddress=jhthorsen@cpan.org')->subject,
    '/C=US/ST=Oslo/L=Oslo/O=Example/OU=Prime/CN=/emailAddress=jhthorsen@cpan.org',
    'merged ssl subject',
  );

  is eval { $sslmaker->openssl(qw(genrsa -invalid)); 'ok' }, undef, 'genrsa -invalid 42';
  like $@, qr{invalid}, 'openssl died';
}

{
  my $asset = $sslmaker->render_to_file('index.txt', {});
  my $path  = $asset->canonpath;
  like $asset->slurp, qr{^\s*$}s, 'index.txt template';
  undef $asset;
  ok !-e $path, 'index.txt was a temp file';
}

{
  unlink 'local/utils-test-serial';
  my $asset = $sslmaker->render_to_file('serial', 'local/utils-test-serial', {});
  my $path  = $asset->canonpath;
  like $asset->slurp, qr{^1000\s*$}s, 'serial template';
  undef $asset;
  ok -e $path, 'serial is not a temp file';
  unlink 'local/utils-test-serial';
}

{
  my $path;
  $sslmaker->with_config(
    sub {
      $path = $ENV{OPENSSL_CONF};
    },
    {home => 'local/tmp/utils',},
  );

  ok $path,    'OPENSSL_CONF generated';
  ok -e $path, 'OPENSSL_CONF file exist';

  my $conf = Path::Tiny->new($path)->slurp;
  like $conf, qr{^dir = /.*/tmp/utils$}m,   "dir = /..tmp";
  like $conf, qr{^default_bits = 4096$}m,   'default_bits = 4096';
  like $conf, qr{^default_crl_days = 30$}m, 'default_crl_days = 30';
  like $conf, qr{^default_days = 365$}m,    'default_days = 365';

  undef $sslmaker;
  ok !-e $path, 'OPENSSL_CONF file removed';
}

done_testing;
