#!perl -w

use strict;

=head1 NAME

03-VPNRequestByForm.t : Test for issuing VPN certificates using the form.

=cut

use Test::More;
use Test::Group;

my $webserver = App::CamelPKI->model("WebServer")->apache;

if ($webserver->is_installed_and_has_perl_support && $webserver->is_operational) {
	plan tests => 2;
} else {
	plan skip_all => "Apache is not insalled or Key Ceremony has not been done !";
}

use App::CamelPKI::Certificate;
use App::CamelPKI::PrivateKey;
use App::CamelPKI;
use App::CamelPKI::Test;

$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

my $port = $webserver->https_port();

=pod

The data structure to complete the form data.

=cut

my $reqVPN = {
		("template" => "VPN1",
		"dns" => "foo.bar.com")
};

=pod

The expected response is also laid out in
L<App::CamelPKI::CertTemplate::VPN/certify>.

=cut
sub get_vpn_certificate {
	my ($params) = @_;

	my ($certCA, $keyCA) = App::CamelPKI->model("CA")->make_admin_credentials;
	my $response = formcall_remote
   		("https://localhost:$port/ca/template/vpn/certifyForm", $params,  "Submit",
   	 	-certificate => $certCA, -key => $keyCA);
	
	like($response, qr/-----BEGIN CERTIFICATE-----/, "a certificate is in the answer (VPN)");
	like($response, qr/-----BEGIN RSA PRIVATE KEY-----/, "a private Key is in the answer (VPN)");


	my ($cert, $key) = split(/-----END CERTIFICATE-----\n/,$response);
	$cert = $cert."-----END CERTIFICATE-----";
	return $cert, $key;
	
}

test "VPN Certificate request" => sub {
    my ($cert, $key) = get_vpn_certificate($reqVPN);
	my $certificate = App::CamelPKI::Certificate->parse($cert);
	like($certificate->get_subject_DN->to_string, qr/$reqVPN->{dns}/, "Dns is present inthe certificate (VPN)");

	my $PrivateKey = App::CamelPKI::PrivateKey->parse($key);
	is ($certificate->get_public_key->get_modulus, $PrivateKey->get_modulus, "Certificate and key fitted together (VPN)");
};

test "OpenVPN Certificates" => sub {
	my $OpenVPNServer = {
		("template" => "OpenVPNServer",
		 "dns" => "foo.bar.com")
	};
	
	my $OpenVPNClient = {
		("template" => "OpenVPNClient",
		 "email" => 'pki@camelpki.com')
	};
	
	my ($cert, $key) = get_vpn_certificate($OpenVPNServer);
	my $certificate = App::CamelPKI::Certificate->parse($cert);
	like($certificate->get_subject_DN->to_string, qr/$OpenVPNServer->{dns}/, "Dns is present inthe certificate (OpenVPNServer)");

	my $PrivateKey = App::CamelPKI::PrivateKey->parse($key);
	is ($certificate->get_public_key->get_modulus, $PrivateKey->get_modulus, "Certificate and key fitted together (OpenVPNServer)");
	
	($cert, $key) = get_vpn_certificate($OpenVPNClient);
	$certificate = App::CamelPKI::Certificate->parse($cert);
	like($certificate->get_subject_DN->to_string, qr/$OpenVPNClient->{email}/, "email is present inthe certificate (OpenVPNClient)");

	$PrivateKey = App::CamelPKI::PrivateKey->parse($key);
	is ($certificate->get_public_key->get_modulus, $PrivateKey->get_modulus, "Certificate and key fitted together (OpenVPNClient)");	
		
}