#!perl -w

use strict;
use warnings;

use Test::More;
use App::CamelPKI;
use App::CamelPKI::Test qw(plaintextcall_remote
                      certificate_chain_ok run_thru_openssl);
use File::Slurp qw(write_file);
use File::Spec::Functions qw(catfile);
use LWP::UserAgent;


my $webserver = App::CamelPKI->model("WebServer")->apache;
if ($webserver->is_installed_and_has_perl_support && $webserver->is_operational) {
	plan tests => 4;
} else {
	plan skip_all => "Apache is not insalled or Key Ceremnoy has not been done !";
}
$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

my $port = $webserver->https_port();

sub request {
    my ($uri) = @_;
    $uri = "/$uri" unless $uri =~ m|^/|;
    my $url = "https://localhost:$port$uri";
    my $req = HTTP::Request->new(GET => $url);
    return LWP::UserAgent->new->request($req);
}


=head1 NAME

B<acceptance-get-CA.t> - Fetches the CA certification chain and the
CRL over plain HTTP/S (that is, non-JSON, non-authenticated).

=cut

my $opcacert = plaintextcall_remote
    ("https://localhost:$port/ca/certificate_pem");
like($opcacert, qr/BEGIN CERTIFICATE/, "got the certificate");

my @certs = App::CamelPKI::Certificate->parse_bundle
    (request("/ca/certificate_chain_pem")->content);

certificate_chain_ok($opcacert, [map {$_->serialize} @certs]);

write_file(my $cabundle = catfile(App::CamelPKI::Test->tempdir, "ca-bundle.crt"),
           join("", map {$_->serialize} @certs));

=pod

And now for the CRL.

=cut

my $crlpem = plaintextcall_remote
    ("https://localhost:$port/ca/current_crl");
like($crlpem, qr/BEGIN X509 CRL/, "got the CRL");

run_thru_openssl($crlpem, "crl", -CAfile => $cabundle);
is($?, 0, "CRL looks valid");
