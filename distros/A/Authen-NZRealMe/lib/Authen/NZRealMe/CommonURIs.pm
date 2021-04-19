package Authen::NZRealMe::CommonURIs;
$Authen::NZRealMe::CommonURIs::VERSION = '1.23';
use strict;
use warnings;

=head1 NAME

Authen::NZRealMe::CommonURIs - Common mappings for tokens to URIs

=head1 DESCRIPTION

This module is a central location for defining URIs used across this
distribution.  The aim of the module is to reduce duplication and possibility
of errors.

Many of the URIs are namespace URIs which will be used in reading or writing
XML documents.  The chosen prefixes for these namespace URIs are arbitrary.

=cut

use Carp qw(croak);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(URI NS_PAIR);


my(%uri_from_prefix, %prefix_from_uri);  # Populated from the POD below


sub URI {
    my($token) = @_;

    if(my $uri = $uri_from_prefix{$token}) {
        return $uri;
    }
    croak "No URI has been set up for '$token'";
}

sub NS_PAIR {
    my($selector) = @_;

    if(my $uri = $uri_from_prefix{$selector}) {
        return ($selector, $uri);
    }
    elsif(my $prefix = $prefix_from_uri{$selector}) {
        return ($prefix, $selector);
    }
    croak "'$selector' is not a registered namespace prefix or namespace URI";
}

{
    # Populate the %uri_from_prefix lookup hash from the POD below

    use autodie;

    open(my $fh, '<', __FILE__);
    while(<$fh>) {
        if(/^=item\s+(\w+)\s+=>\s+(\S+)\s*$/) {
            $uri_from_prefix{$1} = $2;
            $prefix_from_uri{$2} = $1;
        }
    }
}

1;

__END__

=head1 SYNOPSIS

  use Authen::NZRealMe::CommonURIs qw(URI NS_PAIR);

  say URI('ec14n');   # http://www.w3.org/2001/10/xml-exc-c14n#

  $xc->registerNs( NS_PAIR('ds') );


=head1 FUNCTIONS

The following two functions are exported:

=head2 URI( token )

Takes a simple string argument (like 'ec14n') which is used as a lookup and
returns a URI (like 'http://www.w3.org/2001/10/xml-exc-c14n#').

Will die if there no URI is registered for the supplied token.

=head2 NS_PAIR( prefix or uri )

Takes a simple string argument (like 'ds') which is used as a lookup and
returns a a list of two scalar values: a namespace-prefix => namespace-uri pair
for use with L<XML::LibXML::XPathContext>.  The supplied argument can be used
to look up by namespace prefix or by namespace URI.

After the namespace-prefix => namespace-uri pair have been registered, the
supplied prefix value can be used as a namespace prefix in XPath queries.

Will die if the supplied value cannot be used as a prefix to find a URI or as a
URI to find a prefix.

=head1 IDENTIFIERS

The following token/URI mappings are defined.  For simplicity, they are all
available via both the F<URI()> and the F<NS_PAIR()> functions, although not
all the URIs are actually intended to be used as namespaces in XML.

Sources for these URIs:

  DSIG_CORE   https://www.w3.org/TR/xmldsig-core/#sec-CoreSyntax
  DSIG_ALG    https://www.w3.org/TR/xmldsig-core/#sec-AlgID
  SAML2       https://wiki.oasis-open.org/security/FrontPage#SAML_V2.0_Standard
  SOAP11      https://www.w3.org/TR/2000/NOTE-SOAP-20000508/#_Toc478383494
  SOAP12      https://www.w3.org/TR/2007/REC-soap12-part1-20070427/#soapenvelope
  WSDL        https://www.w3.org/TR/wsdl/#nsprefixes
  WSDL_SOAP   http://schemas.xmlsoap.org/wsdl/soap12/soap12WSDL.htm
  WS_ADDR     https://www.w3.org/TR/ws-addr-core/#namespaces
  WS_TRUST    http://docs.oasis-open.org/ws-sx/ws-trust/v1.4/ws-trust.html#_Toc325658925
  WS_SEC      http://docs.oasis-open.org/wss-m/wss/v1.1.1/os/wss-SOAPMessageSecurity-v1.1.1-os.html#_Toc307407921
  WS_SEC2     http://docs.oasis-open.org/wss-m/wss/v1.1.1/os/wss-SOAPMessageSecurity-v1.1.1-os.html#_Toc307407949
  XENC        https://www.w3.org/TR/xmlenc-core1/
  RM_LOGIN    https://developers.realme.govt.nz/how-realme-works/
  RM_ASSERT   https://developers.realme.govt.nz/how-realme-works/
  RM_ICMS     RealMe iCMS docs

