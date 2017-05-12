package App::CamelPKI::Controller::Certificate;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

App::CamelPKI::Controller::Certificate - Camel-PKI Certiciate Certificate controller.

=head1 DESCRIPTION

This controller provides the actions over Certificates.

=over

=item I<show_by_serial>

show informations about a given certificate.

=cut

sub show_by_serial : Local{
	my ($self, $c) = @_;
	my $serial;
	foreach my $part (@{$c->request->arguments}){
		$serial .= $part;
	}
	my $cert = $c->model("CA")->instance->get_certificate_by_serial($serial);
	if ($cert) {
		$c->stash->{cert}->{serial} = $cert->get_serial;
		$c->stash->{cert}->{subject} = $cert->get_subject_DN->to_string;
		$c->stash->{cert}->{not_before} = $cert->get_notBefore;
		$c->stash->{cert}->{not_after} = $cert->get_notAfter;
		$c->stash->{cert}->{public_key} = $cert->get_public_key->serialize;
		$c->stash->{cert}->{issuer} = $cert->get_issuer_DN->to_string;
		$c->stash->{cert}->{subject_key_id} = $cert->get_subject_keyid;
		$c->stash->{cert}->{status} = 
			$c->model("CA")->instance->issue_crl->is_member($cert) ?
				"Revoked" : "Valid" ;
		$c->stash->{template} = 'certificate/info.tt2';
	} else {
		$c->stash->{message} = "The certificate with serial : \"$serial\" doesn't exists.";
		$c->stash->{template} = 'message.tt2';
	}
}




=back

=cut

1;
