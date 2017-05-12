#!perl -w

use strict;
use warnings;

=head1 NAME

CRL.t - test the CRL in a various way.
=cut

use Test::More;

use Catalyst::Test;
use App::CamelPKI;
use Test::Group;
use Catalyst::Utils;
use App::CamelPKI::Test;


my $webserver = App::CamelPKI->model("WebServer")->apache;
if ($webserver->is_installed_and_has_perl_support && $webserver->is_operational) {
	plan tests => 2;
} else {
	plan skip_all => "Apache is not insalled or Key Ceremnoy has not been done !";
}
$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

my $port = $webserver->https_port();

my ($CAcert, $CAkey) = App::CamelPKI->model("CA")->make_admin_credentials;

test "CRL in plain text" => sub {
	my $response = call_remote
   		("https://localhost:$port/ca/gen_crl",
   			-certificate => $CAcert, -key => $CAkey);
	like($response, qr/-----BEGIN X509 CRL-----/);
	like($response, qr/-----END X509 CRL-----/);
};

SKIP: {
	skip "Not implemented", 1 if 1;
	test "CRL in DER Format" => sub {
		#TODO : code the test
	};
}



