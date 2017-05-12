#!perl -w

use strict;

=head1 NAME

acceptance-revoke-certificatesJSON.t - Revoke certificates using a
client certificate authenticated JSON-RPC call

=head1 DESCRIPTION

In Camel-PKI, revocation occurs in batches across several templates at
once in an ad-hoc fashion: e.g. the revoke operation in the "BB"
template class only stipulates a hostname, and all certificates with
this hostname in all three templates BB1, BB2 and BB3 get revoked at
once.

=cut

use Test::More;

use App::CamelPKI::Certificate;
use App::CamelPKI::PrivateKey;
use App::CamelPKI::CRL;
use App::CamelPKI;
use App::CamelPKI::Test qw(jsoncall_remote plaintextcall_remote);
use App::CamelPKI::Error;

my $webserver = App::CamelPKI->model("WebServer")->apache;
if ($webserver->is_installed_and_has_perl_support && $webserver->is_operational) {
	plan tests => 16;
} else {
	plan skip_all => "Apache is not insalled or Key Ceremnoy has not been done !";
}
$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

my $port = $webserver->https_port();



our ($cert, $key) = App::CamelPKI->model("CA")->make_admin_credentials;

=head1 TEST OVERVIEW

First, make the certificates for the tests.

=cut

our @certs;

my $testhost1 = "foo.example.com";
my $testhost2 = "bar.example.com";

certify("VPN",
        # $certs[0]
        { template => "VPN1", dns      => $testhost1 },
        # $certs[1]
        { template => "VPN1", dns      => $testhost2 },
        );

foreach my $i (0..$#certs) {
    ok($certs[$i]->isa("App::CamelPKI::Certificate"),
       "certificate $i isa App::CamelPKI::Certificate");
    ok(! cert_is_revoked($certs[$i]), "certificate $i is valid");
}

revoke("VPN", { dns => $testhost1 });

ok(! cert_is_revoked($certs[1]), "Cert 1 was not revoked");
ok(cert_is_revoked($certs[0]), "Cert 0 was revoked");


=pod

The SSL template is special, as there is no C<dns> field in SSLClient
certificates.  Therefore it is possible to revoke by C<role>, for this
template group only.

=cut

@certs = ();

certify("SSL",
        { template => "SSLServer", dns => $testhost1 },
        { template => "SSLClient", role => "play" });

is(scalar(@certs), 2, "2 Certificates issued");
grep { ok(! cert_is_revoked($_), "no certs revoked yet") } @certs;

revoke("SSL", { dns => $testhost1 });
ok(cert_is_revoked($certs[0]), "revoked by hostname");
ok(! cert_is_revoked($certs[1]), "not revoked yet");

certify("SSL",
        { template => "SSLServer", dns => $testhost1 });
ok(! cert_is_revoked($certs[2]), "new cert to take the place "
   . "of the one just revoked");

revoke("SSL", { role => "play" });
ok(cert_is_revoked($certs[0]), "still revoked");
ok(cert_is_revoked($certs[1]), "just revoked");
ok(! cert_is_revoked($certs[2]), "still valid");

=pod

It shall not be possible to revoke all certificates in a template
group at once.

=cut

try {
    revoke("VPN", {});
    fail;
} catch Error with {
    pass "Can't revoke whole group (VPN)";
};


exit; ############################################


=head1 TEST LIBRARY

=head2 certify($shortname, $req1, $req2, ...)

Requests the certificates over JSON-RPC in template $shortname
(e.g. "BB") and appends them to global variable @certs.

=cut

sub certify {
    my ($shortname, @reqs) = @_;
    $shortname = lc($shortname);
    push(@certs, map { App::CamelPKI::Certificate->parse($_->[0]) }
         (@{jsoncall_remote
                ("https://localhost:$port/ca/template/$shortname/certifyJSON",
                 { requests => [ @reqs ]},
             -certificate => $cert, -key => $key)->{keys}}));
}

=head2 cert_is_revoked($certobj)

Returns true if $certobj is currently in the CRL.

=cut

our $crl;

sub cert_is_revoked {
    $crl = App::CamelPKI::CRL->parse
        (plaintextcall_remote("https://localhost:$port/ca/current_crl"))
            unless defined $crl;

    return $crl->is_member(shift);
}

=head2 revoke($shortname, $revokereq)

Sends revocation $revokereq (e.g. C<< { dns => "foo.example.com" } >>)
to the revocation controller named $shortname (e.g. C<BB>).
Invalidates the CRL cache of L</cert_is_revoked>.

=cut

sub revoke {
    my ($shortname, $revokereq) = @_;
    $shortname = lc($shortname);
    jsoncall_remote
        ("https://localhost:$port/ca/template/$shortname/revokeJSON", $revokereq,
         -certificate => $cert, -key => $key);
    undef $crl;
}
