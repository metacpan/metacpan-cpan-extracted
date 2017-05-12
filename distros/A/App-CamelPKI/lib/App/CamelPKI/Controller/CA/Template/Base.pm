package App::CamelPKI::Controller::CA::Template::Base;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

App::CamelPKI::Controller::CA::Template::Base - Base class for all template
controllers in Camel-PKI

=head1 DESCRIPTION

A B<template controller> is an entry point into Camel-PKI : it consists
of the code that responds to the JSON-RPC requests for issuing or
revoking certificates.  Other user-initiated Certification Authority
operations in Camel-PKI are handled by L<App::CamelPKI::Controller::CA>.

Template controllers are grouped in categories, just like the
certificate templates in the C<App::CamelPKI::CertTemplate::*> namespace.
Each class in the C<App::CamelPKI::Controller::CA::Template::*> namespace
deals with one such category of templates,
e.g. L<App::CamelPKI::Controller::CA::Template::SSL> serves certification
and revocation requests for templates C<App::CamelPKI::Controller::SSLServer> and
C<App::CamelPKI::Controller::SSLClient> , both implemented within 
the L<App::CamelPKI::CertTemplate::SSL> module.

All template controllers inherit from this class,
I<App::CamelPKI::Controller::CA::Template::Base>, which is abstract.  They
overload the L</OVERLOADABLE METHODS>, and wire up the C<certify> and
C<revoke> actions.


=head1 ACTIONS

These actions are inherited by template controllers, and are mapped
into their respective URL namespaces unless appropriate Catalyst
counter-mojo is performed.  However, these actions are not mapped in
the base class (because they have no meaning there).

=begin internals

=head2 register_actions()

Overloaded so as to do nothing in the superclass.

=end internals

=cut

sub register_actions {
    my $self = shift;
    return if (ref($self) || $self) eq __PACKAGE__;
    return $self->NEXT::register_actions(@_);
}

=head2 certifyJSON($reqdetails) : Local : ActionClass("+App::CamelPKI::Action::JSON")

Requests the issuance of a number of certificates in this template
family.  $reqdetails (passed as the JSON-RPC POST payload) is a
reference to a structure like this (here for
L<App::CamelPKI::Controller::CA::Template::SSL>, other template groups would
obviously use different values for C<template>):

   {
     requests => [
      { template => "SSLServer",
        role     => "foo",
        dns      => "bar.example.com",
      },
      { template => "SSLClient",
        role     => "bar",
        dns      => "bar.example.com",
      },
      { template => "SSLClient",
        role     => "bar",
        dns      => "bar.example.com",
      },
      { template => "SSLClient",
        dns      => "bar.example.com",
      }
     ],
   }

$reqdetails->{requests} is a reference to list with one entry per
certificate to issue.

According to the coherency requirements set forth in certificate
template code, requesting a new certificate that collides with a
pre-existing one results in the latter being revoked implicitly;
requesting two colliding certificates within the same call to
I<certify> throws an exception.

The response is transmitted as an C<application/json> HTTP document,
with the following structure (again in Perl syntax):

  {
     keys => [
        [ $cert1, $key1 ],
        [ $cert2, $key2 ],
        [ $cert3, $key3 ],
        [ $cert4, $key4 ],
     ],
  }

where $cert1, ... are certificates in PEM formats; $key1, ... are
private keys in PEM format; and the certificates and keys are in the
same order as the $reqdetails->{requests} list outlined above.

I<certify> works as a single transaction, and will therefore either
complete in whole or fail in whole; in no case will the response
contain a smaller number of certificates than the request list.

=cut

sub certifyJSON : Local : ActionClass("+App::CamelPKI::Action::JSON") {
    my ($self, $c, $trans) = @_;

    my $valid_templates_regex =
        join("|", $self->_list_template_shortnames());

    my $ca = $c->model("CA")->instance;
    my @PrivateKeys;
    foreach my $req (@{$trans->{requests}}) {
    	my $keyPriv = App::CamelPKI::PrivateKey->genrsa($self->{keysize});
    	push @PrivateKeys, $keyPriv->serialize(-format => "PEM");
    	if ($req->{template} =~ m/^($valid_templates_regex)$/) {
            my $template = "App::CamelPKI::CertTemplate::$1";
            $ca->issue($template, $keyPriv->get_public_key,
                       map { $_ => $req->{$_} } ($template->list_keys()));
    	} else {
            die "Unknown template $req->{template}";
    	}
    }
    my @pemCert = $ca->commit;
    foreach my $cert(@pemCert){
    	$cert = $cert->serialize();
    	my $key = shift @PrivateKeys;
    	push @{$c->stash->{keys}}, [ $cert, $key ];
    }
}


=head2 certifyForm : Local

This function is used to redirect the user to the right template 
depending on the url used to go to this functions, for example :
http://127.0.0.1/ca/template/ssl/certifyForm will redirect
on the appropriate form for SSL certificates.

This assumes that every certificate's template own a function named
_form_certify_template that represents the url of the TT2 template
starting from the App/CamelPKI/root directory.

