use strict;
use Test::More;
use App::sslmaker;

plan skip_all => "$^O is not supported" if $^O eq 'MSWin32';
plan skip_all => 'openssl is required'  if system 'openssl version >/dev/null';

my $asset;
my $intermediate_home = Path::Tiny->new('local/tmp/step-2-intermediate/intermediate');
my $ca_home           = Path::Tiny->new('local/tmp/step-2-intermediate/ca');
my $ca_args           = {
  cert       => $ca_home->child('certs/ca.cert.pem'),
  days       => 20,
  home       => $ca_home,
  key        => $ca_home->child('private/ca.key.pem'),
  passphrase => $ca_home->child('private/passphrase'),
  subject    => '/CN=whatever.example.com',
};

# clean up old run
$ca_home->remove_tree({safe => 0})           if -d $ca_home;
$intermediate_home->remove_tree({safe => 0}) if -d $intermediate_home;

subtest 'tested in t/act-as-your-own-certificate-authority.t' => sub {
  my $sslmaker = App::sslmaker->new;
  $sslmaker->make_directories({home => $ca_home, templates => 1});
  $sslmaker->with_config(make_key => $ca_args);
  ok -e $ca_args->{key}, 'ca key created';
  $sslmaker->with_config(make_cert => $ca_args);
  ok -e $ca_args->{cert}, 'ca cert created';
};

subtest 'make intermediate' => sub {
  my $cert;
  my $sslmaker          = App::sslmaker->new;
  my $intermediate_args = {
    home       => $intermediate_home,
    key        => $intermediate_home->child('private/intermediate.key.pem'),
    passphrase => $intermediate_home->child('private/passphrase'),
    csr        => $intermediate_home->child('certs/intermediate.csr.pem'),
    days       => 20,
    subject    => '/CN=test.example.com',
  };

  $sslmaker->make_directories({home => $intermediate_home, templates => 1});

  $sslmaker->with_config(make_key => $intermediate_args);
  ok -e $intermediate_args->{key}, 'intermediate key created';
  is + (stat $intermediate_args->{key})[2] & 0777, 0400, 'key mode 400';

  $asset = $sslmaker->with_config(make_csr => $intermediate_args);
  ok -e $asset, 'intermediate csr created';
  is $asset,                   $intermediate_args->{csr}, 'correct asset location';
  is +(stat $asset)[2] & 0777, 0400,                      'csr mode 400';

  $asset = $sslmaker->with_config(
    sign_csr => {
      ca_cert    => $ca_args->{cert},
      ca_key     => $ca_args->{key},
      csr        => $intermediate_args->{csr},
      extensions => 'v3_ca',
      home       => $ca_home,
      passphrase => $ca_args->{passphrase},
    }
  );

  ok -e $asset, 'csr was signed with ca key';
  $cert = $asset->parent->child('intermediate.cert.pem');
  $asset->move($cert);
  undef $sslmaker;
  undef $asset;
  ok -e $cert, 'intermediate cert was moved from temp location';

  like $ca_home->child('index.txt')->slurp, qr{CN=test\.example\.com}, 'cert was added to index.txt';
  like $ca_home->child('serial')->slurp,    qr{^1001$}m,               'serial was modified';
};

$ca_home->remove_tree({safe => 0});
$intermediate_home->parent->remove_tree({safe => 0});

done_testing;
