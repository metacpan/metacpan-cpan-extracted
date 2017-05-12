#!perl -w

use strict;
use warnings;

=head1 NAME

04-RevokeByForm.t : pass tests for revoking certificates using forms.

=cut

use Test::More;
use Test::Group;

my $webserver = App::CamelPKI->model("WebServer")->apache;


if ($webserver->is_installed_and_has_perl_support && $webserver->is_operational) {
	plan tests => 3;
} else {
	plan skip_all => "Apache is not insalled or Key Ceremnoy has not been done !";
}


use Catalyst::Test;
use Catalyst::Utils;
use App::CamelPKI::CRL;
use App::CamelPKI;
use App::CamelPKI::Test;

$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

my $port = $webserver->https_port();

=pod

The data structure to complete the form data.

=cut



my $reqSSLServer = {
		("template" => "SSLServer",
		"dns" => "test.foo.com")
};

my $reqSSLServerRevoke = {
	"type" => "dns",
	"data" => "test.foo.com",
};

my $reqSSLClient = {
		("template" => "SSLClient",
		"role" => "test.bar")
};

my $reqVPN = {
		("dns" => "test.foo.bar.com")
};

=pod

The expected response is also laid out in
L<App::CamelPKI::CertTemplate::SSL/certify>.

=cut

my ($CAcert, $CAkey) = App::CamelPKI->model("CA")->make_admin_credentials;

test "Revocation SSLServer" => sub {
	
	my $certSSL = certify("ssl", "SSLServer", "dns", "test.foo.com");
	
	ok(! cert_is_revoked($certSSL), "Certificate not inserted ?");
	
	revoke("ssl", "dns", "test.foo.com");

	ok(cert_is_revoked($certSSL), "Certificate not revoked !");
};

test "Revocation SSLClient" => sub {
	
	my $certSSL = certify("ssl", "SSLClient", "role", "test.bar");
	
	ok(! cert_is_revoked($certSSL), "Certificate not inserted ?");
	
	revoke("ssl", "role", "test.bar");

	ok(cert_is_revoked($certSSL), "Certificate not revoked !");
};

test "Revocation VPN" => sub {
	
	my $cert = certify("vpn", "VPN1", "dns", "test.foo.com");
	
	ok(! cert_is_revoked($cert), "Certificate not inserted ?");
	
	revoke("vpn", "dns", "test.foo.com");

	ok(cert_is_revoked($cert), "Certificate not revoked !");
};

=head2 certify($type_cert, $template, $type, $data)

Certify the certificate.

=cut

sub certify {
	my ($type_cert, $template, $type, $data) = @_;
	my $req = {
			"template" => $template,
			$type => $data,
		};

	my $resp_server = formcall_remote
   		("https://localhost:$port/ca/template/$type_cert/certifyForm", $req, "Submit",
   	 		-certificate => $CAcert, -key => $CAkey);
   
   	return App::CamelPKI::Certificate->parse($resp_server);
};

=head2 revoke($type_cert, $type, $data)

revoke the certificate using forms

=cut

sub revoke{
	my ($type_cert, $type, $data) = @_;
	my $req = {
		"type" => $type,
		"data" => $data,
	};
	formcall_remote
   		("https://localhost:$port/ca/template/$type_cert/revokeForm", $req, "Submit",
   	 		-certificate => $CAcert, -key => $CAkey);
};

=head2 cert_is_revoked($certobj)

Returns true if $certobj is currently in the CRL.

=cut

sub cert_is_revoked {
    my $crl = App::CamelPKI::CRL->parse
        (plaintextcall_remote("https://localhost:$port/ca/current_crl"));
        
    return $crl->is_member(shift);
};