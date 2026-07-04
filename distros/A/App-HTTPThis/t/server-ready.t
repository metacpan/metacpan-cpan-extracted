use strict;
use warnings;

use Test::More;
use App::HTTPThis;

# Capture what _server_ready prints to the currently-selected filehandle.
sub ready_output {
  my (%args) = @_;
  my $app = bless { root => '.' }, 'App::HTTPThis';

  my $out = '';
  open my $fh, '>', \$out or die "cannot open in-memory handle: $!";
  my $old = select $fh;
  $app->_server_ready( { proto => 'http', port => 7007, %args } );
  select $old;
  close $fh;

  return $out;
}

subtest 'bound to all interfaces (no host)' => sub {
  my $out = ready_output( host => 0 );
  like $out, qr{http://127\.0\.0\.1:7007/}, 'shows a clickable localhost URL';
  like $out, qr/all network interfaces/i,
    'warns that it is reachable on all network interfaces';
  like $out, qr/--host 127\.0\.0\.1/,
    'explains how to restrict access to localhost';
};

subtest 'bound to all interfaces (0.0.0.0)' => sub {
  my $out = ready_output( host => '0.0.0.0' );
  like $out, qr{http://127\.0\.0\.1:7007/}, 'shows a clickable localhost URL';
  like $out, qr/all network interfaces/i, 'warns about all interfaces';
  like $out, qr/--host 127\.0\.0\.1/, 'explains how to restrict access';
};

subtest 'bound to localhost explicitly' => sub {
  my $out = ready_output( host => '127.0.0.1' );
  like $out, qr{http://127\.0\.0\.1:7007/}, 'shows the localhost URL';
  unlike $out, qr/all network interfaces/i,
    'no all-interfaces warning when bound to localhost';
};

subtest 'bound to a specific address' => sub {
  my $out = ready_output( host => '192.168.0.5' );
  like $out, qr{http://192\.168\.0\.5:7007/}, 'shows the requested host';
  unlike $out, qr/all network interfaces/i,
    'no all-interfaces warning for a specific address';
};

subtest 'bound to all interfaces (IPv6 ::)' => sub {
  my $out = ready_output( host => '::' );
  like $out, qr{http://\[::1\]:7007/}, 'shows the IPv6 loopback URL';
  like $out, qr/all network interfaces/i, 'warns about all interfaces';
  like $out, qr/--host ::1/, 'explains how to restrict access for IPv6';
};

done_testing;
