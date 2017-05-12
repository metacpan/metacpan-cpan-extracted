package App::CamelPKI::Controller::CA;

use strict;
use warnings;
use base 'Catalyst::Controller';
use App::CamelPKI::CA;

=head1 NAME

App::CamelPKI::Controller::CA - Camel-PKI Certiciate Authority controller.

=head1 DESCRIPTION

This controller provides the CA-wide actions that are independent of
any given certificate template.

Actions with name ending by C<_pem> don't use L<App::CamelPKI::View::JSON>,
but rather transmit directly their data in text/plain; this enables
operation with very basic clients (e.g. 'wget').  Most of these
text/plain actions do not require a client certificate and are
publicly accessible.

=over

=item I<certificate_pem>

Returns the AC certicate, in PEM format.

Note: the Content-Type is C<text/plain>, and not
C<application/pkix-cert> (as mentioned in RFC2585), because it
would seem that the latter is intended for DER format.

=cut

sub certificate_pem : Local {
    my ($self, $c) = @_;

    $c->response->content_type("text/plain");
    $c->response->body($c->model("CA")->instance->certificate->serialize);
}

=item I<certificate_chain_pem>

Returns a list of certificates in PEM format concatenated
together. The first of these certificates is the same that
L</certicate_pem>; the whole list constitues a valid certification
chain in the sense of RFC3280 section 6.

=cut

sub certificate_chain_pem : Local {
    my ($self, $c) = @_;
    $c->response->content_type("text/plain");
    my $ca = $c->model("CA");
    $c->response->body
        (join("", $ca->instance->certificate->serialize,
              map { $_->serialize } ($ca->certification_chain)));
}

=item I<gen_crl>

Immediately generates a new CRL, and returns it in PEM format.

Note: the Content-Type is C<text/plain>, and not
C<application/pkix-cert> (as mentioned in RFC2585), because it would
seem that the latter is intended for DER format.

=cut

sub gen_crl : Local {
    my ($self, $c) = @_;
    $c->response->content_type("text/plain");
    $c->response->body($c->model("CA")->instance->issue_crl->serialize);
}


=item I<current_crl>

Returns the last CRL issued by L</gen_crl>, unless it is set to expire
shortly, in which case a new CRL is generated, stored and returned.

=cut

sub current_crl : Local {
    my ($self, $c) = @_;
    $c->forward("gen_crl"); # FIXME: implement caching.
}

=item I<examine_crl>

Sends the right template in order to consult the CRL.

=cut

sub examine_crl : Local {
	my ($self, $c) = @_;
	$c->stash->{crl} = $c->model("CA")->instance->issue_crl->serialize;
	$c->stash->{template} = "crl/consult.tt2";
}

=item I<download_crl>

Sends back in a text file in DER format the CRL.

=cut

sub download_crl : Local{
	my ($self, $c) = @_;
	$c->response->content_type("application/octet-stream");
	my $crl = App::CamelPKI::CRL->parse(
					$c->model("CA")->instance->issue_crl->serialize,
					-format => "PEM");
					
    $c->response->body($crl->serialize(-format => "DER"));
}

=item I<list_issued_certificates>

Gets the list of Certificates wich are currently issued and not revoked yet.

=cut

sub list_issued_certificates : Local{
	my ($self, $c) = @_;
	my @certs = $c->model("CA")->instance->get_certificates_issued;
	foreach my $myCert (@certs){
		push @{$c->stash->{certs}},
			{
				serial => $myCert->get_serial,
				subject => $myCert->get_subject_DN->to_string,
				notBefore => $myCert->get_notBefore,
				notAfter => $myCert->get_notAfter,
			};
	}
	$c->stash->{template} = "certificate/list_issued.tt2";
}

=item I<list_revoked_certificates>

Gets the list of Certificates wich are currently revoked.

=cut

sub list_revoked_certificates : Local{
	my ($self, $c) = @_;
	my @certs = $c->model("CA")->instance->get_certificates_revoked;
	foreach my $myCert (@certs){
		push @{$c->stash->{certs}},
			{
				serial => $myCert->get_serial,
				subject => $myCert->get_subject_DN->to_string,
				notBefore => $myCert->get_notBefore,
				notAfter => $myCert->get_notAfter,
				public_key => $myCert->get_public_key->serialize,
			};
	}
	$c->stash->{template} = "certificate/list_revoked.tt2";
}

=back

=cut

1;