=over 4

=item ds => http://www.w3.org/2000/09/xmldsig#

XML Digital Signatures namespace URI.  Source: [DSIG_CORE].

=item c14n => http://www.w3.org/TR/2001/REC-xml-c14n-20010315

Canonical XML 1.0 (omit comments) transform.  Source: [DSIG_ALG].

=item c14n_wc => http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments

Canonical XML 1.0 (with comments) transform.  Source: [DSIG_ALG].

=item c14n11 => http://www.w3.org/2006/12/xml-c14n11

Canonical XML 1.1 (omit comments) transform.  Source: [DSIG_ALG].

=item c14n11_wc => http://www.w3.org/2006/12/xml-c14n11#WithComments

Canonical XML 1.1 (with comments) transform.  Source: [DSIG_ALG].

=item ec14n => http://www.w3.org/2001/10/xml-exc-c14n#

Exclusive XML Canonicalization 1.0 (omit comments) transform.  Source: [DSIG_ALG].

=item ec14n_wc => http://www.w3.org/2001/10/xml-exc-c14n#WithComments

Exclusive XML Canonicalization 1.0 (with comments) transform.  Source: [DSIG_ALG].

=item xenc => http://www.w3.org/2001/04/xmlenc#

XML Encryption Syntax and Processing.  Source: [XENC].

=item xenc_type_element => http://www.w3.org/2001/04/xmlenc#Element

URI indicating that the encrypted data represents an element.  Source: [XENC].

=item xenc_rsa15 => http://www.w3.org/2001/04/xmlenc#rsa-1_5

URI for XML Encryption block encryption algorithm "RSAES-PKCS1-v1_5".  Source:
[XENC].

=item xenc_aes128cbc => http://www.w3.org/2001/04/xmlenc#aes128-cbc

URI for XML Encryption block encryption algorithm "AES128-CBC".  Source: [XENC].

=item xenc_aes256cbc => http://www.w3.org/2001/04/xmlenc#aes256-cbc

URI for XML Encryption block encryption algorithm "AES256-CBC".  Source: [XENC].

=item xenc_rsa_oaep_mgf1p => http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p

URI for XML Encryption key transport encryption algorithm "RSA OAEP MGF1P".
Source: [XENC].

=item rsa_1_5 => http://www.w3.org/2001/04/xmlenc#rsa-1_5

URI for XML Encryption key transport encryption algorithm "RSA Version 1.5".
Source: [XENC].

=item sha1 => http://www.w3.org/2000/09/xmldsig#sha1

SHA1 digest transform.  Source: [DSIG_ALG].

=item sha256 => http://www.w3.org/2001/04/xmlenc#sha256

SHA256 digest transform.  Source: [DSIG_ALG].

=item env_sig => http://www.w3.org/2000/09/xmldsig#enveloped-signature

Enveloped Signature transform.  Source: [DSIG_ALG].

=item rsa_sha1 => http://www.w3.org/2000/09/xmldsig#rsa-sha1

RSA with SHA1 digital signature transform.  Source: [DSIG_ALG].

=item rsa_sha256 => http://www.w3.org/2001/04/xmldsig-more#rsa-sha256

RSA with SHA256 digital signature transform.  Source: [DSIG_ALG].

=item soap11 => http://schemas.xmlsoap.org/soap/envelope/

Namespace URI for SOAP version 1.1 elements.  Source: [SOAP11].

=item soap12 => http://www.w3.org/2003/05/soap-envelope

Namespace URI for SOAP version 1.2 elements.  Source: [SOAP12].

=item wsdl => http://schemas.xmlsoap.org/wsdl/

Namespace URI for WSDL elements.  Source: [WSDL].

=item wsdl_soap => http://schemas.xmlsoap.org/wsdl/soap12/

Namespace URI for WSDL binding for SOAP version 1.2 elements.  Source: [WSDL_SOAP].

=item wsa => http://www.w3.org/2005/08/addressing

Namespace URI for Web Services Addressing elements.  Source [WS_ADDR].

=item wsam => http://www.w3.org/2007/05/addressing/metadata

Namespace URI for Web Services Addressing metadata elements.  Source [WS_ADDR].

