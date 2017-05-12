#!perl -w

use strict;
use warnings;

use Test::More;
use Test::Group;
use App::CamelPKI;

my $webserver = App::CamelPKI->model("WebServer")->apache;

if ($webserver->is_operational) {
	plan tests => 9;
} else {
	plan skip_all => "Key ceremony has not be done !";
}

=head1 NAME

03-VPNRequestByForm.t : Test for issuing VPN certificates using JSON.

=cut

use_ok 'Catalyst::Test';
use_ok 'Catalyst::Utils';
use_ok 'JSON';
use_ok 'Crypt::OpenSSL::CA';
use_ok 'App::CamelPKI::Test';
use_ok 'App::CamelPKI::Test', 'camel_pki_chain';
use_ok 'App::CamelPKI::Certificate';


test "demande unique" => sub {
 	my $role = "test";
 	my $dns = "monsite.com";
 	my $res = 
 	jsoncall_local("http://localhost:3000/ca/template/vpn/certifyJSON",
 		{"requests" , [ {"template" => "OpenVPNServer", "dns" => $dns} ] });

	is(scalar(@{$res->{keys}}), 1, "1 answer");

	my $cert = App::CamelPKI::Certificate->parse($res->{keys}->[0]->[0]);
	my $dn = $cert->get_subject_DN->to_string;

	like($dn, qr/$dns/, "DNS dans le dn");


	my $PrivateKey = App::CamelPKI::PrivateKey->parse($res->{keys}->[0]->[1]);
	is ($cert->get_public_key->get_modulus, $PrivateKey->get_modulus, "Certificates and key fitted together");
};
 
 
 
test "three certificates (VPN1, OpenVPNServer, et OpenVPNClient)" => sub {
	my $dns_vpn = "monsite.com";
 	my $dns_openvpnserver = "monsite2.com";
 	my $email_openvpnclient = 'pki@camelpki.com';
 	
 	my $res = 
 	jsoncall_local("http://localhost:3000/ca/template/vpn/certifyJSON",
 		{"requests" , [ {"template" => "VPN1", "dns" => $dns_vpn},
                                {"template" => "OpenVPNServer", "dns" => $dns_openvpnserver},
                                {"template" => "OpenVPNClient", "email" => $email_openvpnclient} ] });

	is(scalar(@{$res->{keys}}), 3, "3 answers");
	
	foreach my $keyandcert (@{$res->{keys}}) {
            my $cert = $keyandcert->[0];
            certificate_chain_ok($cert, [ &camel_pki_chain ]);
        }
};