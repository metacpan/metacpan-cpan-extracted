#!perl -w

use strict;
use warnings;

use Catalyst::Test;
use Catalyst::Utils;
use JSON;
use Test::More;
use Test::Group;

use App::CamelPKI;
use App::CamelPKI::Test;

=head1 NAME

04-RevokeByJSON.t : pass tests for revoking certificates using JSON.

=cut


my $webserver = App::CamelPKI->model("WebServer")->apache;
if ($webserver->is_installed_and_has_perl_support && $webserver->is_operational) {
	plan tests => 5;
} else {
	plan skip_all => "Apache is not insalled or Key Ceremnoy has not been done !";
}
$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

my $port = $webserver->https_port();



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

my $reqOpenVPNServer = {
		("dns" => "test.foo.bar.com")
};

my $reqOpenVPNClient = {
		("dns" => 'pki@pki.com')
};

=pod

The expected response is also laid out in
L<App::CamelPKI::CertTemplate::SSL/certify>.

=cut

my ($CAcert, $CAkey) = App::CamelPKI->model("CA")->make_admin_credentials;

test "Revocation SSLServer" => sub {
	
	my $certSSL = certify("ssl", "SSLServer", "dns", "test.foo.com");
	
	ok(! cert_is_revoked($certSSL), "Certificate not inserted ?");
	
	revoke("ssl", {"dns", "test.foo.com"});

	ok(cert_is_revoked($certSSL), "Certificate not revoked !");
};

test "Revocation SSLClient" => sub {
	
	my $certSSL = certify("ssl", "SSLClient", "role", "test.bar");
	
	ok(! cert_is_revoked($certSSL), "Certificate not inserted ?");
	
	revoke("ssl", {"role", "test.bar"});

	ok(cert_is_revoked($certSSL), "Certificate not revoked !");
};

test "Revocation VPN" => sub {
	
	my $cert = certify("vpn", "VPN1", "dns", "test.foo.com");
	
	ok(! cert_is_revoked($cert), "Certificate not inserted ?");
	
	revoke("vpn", {"dns", "test.foo.com"});

	ok(cert_is_revoked($cert), "Certificate not revoked !");
};

test "Revocation OpenVPNServer" => sub {
	my $cert = certify("vpn", "OpenVPNServer", "dns", "test.openvpn.com");
	ok(! cert_is_revoked($cert), "Certificate not inserted ?");
	revoke("vpn", {"dns", "test.openvpn.com"});
	ok(cert_is_revoked($cert), "Certificate not revoked !");
};

test "Revocation OpenVPNServer" => sub {
	my $cert = certify("vpn", "OpenVPNClient", "email", 'pki@pki.com');
	ok(! cert_is_revoked($cert), "Certificate not inserted ?");
	revoke("vpn", {"email", 'pki@pki.com'});
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
	my $resp_server = 
		jsoncall_local("http://localhost:3000/ca/template/$type_cert/certifyJSON",
 			{ "requests" , [ $req ] });

   	return App::CamelPKI::Certificate->parse($resp_server->{keys}->[0]->[0].$resp_server->{keys}->[0]->[1]);
};

=head2 revoke($type_cert, $type, $data)

revoke the certificate using JSON

=cut

sub revoke{
	my ($type_cert, $req) = @_;
	
	my $resp = jsonreq_remote
   		("https://localhost:$port/ca/template/$type_cert/revokeJSON", $req,
   			-certificate => $CAcert, -key => $CAkey);
	
};

=head2 cert_is_revoked($certobj)

Returns true if $certobj is currently in the CRL.

=cut

sub cert_is_revoked {
    my $crl = App::CamelPKI::CRL->parse
        (plaintextcall_remote("https://localhost:$port/ca/current_crl"));
        #print Data::Dumper::Dumper($crl);
        my $dlcrl = shift;

    return $crl->is_member($dlcrl);
};