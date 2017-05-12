#!perl -w

use strict;

=head1 NAME

acceptance-issue-certificatesJSON.t - Query a live Camel-PKI CA server over
JSON-RPC using an administrator certificate, and have it issue some
new certificates.

=cut

use Test::More;

use App::CamelPKI::Certificate;
use App::CamelPKI::PrivateKey;
use App::CamelPKI;
use App::CamelPKI::Test qw(jsoncall_remote);

my $webserver = App::CamelPKI->model("WebServer")->apache;
if ($webserver->is_installed_and_has_perl_support && $webserver->is_operational) {
	plan tests => 5;
} else {
	plan skip_all => "Apache is not insalled or Key Ceremnoy has not been done !";
}
$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

my $port = $webserver->https_port();

=pod

The data structure to present to the JSON-RPC server is set forth in
L<App::CamelPKI::CertTemplate::VPN/certifyJSON>.

=cut

my $req = {
     requests => [
      { template => "VPN1",
        dns      => "foo.example.com",
      },
      { template => "VPN1",
        dns      => "bar.example.com",
      },
      { template => "VPN1",
        dns      => "foo.example.com",
      },
      { template => "VPN1",
        dns      => "bar.example.com",
      }
     ],
   };

=pod

The expected response is also laid out in
L<App::CamelPKI::CertTemplate::VPN/certifyJSON>.

=cut

my ($cert, $key) = App::CamelPKI->model("CA")->make_admin_credentials;

my $response = jsoncall_remote
    ("https://localhost:$port/ca/template/vpn/certifyJSON", $req,
     -certificate => $cert, -key => $key);
is(scalar(@{$response->{keys}}), 4, "four answers");
map {
    is(App::CamelPKI::Certificate->parse($_->[0])->get_public_key->serialize,
       App::CamelPKI::PrivateKey->parse($_->[1])->get_public_key->serialize,
       "keys match");
} @{$response->{keys}};
