#!perl -w

use strict;
use warnings;

use Test::More;
use Test::Group;

my $webserver = App::CamelPKI->model("WebServer")->apache;

if ($webserver->is_operational) {
	plan tests => 2;
} else {
	plan skip_all => "Key ceremony has not be done !";
}

=head1 NAME

02-SSLRequestByJSON.t : Test for issuing SSL certificates using JSON.

=cut
use Catalyst::Test;
use App::CamelPKI;
use Catalyst::Utils;
use JSON;
use Crypt::OpenSSL::CA;
use App::CamelPKI::Test;
use App::CamelPKI::Test qw(camel_pki_chain);
use App::CamelPKI::Certificate;


test "Unique demand" => sub {
 	my $role = "test";
 	my $dns = "monsite.com";
 	my $res = 
 	jsoncall_local("http://localhost:3000/ca/template/ssl/certifyJSON",
 		{"requests" , [ {"template" => "SSLServer", "dns" => $dns} ] });

	is(scalar(@{$res->{keys}}), 1, "1 answer");

	my $cert = App::CamelPKI::Certificate->parse($res->{keys}->[0]->[0]);
	my $dn = $cert->get_subject_DN->to_string;

	like($dn, qr/$dns/, "DNS dans le dn");


	my $PrivateKey = App::CamelPKI::PrivateKey->parse($res->{keys}->[0]->[1]);
	is ($cert->get_public_key->get_modulus, $PrivateKey->get_modulus, "Certificate and key fitted together");
};
 
 
 
test "three certificates (SSLServer et SSLClient)" => sub {
 	my $role = "test2";
 	my $dns = "monsite2.com";
 	my $res = 
 	jsoncall_local("http://localhost:3000/ca/template/ssl/certifyJSON",
 		{"requests" , [ {"template" => "SSLServer", "dns" => $dns},
 						{"template" => "SSLClient", "role" => $role} ] });
	
	is(scalar(@{$res->{keys}}), 2, "2 answers");

	my $certSSLClient = App::CamelPKI::Certificate->parse($res->{keys}->[1]->[0]);
	my $dn = $certSSLClient->get_subject_DN->to_string;
	like($dn, qr/$role/, "Role in dn"); 

	my $PrivateKey = App::CamelPKI::PrivateKey->parse($res->{keys}->[1]->[1]);
	is ($certSSLClient->get_public_key->get_modulus, $PrivateKey->get_modulus, "Certificate and key fitted together");
	
	
	
	foreach my $keyandcert (@{$res->{keys}}) {
        my $cert = $keyandcert->[0];
    	certificate_chain_ok($cert, [ &camel_pki_chain ]);
    }
}