=item wsa_anon => http://www.w3.org/2005/08/addressing/anonymous

URI token to select anonymous addressing.  Source [WS_ADDR].

=item wsse => http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd

Namespace URI for Web Services Security extension elements.  Source [WS_SEC].

=item wss_b64 => http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary

Encoding type used for Web Services Security binary security tokens.  Source [WS_SEC2].

=item wss_saml2 => http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV2.0

Identifier type used for Web Services Security SAML2 token type references.  Source [WS_SEC2].

=item wss_sha1 => http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#ThumbprintSHA1

Identifier type used for Web Services Security key identifier thumbprint references.  Source [WS_SEC2].

=item wst => http://docs.oasis-open.org/ws-sx/ws-trust/200512

Namespace URI for WS-Trust elements.  Source [WS_TRUST].

=item wst_validate => http://docs.oasis-open.org/ws-sx/ws-trust/200512/Validate

Identifier type used for WS-Trust request type references.  Source [WS_TRUST].

=item wsu => http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd

Namespace URI for Web Services Security elements.  Source [WS_SEC].

=item saml => urn:oasis:names:tc:SAML:2.0:assertion

Namespace used for SAML 2.0 assertion elements.  Source [SAML2].

=item samlmd => urn:oasis:names:tc:SAML:2.0:metadata

Namespace used for SAML 2.0 metadata elements.  Source [SAML2].

=item samlp => urn:oasis:names:tc:SAML:2.0:protocol

Namespace used for SAML 2.0 protocol elements.  Source [SAML2].

=item saml_b_soap => urn:oasis:names:tc:SAML:2.0:bindings:SOAP

Identifier type used for SAML 2.0 binding type references.  Source [SAML2].

=item saml_binding_artifact => urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact

Identifier type used for SAML 2.0 HTTP-Artifact binding.  Source [SAML2].

=item saml_binding_redirect => urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect

Identifier type used for SAML 2.0 HTTP-Redirect binding.  Source [SAML2].

=item saml_binding_post => urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST

Identifier type used for SAML 2.0 HTTP-POST binding.  Source [SAML2].

=item saml_success => urn:oasis:names:tc:SAML:2.0:status:Success

Identifier type used for SAML 2.0 response success status references.  Source
[SAML2].

=item saml_auth_fail => urn:oasis:names:tc:SAML:2.0:status:AuthnFailed

Identifier type used for SAML 2.0 response failure status references.  Source
[SAML2].

=item saml_unkpncpl => urn:oasis:names:tc:SAML:2.0:status:UnknownPrincipal

Identifier type used for SAML 2.0 response 'unknown principal' status
references.  Source [SAML2].

=item saml_nameid_format_persistent => urn:oasis:names:tc:SAML:2.0:nameid-format:persistent

Identifier type used for SAML 2.0 NameID subject format, unique identifier is retained.
Source [SAML2].

=item saml_nameid_format_transient => urn:oasis:names:tc:SAML:2.0:nameid-format:transient

Identifier type used for SAML 2.0 NameID subject format, unique identifier for each flow.
Source [SAML2].

=item rm_timeout => urn:nzl:govt:ict:stds:authn:deployment:RealMe:SAML:2.0:status:Timeout

Identifier type used by RealMe for SAML 2.0 response timeout status references.
Source [RM_LOGIN].

=item gls_timeout => urn:nzl:govt:ict:stds:authn:deployment:GLS:SAML:2.0:status:Timeout

Identifier type used by GLS for SAML 2.0 response timeout status references.
Source [RM_LOGIN].

=item xpil => urn:oasis:names:tc:ciq:xpil:3

Namespace used for party (person) elements in RealMe identity assertions.
Source [RM_ASSERT].

=item xal => urn:oasis:names:tc:ciq:xal:3

Namespace used for locality elements in RealMe identity assertions.
Source [RM_ASSERT].

=item xnl => urn:oasis:names:tc:ciq:xnl:3

Namespace used for person name elements in RealMe identity assertions.
Source [RM_ASSERT].

=item ct => urn:oasis:names:tc:ciq:ct:3

Namespace used for common types used with elements in RealMe identity
assertions.  Source [RM_ASSERT].

=item icms => urn:nzl:govt:ict:stds:authn:deployment:igovt:gls:iCMS:1_0

Namespace used for iCMS AllowCreateFLT elements.  Source [RM_ICMS]

=back
