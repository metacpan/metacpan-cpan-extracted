use strict;
use Test::More;
use App::sslmaker;

# https://jamielinux.com/articles/2013/08/act-as-your-own-certificate-authority/

plan skip_all => 'Cannot build on Win32' if $^O eq 'MSWin32';
plan skip_all => 'openssl is required' if system 'openssl -h 2>/dev/null';

my $sslmaker = App::sslmaker->new;
my $home = Path::Tiny->new('local/tmp/step-1-ca');
my $asset;

$home->remove_tree({ safe => 0 });

{
  $sslmaker->make_directories({ home => $home, templates => 1 });

  ok -d $home->child('certs'), 'certs dir';
  ok -d $home->child('crl'), 'crl dir';
  ok -d $home->child('newcerts'), 'newcerts dir';
  is +(stat $home->child('private'))[2] & 0777, 0700, 'private dir mode 700';
  is +(stat $home->child('index.txt'))[2] & 0777, 0644, 'index.txt file mode 644';
  is +(stat $home->child('serial'))[2] & 0777, 0644, 'serial file mode 644';
}

{
  my $args = {
    bits => 1024,
    cert => $home->child('certs/ca.cert.pem'),
    days => 365 * 20,
    home => $home,
    key => $home->child('private/ca.key.pem'),
    passphrase => $home->child('private/passphrase'),
  };

  $asset = $sslmaker->with_config(make_key => $args);

  ok -e $asset, 'key created';
  is $asset, $args->{key}, 'asset is not remporary';
  is -s $args->{passphrase}, 64, 'passphrase has correct length';
  is +(stat $args->{passphrase})[2] & 0777, 0400, 'passphrase mode 400';
  is +(stat $asset)[2] & 0777, 0400, 'key mode 400';

  $asset = $sslmaker->with_config(make_cert => $args);
  ok -e $asset, 'cert created';
  is +(stat $asset)[2] & 0777, 0444, 'cert mode 444';
}

$home->remove_tree({ safe => 0 });
done_testing;