=cut

sub certifyForm : Local {	
	my ($self, $c) = @_;
	$c->stash->{template} = $self->_form_certify_template;
}

=head2 certify

Requests the issuance of a certificate.
Parameters are passed as form's requests.
For example, for  L<App::CamelPKI::Controller::CA::Template::SSLClient> 
the request should be :
$c->request->params->template="SSLClient"
$c->request->params->dns="foo.bar.com"
$c->request->params->role="administration"

The certificate and the key is returned as a PEM file containing
the generated certificate and the private key.
  
=cut

sub certify : Local {
	my ($self, $c) = @_;
	
	my $valid_templates_regex =
    	join("|", $self->_list_template_shortnames());
	
	my $ca = $c->model("CA")->instance;
	my $keyPriv = App::CamelPKI::PrivateKey->genrsa($self->{keysize});
	my $tempPerso = $c->request->params->{template};
	
	if ($c->request->params->{template} =~ m/^($valid_templates_regex)$/) {
    	my $template = "App::CamelPKI::CertTemplate::$tempPerso";
        $ca->issue($template, $keyPriv->get_public_key,
        	map { $_ => $c->request->params->{$_} } ($template->list_keys()));
    } else {
    	die "Unknown template $c->request->params->{template}";
    }
    
    my @pemCert = $ca->commit;
    
    foreach my $cert(@pemCert){
    	$cert = $cert->serialize();
    	my $key = $keyPriv->serialize(-format => "PEM");
    	$c->response->content_type("application/octet-stream");
    	$c->response->body($cert.$key);
    }
}

=head2 revokeForm : Local

This function is used to redirect the user to the right template 
depending on the url used to go to this functions, for example :
http://127.0.0.1/ca/template/ssl/revokeForm will redirect
on the appropriate form for SSL certificates.

This assumes that every certificate's template own a function named
_form_template and that represents the url of the TT2 template
starting from the App/CamelPKI/root directory.

=cut

sub revokeForm : Local {
	my ($self, $c) = @_;
	$c->stash->{template} = $self->_form_revoke_template;
}

=head2 revoke

Revokes a set of certificates at once. The datas are passed by a form.

$c->request->params->{type}="dns"
$c->request->params->{data}="foo.bar.com"

The effect is to revoke all certificates that have foo.bar.com as their DNS
name in any of the templates that this controller class deals with.

=cut

sub revoke : Local {
	my ($self, $c) = @_;

    my $ca = $c->model("CA")->instance;
    my $type = $c->request->params->{type};
    my $data = $c->request->params->{data};
    foreach my $shorttemplate ($self->_list_template_shortnames()) {
        my $template = "App::CamelPKI::CertTemplate::$shorttemplate";
        my @revocation_criteria =
            map { ($type =~ m/$_/) ?
                      ($_ => $data) :
                          () } ($self->_revocation_keys);
        throw App::CamelPKI::Error::User
            ("Attempt revoke whole template group")
                if ! @revocation_criteria;
        warn @revocation_criteria;
        $ca->revoke($template, $_)
            for $ca->database->search
                (template => $template, @revocation_criteria);
    }
    $ca->commit;
    $c->stash->{type}=$type;
    $c->stash->{data}=$data;
    $c->stash->{template} = "certificate/revocation_done.tt2";
}


=head2 revokeJSON($revocdetails)

Revokes a set of certificates at once. The $revocdetails structure is
of the following form:

    {
        dns => $host
    }

The effect is to revoke all certificates that have $host as their DNS
name in any of the templates that this controller class deals with.

=cut

sub revokeJSON : Local :  ActionClass("+App::CamelPKI::Action::JSON") {
    my ($self, $c, $revocdetails) = @_;

	print "\n\n\n 1-- ".Data::Dumper::Dumper($self->_revocation_keys."\n\n\n");
    my $ca = $c->model("CA")->instance;
    foreach my $shorttemplate ($self->_list_template_shortnames()) {
        my $template = "App::CamelPKI::CertTemplate::$shorttemplate";
        
        my @revocation_criteria =
            map { exists($revocdetails->{$_}) ?
                      ($_ => $revocdetails->{$_}) :
                          () } ($self->_revocation_keys);
        throw App::CamelPKI::Error::User
            ("Attempt revoke whole template group")
                if ! @revocation_criteria;
        $ca->revoke($template, $_)
            for $ca->database->search
                (template => $template, @revocation_criteria);
    }
    $ca->commit;
}

=head2 view_operations 

returns to the right view for listing possiblities with templates.

=cut

sub view_operations : Local {
	my ($self, $c) = @_;
	$c->stash->{template} = $self->_operations_available;
}

=head1 OVERLOADABLE METHODS

=head2 _list_template_shortnames

Shall return the list of the short names of the templates that this
controller deals with.  There is no base class implementation.

=cut

# No base class implementation

=head2 _revocation_keys

Shall return the list of nominative data keys that are allowed as
criteria for batch revocation.  The base class implementation is to
use only C<dns>.

=cut

sub _revocation_keys { "dns" }

1;
