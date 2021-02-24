package Authen::NZRealMe::ServiceProvider;
$Authen::NZRealMe::ServiceProvider::VERSION = '1.22'; # TRIAL
use strict;
use warnings;
use autodie;

require XML::LibXML;
require XML::LibXML::XPathContext;
require XML::Generator;
require Crypt::OpenSSL::X509;
require HTTP::Response;

use URI::Escape  qw(uri_escape uri_unescape);
use POSIX        qw(strftime);
use Date::Parse  qw();
use File::Spec   qw();
use JSON::XS     qw();
use MIME::Base64 qw();

use Authen::NZRealMe::CommonURIs qw(URI NS_PAIR);
use Authen::NZRealMe::Asserts    qw(assert_is_base64);

use WWW::Curl::Easy qw(
    CURLOPT_URL
    CURLOPT_POST
    CURLOPT_HTTPHEADER
    CURLOPT_POSTFIELDS
    CURLOPT_SSLCERT
    CURLOPT_SSLKEY
    CURLOPT_SSL_VERIFYPEER
    CURLOPT_WRITEDATA
    CURLOPT_WRITEHEADER
    CURLOPT_CAPATH
);

use constant DATETIME_BEFORE => -1;
use constant DATETIME_EQUAL  => 0;
use constant DATETIME_AFTER  => 1;


my %metadata_cache;
my $signing_cert_filename = 'sp-sign-crt.pem';
my $signing_key_filename  = 'sp-sign-key.pem';
my $ssl_cert_filename     = 'sp-ssl-crt.pem';
my $ssl_key_filename      = 'sp-ssl-key.pem';
my $icms_wsdl_filename    = 'metadata-icms.wsdl';
my $ca_cert_directory     = 'ca-certs';

my $ns_samlmd     = [ NS_PAIR('samlmd') ];
my $ns_ds         = [ NS_PAIR('ds') ];
my $ns_saml       = [ NS_PAIR('saml') ];
my $ns_samlp      = [ NS_PAIR('samlp') ];
my $ns_soap11     = [ NS_PAIR('soap11') ];
my $ns_xenc       = [ NS_PAIR('xenc') ];
my $ns_xpil       = [ NS_PAIR('xpil') ];
my $ns_xal        = [ NS_PAIR('xal') ];
my $ns_xnl        = [ NS_PAIR('xnl') ];
my $ns_ct         = [ NS_PAIR('ct') ];
my $ns_soap12     = [ NS_PAIR('soap12') ];
my $ns_wsse       = [ NS_PAIR('wsse') ];
my $ns_wsu        = [ NS_PAIR('wsu') ];
my $ns_wst        = [ NS_PAIR('wst') ];
my $ns_wsa        = [ NS_PAIR('wsa') ];
my $ns_ec14n      = [ NS_PAIR('ec14n') ];
my $ns_icms       = [ NS_PAIR('icms') ];
my $ns_wsdl       = [ NS_PAIR('wsdl') ];
my $ns_wsdl_soap  = [ NS_PAIR('wsdl_soap') ];
my $ns_wsam       = [ NS_PAIR('wsam') ];

my @ivs_namespaces  = ( $ns_xpil, $ns_xnl, $ns_ct, $ns_xal );
my @avs_namespaces  = ( $ns_xpil, $ns_xal );
my @icms_namespaces = ( $ns_ds, $ns_saml, $ns_icms, $ns_wsse, $ns_wsu, $ns_wst, $ns_soap12  );
my @wsdl_namespaces = ( $ns_wsdl, $ns_wsdl_soap, $ns_wsam );

my %urn_attr_name = (
    fit         => 'urn:nzl:govt:ict:stds:authn:attribute:igovt:IVS:FIT',
    ivsx        => 'urn:nzl:govt:ict:stds:authn:safeb64:attribute:igovt:IVS:Assertion:Identity',
    ivs         => 'urn:nzl:govt:ict:stds:authn:safeb64:attribute:igovt:IVS:Assertion:JSON:Identity',
    avs         => 'urn:nzl:govt:ict:stds:authn:safeb64:attribute:NZPost:AVS:Assertion:Address',
    icms_token  => 'urn:nzl:govt:ict:stds:authn:safeb64:attribute:opaque_token',
);

my $soap_action = 'http://www.oasis-open.org/committees/security';


sub new {
    my $class = shift;

    my $self = bless {
        type                     => 'login',
        skip_signature_check     => 0,
        @_
    }, $class;

    my $conf_dir = $self->{conf_dir} or die "conf_dir not set\n";
    $self->{conf_dir} = File::Spec->rel2abs($conf_dir);

    $self->_check_type();

    $self->_load_metadata();

    return $self;
}


sub new_defaults {
    my $class = shift;

    my $self = bless {
        @_,
    }, $class;

    return $self;
}


sub conf_dir               { shift->{conf_dir};               }
sub type                   { shift->{type};                   }
sub entity_id              { shift->{entity_id};              }
sub acs_list               { @{ shift->{acs_list} // [] };    }
sub organization_name      { shift->{organization_name};      }
sub organization_url       { shift->{organization_url};       }
sub contact_company        { shift->{contact_company};        }
sub _x                     { shift->{x};                      }
sub nameid_format          { shift->{nameid_format};          }
sub signing_cert_pathname  { shift->{conf_dir} . '/' . $signing_cert_filename; }
sub signing_key_pathname   { shift->{conf_dir} . '/' . $signing_key_filename;  }
sub ssl_cert_pathname      { shift->{conf_dir} . '/' . $ssl_cert_filename;     }
sub ssl_key_pathname       { shift->{conf_dir} . '/' . $ssl_key_filename;      }
sub ca_cert_pathname       { shift->{conf_dir} . '/' . $ca_cert_directory;     }

sub skip_signature_check     { shift->{skip_signature_check};     }

sub idp {
    my $self = shift;

    return $self->{idp} if $self->{idp};

    $self->{idp} = Authen::NZRealMe->class_for('identity_provider')->new(
        conf_dir  => $self->conf_dir(),
        type      => $self->type,
    );
}


sub token_generator {
    return shift->{token_generator} ||=
        Authen::NZRealMe->class_for('token_generator')->new();
}


sub generate_saml_id {
    return shift->token_generator->saml_id(@_);
}


sub generate_certs {
    my($class, $conf_dir, %args) = @_;

    Authen::NZRealMe->class_for('sp_cert_factory')->generate_certs(
        $conf_dir, %args
    );
}


sub build_meta {
    my($class, %opt) = @_;

    Authen::NZRealMe->class_for('sp_builder')->build($class, %opt);
}


sub _read_file {
    my($self, $filename) = @_;

    local($/) = undef; # slurp mode
    open my $fh, '<', $filename or die "open($filename): $!";
    my $data = <$fh>;
    return $data;
}


sub _write_file {
    my($self, $filename, $data) = @_;

    open my $fh, '>', $filename or die "open(>$filename): $!";
    print $fh $data;

    close($fh) or die "close(>$filename): $!";
}


sub make_bundle {
    my($class, %opt) = @_;

    my $conf_dir = $opt{conf_dir};
    foreach my $type (qw(login assertion)) {
        my $conf_path = $class->_metadata_pathname($conf_dir, $type);
        if(-r $conf_path) {
          my $sp = $class->new(
              conf_dir  => $conf_dir,
              type      => $type,
          );
          my $zip = Authen::NZRealMe->class_for('sp_builder')->make_bundle($sp);
          print "Created metadata bundle for '$type' IDP at:\n$zip\n\n";
        }
    }
}


sub _check_type {
    my $self = shift;

    my $type = $self->type;
    if($type ne 'login' and $type ne 'assertion') {
        warn qq{Unknown service type.\n} .
             qq{  Got: "$type"\n} .
             qq{  Expected: "login" or "assertion"\n};
    }
}


sub _load_metadata {
    my $self = shift;

    my $cache_key = $self->conf_dir . '-' . $self->type;
    my $params = $metadata_cache{$cache_key} || $self->_read_metadata_from_file;

    $self->{$_} = $params->{$_} foreach keys %$params;
}


sub _read_metadata_from_file {
    my $self = shift;

    my $metadata_file = $self->_metadata_pathname;
    die "File does not exist: $metadata_file\n" unless -e $metadata_file;

    my $xc = $self->_xpath_context_dom($metadata_file, $ns_samlmd, $ns_ds);

    my %params;
    foreach (
        [ id                     => q{/samlmd:EntityDescriptor/@ID} ],
        [ entity_id              => q{/samlmd:EntityDescriptor/@entityID} ],
        [ organization_name      => q{/samlmd:EntityDescriptor/samlmd:Organization/samlmd:OrganizationName} ],
        [ organization_url       => q{/samlmd:EntityDescriptor/samlmd:Organization/samlmd:OrganizationURL} ],
        [ contact_company        => q{/samlmd:EntityDescriptor/samlmd:ContactPerson/samlmd:Company} ],
        [ nameid_format          => q{/samlmd:EntityDescriptor/samlmd:SPSSODescriptor/samlmd:NameIDFormat} ],
    ) {
        $params{$_->[0]} = $xc->findvalue($_->[1]);
    }

    if (! $params{nameid_format}) {
        # Old metadata files do not contain NameIDFormat, set the default:
        $params{nameid_format} = {
            login     => URI('saml_nameid_format_persistent'),
            assertion => URI('saml_nameid_format_transient'),
        }->{$self->type};
    }

    my @acs_list =
        map {
            $self->_parse_acs($_);
        } $xc->findnodes(
            q{/samlmd:EntityDescriptor/samlmd:SPSSODescriptor/samlmd:AssertionConsumerService}
        )
            or die "No AssertionConsumerService elements defined";
    $params{acs_list} = \@acs_list;

    my $cache_key = $self->conf_dir . '-' . $self->type;
    $metadata_cache{$cache_key} = \%params;

    my $icms_pathname = $self->_icms_wsdl_pathname;

    if ( $self->{type} eq 'assertion' && -e $icms_pathname ){
        $self->_parse_icms_wsdl;
    }

    return \%params;
}

sub _parse_acs {
    my ($self, $el) = @_;

    my $acs = {};

    my $index = $el->{index};
    if(defined($index)) {
        die qq{Invalid AssertionConsumerService index="$index"}
            unless $index =~ /^[0-9]+$/;
        $acs->{index} = $index;
    }
    else {
        die "AssertionConsumerService is missing 'index'"
    }

    if(my $binding = $el->{Binding}) {
        if(
            $binding ne URI('saml_binding_artifact')
            and $binding ne URI('saml_binding_post')
        ) {
            die qq{Invalid AssertionConsumerService binding="$binding"}
        }
        $acs->{binding} = $binding;
    }
    else {
        die "AssertionConsumerService is missing 'Binding'"
    }

    $acs->{location} = $el->{Location}
        or die "AssertionConsumerService is missing 'Location'";

    if(my $default = $el->{isDefault}) {
        if($default eq 'true') {
            $acs->{is_default} = 1;
        }
    }

    return $acs;
}


sub _parse_icms_wsdl {
    my ($self) = @_;

    my $xc = $self->_xpath_context_dom($self->_icms_wsdl_pathname, @wsdl_namespaces);
    my $result = {};
    foreach my $type ( 'Issue', 'Validate' ){
        $result->{$type} = {
            url       => $xc->findvalue('/wsdl:definitions/wsdl:service[@name="igovtContextMappingService"]/wsdl:port[@name="'.$type.'"]/wsdl_soap:address/@location'),
            operation => $xc->findvalue('/wsdl:definitions/wsdl:portType[@name="'.$type.'"]/wsdl:operation/wsdl:input/@wsam:Action'),
        };
    }

    my $cache_key = $self->conf_dir . '-' . $self->type . '-icms';
    $metadata_cache{$cache_key} = $result;
}

sub _metadata_pathname {
    my $self     = shift;
    my $conf_dir = shift;
    my $type     = shift;

    $type //= $self->type;

    $conf_dir ||= $self->conf_dir or die "conf_dir not set";

    return $conf_dir . '/metadata-' . $type . '-sp.xml';
}

sub _icms_wsdl_pathname {
    my $self     = shift;
    my $conf_dir = shift;
    my $type     = shift;

    $type //= $self->type;

    $conf_dir ||= $self->conf_dir or die "conf_dir not set";

    return $conf_dir . '/' . $icms_wsdl_filename;
}

sub _icms_method_data {
    my $self = shift;
    my $method = shift;

    my $cache_key = $self->conf_dir . '-' . $self->type . '-icms';

    my $methods = $metadata_cache{$cache_key} || $self->_parse_icms_wsdl;

    return $methods->{$method};
}

sub _xpath_context_dom {
    my($self, $source, @namespaces) = @_;

    my $parser = XML::LibXML->new();
    my $doc    = $source =~ /<.*>/
                 ? $parser->parse_string( $source )
                 : $parser->parse_file( $source );
    my $xc     = XML::LibXML::XPathContext->new( $doc->documentElement() );

    foreach my $ns ( @namespaces ) {
        $xc->registerNs( @$ns );
    }

    return $xc;
}


sub select_acs_by_index {
    my $self  = shift;
    my $index = shift // 'default';

    my @match;
    foreach my $acs ( $self->acs_list ) {
        if ($index eq 'default') {
            push @match, $acs if $acs->{is_default};
        }
        elsif ($acs->{index} eq $index) {
            push @match, $acs;
        }
    }
    my $str = $index eq 'default' ? qq{isDefault="true"} : qq{index="$index"};
    die qq{Unable to find <AssertionConsumerService> with $str}
        unless @match;

    my $count = @match;
    die qq{$count <AssertionConsumerService> elements have $str}
        unless $count == 1;
    return $match[0];
}


sub new_request {
    my $self = shift;

    my %opt = @_;
    my $acs = $self->select_acs_by_index($opt{acs_index});
    $opt{acs_index} = $acs->{index};
    my $req = Authen::NZRealMe->class_for('authen_request')->new($self, %opt);
    return $req;
}


sub _signing_cert_pem_data {
    my $self = shift;

    return $self->{signing_cert_pem_data} if $self->{signing_cert_pem_data};

    my $path = $self->signing_cert_pathname
        or die "No path to signing certificate file";

    my $cert_data = $self->_read_file($path);

    $cert_data =~ s{\r\n}{\n}g;
    $cert_data =~ s{\A.*?^-+BEGIN CERTIFICATE-+\n}{}sm;
    $cert_data =~ s{^-+END CERTIFICATE-+\n?.*\z}{}sm;

    return $cert_data;
}


sub metadata_xml {
    my $self = shift;

    return $self->_to_xml_string();
}


sub _sign_xml {
    my $self      = shift;
    my $algorithm = shift;
    my %options;
    $options{algorithm} = 'algorithm_' . $algorithm if $algorithm;
    my $signer = $self->_signer(%options);
    return $signer->sign(@_);
}


sub sign_query_string {
    my($self, $qs) = @_;

    $qs .= '&SigAlg=http%3A%2F%2Fwww.w3.org%2F2000%2F09%2Fxmldsig%23rsa-sha1';

    my $signer = $self->_signer(signature_algorithm => 'rsa_sha1');

    my $sig = $signer->create_detached_signature($qs, '');

    return $qs . '&Signature=' . uri_escape( $sig );
}


sub _signer {
    my($self, %options) = @_;

    my $key_path = $self->signing_key_pathname
        or die "No path to signing key file";

    return Authen::NZRealMe->class_for('xml_signer')->new(
        pub_cert_file => $self->signing_cert_pathname,
        key_file      => $key_path,
        %options,
    );
}


sub _encrypter {
    my($self, %options) = @_;

    my $key_path = $self->signing_key_pathname
        or die "No path to signing key file";

    return Authen::NZRealMe->class_for('xml_encrypter')->new(
        pub_cert_file => $self->signing_cert_pathname,
        key_file      => $key_path,
        %options,
    );
}


sub resolve_posted_assertion {
    my($self, %args) = @_;

    my $post_param = $args{saml_response}
        or die "No saml_response value was supplied to resolve_posted_assertion()";

    $post_param =~ s/\s+//g;

    assert_is_base64($post_param, '$args{saml_response}');
    my $xml = MIME::Base64::decode_base64($post_param);
    $xml = $self->decrypt_assertion($xml);

    my $response = $self->_verify_assertion($xml, %args);

    if($response->is_success) {
        if($self->type eq 'assertion' and $self->nameid_format ne URI('saml_nameid_format_persistent')) {
             $self->_resolve_flt($response, %args) if $args{resolve_flt};
        }
    }

    return $response;
}


sub decrypt_assertion {
    my($self, $xml) = @_;

    $self->_reject_unencrypted_assertions($xml);

    # Replace any <EncryptedData> elements with their unencrypted contents

    my $encrypter = $self->_encrypter();
    return $encrypter->decrypt_encrypted_data_elements($xml);
}


sub _reject_unencrypted_assertions {
    my($self, $xml) = @_;

    # This is a security mitigation - there should not be any <Assertion>
    # elements before decryption.  If there are, it is most likely an attempt
    # to spoof a SAML response.

    my $xc = $self->_xpath_context_dom($xml, $ns_samlp, $ns_saml, $ns_ds);

    my @assertions = $xc->findnodes(q{//saml:Assertion});
    die "SamlResponse contained an unencrypted <Assertion> element"
        if @assertions;
}


sub resolve_artifact {
    my($self, %args) = @_;

    my $artifact = $args{artifact}
        or die "Need artifact from SAMLart URL parameter\n";

    if($artifact =~ m{\bSAMLart=(.*?)(?:&|$)}) {
        $artifact = uri_unescape($1);
    }

    my $request   = Authen::NZRealMe->class_for('resolution_request')->new($self, $artifact);
    my $url       = $request->destination_url;
    my $soap_body = $request->soap_request;

    my $headers = [
        'User-Agent: Authen-NZRealMe/' . ($Authen::NZRealMe::VERSION // '0.0'),
        'Content-Type: text/xml',
        'SOAPAction: http://www.oasis-open.org/committees/security',
        'Content-Length: ' . length($soap_body),
    ];


    my $content;
    if($args{_from_file_}) {
        $content =  $self->_read_file($args{_from_file_});
    }
    else {
        my $http_resp = $self->_https_post($url, $headers, $soap_body);

        die "Artifact resolution failed:\n" . $http_resp->as_string
            unless $http_resp->is_success;

        $content = $http_resp->content;

        if($args{_to_file_}) {
            $self->_write_file($args{_to_file_}, $content);
        }
    }

    my $response = $self->_verify_assertion($content, %args);

    if($response->is_success) {
        if($self->type eq 'assertion'  and  $args{resolve_flt}) {
             $self->_resolve_flt($response, %args);
        }
    }

    return $response;
}

sub _resolve_flt {
    my($self, $idp_response, %args) = @_;

    my $opaque_token = $idp_response->_icms_token();

    my $request   = Authen::NZRealMe->class_for('icms_resolution_request')->new($self, $opaque_token);

    my $method = $self->_icms_method_data('Validate');

    my $request_data = $request->request_data;

    my $headers = [
        'User-Agent: Authen-NZRealMe/' . ($Authen::NZRealMe::VERSION // '0.0'),
        'Content-Type: text/xml',
        'SOAPAction: ' . $method->{operation},
        'Content-Length: ' . length($request_data),
    ];

    my $response = $self->_https_post($request->destination_url, $headers, $request_data);

    my $content = $response->content;

    if ( !$response->is_success ){
        my $xc = $self->_xpath_context_dom($content, $ns_soap12, $ns_icms);
        # Grab and output the SOAP error explanation, if present.
        if(my($error) = $xc->findnodes('//soap12:Fault')) {
            my $code       = $xc->findvalue('./soap12:Code/soap12:Value',       $error) || 'Unknown';
            my $string     = $xc->findvalue('./soap12:Reason/soap12:Text',      $error) || 'Unknown';
            die "ICMS error:\n  Fault Code: $code\n  Fault String: $string";
        }
        die "Error resolving FLT\n  Response code:$response->code\n  Message:$response->message";
    }

    if($args{_to_file_}) {
        # Add a -icms suffix so we don't overwrite the SAML response file
        my $icms_file = $args{_to_file_};
        $icms_file =~ s{([.]\w+|)$}{-icms$1};
        $self->_write_file($icms_file, $content);
    }

    my $flt = $self->_extract_flt($content);
    $idp_response->set_flt($flt);
}

sub _extract_flt {
    my($self, $xml, %args) = @_;

    # We have a SAML assertion in the SOAP body, make sure it's signed.
    # The assertion comes from the login IDP so use that cert to check.
    my $idp = $self->idp;
    my $verifier;
    eval {
        $verifier = Authen::NZRealMe->class_for('xml_signer')->new(
            pub_cert_text => $idp->login_cert_pem_data(),
        );
        $verifier->verify($xml, '//soap12:Body//ds:Signature', NS_PAIR('soap12'), NS_PAIR('ds'));
    };
    if($@) {
        die "Failed to verify signature on assertion from IdP:\n  $@\n$xml";
    }
    my $xc = $self->_xpath_context_dom($xml, @icms_namespaces);
    my($flt) = $verifier->find_verified_element(
        $xc,
        q{/soap12:Envelope/soap12:Body/wst:RequestSecurityTokenResponse/wst:RequestedSecurityToken/saml:Assertion/saml:Subject/saml:NameID}
    ) or die "Unable to find FLT in iCMS response: $xml\n";
    return $flt->to_literal;
}

sub _https_post {
    my($self, $url, $headers, $body) = @_;

    my $curl = new WWW::Curl::Easy;

    $curl->setopt(CURLOPT_URL,        $url);
    $curl->setopt(CURLOPT_POST,       1);
    $curl->setopt(CURLOPT_HTTPHEADER, $headers);
    $curl->setopt(CURLOPT_POSTFIELDS, $body);
    $curl->setopt(CURLOPT_SSLCERT,    $self->ssl_cert_pathname);
    $curl->setopt(CURLOPT_SSLKEY,     $self->ssl_key_pathname);

    if ($self->{disable_ssl_verify}){
        $curl->setopt(CURLOPT_SSL_VERIFYPEER, 0);
    }
    else {
        $curl->setopt(CURLOPT_SSL_VERIFYPEER, 1);
        $curl->setopt(CURLOPT_CAPATH, $self->ca_cert_pathname);
    }

    my($resp_body, $resp_head);
    open (my $body_fh, ">", \$resp_body);
    $curl->setopt(CURLOPT_WRITEDATA, $body_fh);
    open (my $head_fh, ">", \$resp_head);
    $curl->setopt(CURLOPT_WRITEHEADER, $head_fh);

    my $resp;
    my $retcode = $curl->perform;
    if($retcode == 0) {
        $resp_head =~ s/\A(?:HTTP\/1\.1 100 Continue)?[\r\n]*//; # Remove any '100' responses and/or leading newlines
        my($status, @head_lines) = split(/\r?\n/, $resp_head);
        my($protocol, $code, $message) = split /\s+/, $status, 3;
        my $headers = [ map { split /:\s+/, $_, 2 } @head_lines];
        $resp = HTTP::Response->new($code, $message, $headers, $resp_body);
    }
    else {
        $resp = HTTP::Response->new(
            500, 'Error', [], $curl->strerror($retcode)." ($retcode)\n"
        );
    }

    return $resp;
}


sub _verify_assertion {
    my($self, $xml, %args) = @_;

    my $request_id = $args{request_id}
        or die "Can't resolve to assertion without original request ID\n";

    my $binding = $args{saml_response} ? 'http_post' : 'http_artifact';

    my @ns_prefs = ($ns_soap11, $ns_saml, $ns_samlp, $ns_xenc);
    my $xc = $self->_xpath_context_dom($xml, @ns_prefs);

    my $encrypted = $binding eq 'http_post';
    if($xc->findnodes('//saml:EncryptedAssertion/xenc:EncryptedData')) {
        $encrypted = 1;
        $xml = $self->decrypt_assertion($xml);
        $xc = $self->_xpath_context_dom($xml, @ns_prefs);
    }

    # Check for SOAP error

    if($binding eq 'http_artifact') {
        if(my($error) = $xc->findnodes('//soap11:Fault')) {
            my $code   = $xc->findvalue('./faultcode',   $error) || 'Unknown';
            my $string = $xc->findvalue('./faultstring', $error) || 'Unknown';
            die "SOAP protocol error:\n  Fault Code: $code\n  Fault String: $string\n";
        }
    }


    # Extract the SAML result code

    my $response = $self->_build_resolution_response($xc, $xml, $binding);
    return $response if $response->is_error;


    # Make sure the response payload is signed

    my $idp  = $self->idp;
    my $verifier = $self->_verify_assertion_signature($idp, $xml);


    # Look for the SAML Response Subject payload in a signed section

    my $transport_prefix =  $binding eq 'http_post'
        ? '/samlp:Response'
        : '/soap11:Envelope/soap11:Body/samlp:ArtifactResponse/samlp:Response';

    my $encrypted_prefix = $encrypted
        ? '/saml:EncryptedAssertion'
        : '';

    my $subj_xpath = $transport_prefix . $encrypted_prefix
        . '/saml:Assertion/saml:Subject';
    my($subject) = $verifier->find_verified_element($xc, $subj_xpath);
    my $assertion = $subject->parentNode();


    # Confirm that subject is valid for our SP

    $self->_check_subject_confirmation($xc, $subject, $request_id);


    # Check that it was generated by the expected IdP

    my $idp_entity_id = $idp->entity_id;
    my $from_sp = $xc->findvalue('./saml:NameID/@NameQualifier', $subject) || '';
    die "SAML assertion created by '$from_sp', expected '$idp_entity_id'. Assertion follows:\n$xml\n"
        if $from_sp ne $idp_entity_id;


    # Check that it's intended for our SP

    if($self->type eq 'login') {  # Not provided by assertion IdP
        my $sp_entity_id  = $self->entity_id;
        my $for_sp = $xc->findvalue('./saml:NameID/@SPNameQualifier', $subject) || '';
        die "SAML assertion created for '$for_sp', expected '$sp_entity_id'\n$xml\n"
            if $for_sp ne $sp_entity_id;
    }

    # Look for Conditions on the assertion

    $self->_check_conditions($xc, $assertion);  # will die on failure


    # Make sure it's in the expected format

    my $nameid_format = $self->nameid_format();
    my $format = $xc->findvalue('./saml:NameID/@Format', $subject) || '';
    die "Unrecognised NameID format '$format', expected '$nameid_format'\n$xml\n"
        if $format ne $nameid_format;


    # Check the logon strength (if required)

    if($self->type eq 'login') {  # Not needed for assertion IdP
        my $strength = $xc->findvalue(
            q{./saml:AuthnStatement/saml:AuthnContext/saml:AuthnContextClassRef},
            $assertion
        ) || '';
        $response->set_logon_strength($strength);
        if($args{logon_strength}) {
            $strength = Authen::NZRealMe->class_for('logon_strength')->new($strength);
            $strength->assert_match($args{logon_strength}, $args{strength_match});
        }
    }

    # Extract the payload

    if($self->type eq 'login') {
        $self->_extract_login_payload($response, $xc, $subject);
    }
    elsif($self->type eq 'assertion') {
        $self->_extract_assertion_payload($response, $xc, $assertion);
        $self->_extract_assertion_flt($response, $xc, $subject);
    }

    return $response;
}


sub _verify_assertion_signature {
    my($self, $idp, $xml) = @_;

    my $verifier;
    eval {
        $verifier = $idp->verify_signature($xml);
    };
    if($@) {
        my $skip_type = $self->skip_signature_check;
        if($skip_type) {
            if($skip_type < 2) {
                warn "WARNING: Continuing after signature verification failure "
                   . "(skip_signature_check is enabled)\n$@\n";
            }
            $verifier = Authen::NZRealMe->class_for('xml_signer')->new();
            $verifier->ignore_bad_signatures();
        }
        else {
            die $@;   # Re-throw the exception
        }
    }
    return $verifier;
}


sub _build_resolution_response {
    my($self, $xc, $xml, $binding) = @_;

    my $response = Authen::NZRealMe->class_for('resolution_response')->new($xml);
    $response->set_service_type( $self->type );

    my $status_xpath = $binding eq 'http_post'
        ? '/samlp:Response/samlp:Status/samlp:StatusCode'
        : '//samlp:ArtifactResponse/samlp:Response/samlp:Status/samlp:StatusCode';
    my($status_code) = $xc->findnodes($status_xpath)
        or die "Could not find a SAML status code\n$xml\n";

    # Recurse down to find the most specific status code

    while(
        my($child_code) = $xc->findnodes('./samlp:StatusCode', $status_code)
    ) {
        $status_code = $child_code;
    }

    my($urn) = $xc->findvalue('./@Value', $status_code)
        or die "Couldn't find 'Value' attribute for StatusCode\n$xml\n";

    $response->set_status_urn($urn);

    return $response if $response->is_success;

    my $message_xpath = $binding eq 'http_post'
        ? '/samlp:Response/samlp:Status/samlp:StatusMessage'
        : '//samlp:ArtifactResponse/samlp:Response/samlp:Status/samlp:StatusMessage';
    my $message = $xc->findvalue($message_xpath) || '';
    $message =~ s{(\A\s+|\s+\z)}{}g; # Strip off leading and trailing whitespace
    $message =~ s{^\[.*\]\s*}{};     # Strip off [SP EntityID] prefix
    $response->set_status_message($message) if $message;

    return $response
}


sub _check_subject_confirmation {
    my($self, $xc, $subject, $request_id) = @_;

    my $xml = $subject->toString();

    my($conf_data) = $xc->findnodes(
        './saml:SubjectConfirmation/saml:SubjectConfirmationData',
        $subject
    ) or die "SAML assertion does not contain SubjectConfirmationData\n$xml\n";


    # Check that it's a reply to our request

    my $response_to = $xc->findvalue('./@InResponseTo', $conf_data) || '';
    die "SAML response to unexpected request ID\n"
        . "Original:    '$request_id'\n"
        . "Response To: '$response_to'\n$xml\n" if $request_id ne $response_to;

    # Check that it has not expired

    my $now = $self->now_as_iso();

    if(my($end_time) = $xc->findvalue('./@NotOnOrAfter', $conf_data)) {
        if($self->_compare_times($now, $end_time) != DATETIME_BEFORE) {
            die "SAML assertion SubjectConfirmationData expired at '$end_time'\n";
        }
    }

}


sub _check_conditions {
    my($self, $xc, $assertion) = @_;

    my($conditions) = $xc->findnodes('./saml:Conditions', $assertion)
        or return;

    my $xml = $conditions->toString();

    my $now = $self->now_as_iso();

    if(my($start_time) = $xc->findvalue('./@NotBefore', $conditions)) {
        if($self->_compare_times($start_time, $now) != DATETIME_BEFORE) {
            die "SAML assertion not valid until '$start_time'\n";
        }
    }

    if(my($end_time) = $xc->findvalue('./@NotOnOrAfter', $conditions)) {
        if($self->_compare_times($now, $end_time) != DATETIME_BEFORE) {
            die "SAML assertion not valid after '$end_time'\n";
        }
    }

    foreach my $condition ($xc->findnodes('./saml:*', $conditions)) {
        my($name)  = $condition->localname();
        my $method = "_check_condition_$name";
        die "Unimplemented condition: '$name'" unless $self->can($method);
        $self->$method($xc, $condition);
    }

    return;  # no problems were encountered
}


sub _check_condition_AudienceRestriction {
    my($self, $xc, $condition) = @_;

    my $entity_id = $self->entity_id;
    my $audience  = $xc->findvalue('./saml:Audience', $condition)
        or die "Can't find target audience in: " . $condition->toString();

    die "SAML assertion only valid for audience '$audience' (expected '$entity_id')"
        if $audience ne $entity_id;
}


sub _compare_times {
    my($self, $date1, $date2) = @_;

    foreach ($date1, $date2) {
        s/\s+//g;
        die "Invalid timestamp '$_'\n"
            unless /\A\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d(?:[.]\d+)?Z(.*)\z/s;
        die "Non-UTC dates are not supported: '$_'" if $1;
    }

    return $date1 cmp $date2;
}


sub _extract_login_payload {
    my($self, $response, $xc, $subject) = @_;

    # Extract the FLT

    my $flt = $xc->findvalue(q{./saml:NameID}, $subject)
        or die "Can't find NameID element in response:\n" . $response->xml . "\n";

    $flt =~ s{\s+}{}g;

    $response->set_flt($flt);
}

sub _extract_assertion_flt {
    my($self, $response, $xc, $subject) = @_;

    # Extract the FLT

    my $flt = $xc->findvalue(q{./saml:NameID}, $subject)
        or die "Can't find NameID element in response:\n" . $response->xml . "\n";

    $flt =~ s{\s+}{}g;

    if ($flt =~ m{^(?:WLG|AKL|AZU|CHC)}) {
        # Valid FLT strings
        $response->set_flt($flt);
    }
}


sub _extract_assertion_payload {
    my($self, $response, $xc, $assertion) = @_;

    # Extract the asserted attributes

    my $attribute_selector = q{./saml:AttributeStatement/saml:Attribute};

    foreach my $attr ( $xc->findnodes($attribute_selector, $assertion) ) {
        my $name  = $xc->findvalue('./@Name', $attr) or next;
        my $value = $xc->findvalue('./saml:AttributeValue', $attr) || '';
        if($name =~ /:safeb64:/) {
            assert_is_base64($value, $attribute_selector);
            $value = MIME::Base64::decode_base64url($value);
        }
        if($name eq $urn_attr_name{fit}) {
            $response->set_fit($value);
        }
        elsif($name eq $urn_attr_name{ivs}) {
            $self->_extract_ivs_details($response, $value);
        }
        elsif($name eq $urn_attr_name{ivsx}) {
            $self->_extract_ivsx_details($response, $value);
        }
        elsif($name eq $urn_attr_name{avs}) {
            $self->_extract_avs_details($response, $value);
        }
        elsif($name eq $urn_attr_name{icms_token}) {
            $self->_extract_icms_token($response, $value);
        }
    }
}


sub _extract_ivs_details {
    my($self, $response, $data) = @_;

    my $json = JSON::XS::decode_json($data);

    my $dob  = $json->{dateOfBirth} or warn "dateOfBirth field is not in JSON IVS";
    my $name = $json->{name}        or warn "name field is not in JSON IVS";

    $response->set_date_of_birth($dob->{dateOfBirthValue});
    $response->set_surname(   $name->{lastName});
    $response->set_first_name($name->{firstName});
    $response->set_mid_names( $name->{middleName});

    $response->set_gender($json->{gender}) if $json->{gender};
}

sub _extract_ivsx_details {
    my($self, $response, $xml) = @_;

    my $xc = $self->_xpath_context_dom($xml, @ivs_namespaces);

    my($dd, $mm, $yyyy);

    $self->_xc_extract($xc,
        q{/xpil:Party/xpil:BirthInfo/xpil:BirthInfoElement[@xpil:Type='BirthDay']},
        sub { $dd = shift; }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xpil:BirthInfo/xpil:BirthInfoElement[@xpil:Type='BirthMonth']},
        sub { $mm = shift; }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xpil:BirthInfo/xpil:BirthInfoElement[@xpil:Type='BirthYear']},
        sub { $yyyy = shift; }
    );

    if($dd && $mm && $yyyy) {
        $response->set_date_of_birth("$yyyy-$mm-$dd");
    }

    $self->_xc_extract($xc,
        q{/xpil:Party/xpil:BirthInfo/xpil:BirthPlaceDetails/xal:Locality/xal:NameElement},
        sub { $response->set_place_of_birth(shift); }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xpil:BirthInfo/xpil:BirthPlaceDetails/xal:Country/xal:NameElement},
        sub { $response->set_country_of_birth(shift); }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xpil:PartyName/xnl:PersonName/xnl:NameElement[@xnl:ElementType='LastName']},
        sub { $response->set_surname(shift); }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xpil:PartyName/xnl:PersonName/xnl:NameElement[@xnl:ElementType='FirstName']},
        sub { $response->set_first_name(shift); }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xpil:PartyName/xnl:PersonName/xnl:NameElement[@xnl:ElementType='MiddleName']},
        sub { $response->set_mid_names(shift); }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xpil:PersonInfo/@xpil:Gender},
        sub { $response->set_gender(shift); }
    );
}


sub _extract_avs_details {
    my($self, $response, $xml) = @_;

    my $xc = $self->_xpath_context_dom($xml, @avs_namespaces);

    $self->_xc_extract($xc,
        q{/xpil:Party/xal:Addresses/xal:Address[1]/xal:Premises/xal:NameElement[@NameType="NZUnit"]},
        sub { $response->set_address_unit(shift); }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xal:Addresses/xal:Address[1]/xal:Thoroughfare/xal:NameElement[@NameType="NZNumberStreet"]},
        sub { $response->set_address_street(shift); }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xal:Addresses/xal:Address[1]/xal:Locality/xal:NameElement[@NameType="NZSuburb"]},
        sub { $response->set_address_suburb(shift); }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xal:Addresses/xal:Address[1]/xal:Locality/xal:NameElement[@NameType="NZTownCity"]},
        sub { $response->set_address_town_city(shift); }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xal:Addresses/xal:Address[1]/xal:PostCode/xal:Identifier[@Type="NZPostCode"]},
        sub { $response->set_address_postcode(shift); }
    );

    $self->_xc_extract($xc,
        q{/xpil:Party/xal:Addresses/xal:Address[1]/xal:RuralDelivery/xal:Identifier[@Type="NZRuralDelivery"]},
        sub { $response->set_address_rural_delivery(shift); }
    );

}


sub _extract_icms_token {
    my($self, $response, $xml) = @_;

    $response->_set_icms_token($xml);
}


sub _xc_extract {
    my($self, $xc, $selector, $handler) = @_;

    my @match = $xc->findnodes($selector);
    if(@match > 1) {
        die "Error: found multiple matches (" . @match . ") for selector:\n  '$selector'";
    }
    elsif(@match == 1) {
        $handler->( $match[0]->to_literal, $match[0] );
    }
}


sub _to_xml_string {
    my $self = shift;

    # Use a default namespace, so no prefix required on individual elements
    my $x = XML::Generator->new(':pretty',
        namespace => [ '#default' => URI('samlmd') ],
    );
    $self->{x} = $x;

    my $xml = $x->EntityDescriptor(
        {
            entityID    => $self->entity_id,
            validUntil  => $self->_valid_until_datetime,
        },
        $self->_gen_sp_sso_descriptor(),
        $self->_gen_organization(),
        $self->_gen_contact(),
    );

    # apply fixups
    $xml =~ s{ _xml_lang_attribute="}{ xml:lang="}sg;
    $xml =~ s{\s*<NoIndentContent.*?>(.*?)</NoIndentContent.*?>\s*}
             {_unindent_element_content($1)}sge;

    return $xml;
}


sub _unindent_element_content {
    my($content) = @_;

    $content =~ s{^\s+}{}mg;
    return $content;
}


sub _valid_until_datetime {
    my $self = shift;

    my $x509 = Crypt::OpenSSL::X509->new_from_file( $self->signing_cert_pathname );
    my $date_time = $x509->notAfter;
    my $utime = Date::Parse::str2time($date_time);
    return strftime('%FT%TZ', gmtime($utime) );
}


sub _gen_sp_sso_descriptor {
    my $self = shift;
    my $x    = $self->_x;

    my @acs_elements = map {
        $self->_gen_svc_assertion_consumer($_);
    } $self->acs_list;

    return $x->SPSSODescriptor(
        {
            AuthnRequestsSigned        => 'true',
            WantAssertionsSigned       => 'true',
            protocolSupportEnumeration => 'urn:oasis:names:tc:SAML:2.0:protocol',
        },
        $self->_gen_key_info('signing'),
        $self->_gen_key_info('encryption'),
        $self->_gen_nameid_format(),
        @acs_elements,
    );
}


sub _gen_key_info {
    my $self  = shift;
    my $usage = shift;
    my $x     = $self->_x;

    return $x->KeyDescriptor(
        {
            use => $usage,
        },
        $x->KeyInfo($ns_ds,
            $x->X509Data($ns_ds,
                $x->X509Certificate($ns_ds,
                    $x->NoIndentContent( $self->_signing_cert_pem_data() ),
                ),
            ),
        ),
    );
}

sub _gen_nameid_format {
    my $self = shift;
    my $x    = $self->_x;

    return $x->NameIDFormat(
        $self->nameid_format(),
    );
}


sub _gen_svc_assertion_consumer {
    my($self, $acs) = @_;
    my $x = $self->_x;

    my @is_default = $acs->{is_default}
        ? (isDefault => 'true')
        : ();

    return $x->AssertionConsumerService(
        {
            Binding   => $acs->{binding},
            Location  => $acs->{location},
            index     => $acs->{index},
            @is_default
        },
    );
}


sub _gen_organization {
    my $self = shift;
    my $x    = $self->_x;

    return $x->Organization(
        $x->OrganizationName(
            {
                _xml_lang_attribute  => 'en-us',
            },
            $self->organization_name
        ),
        $x->OrganizationDisplayName(
            {
                _xml_lang_attribute  => 'en-us',
            },
            $self->organization_name
        ),
        $x->OrganizationURL(
            {
                _xml_lang_attribute  => 'en-us',
            },
            $self->organization_url
        ),
    );
}


sub _gen_contact {
    my $self = shift;
    my $x    = $self->_x;

    my $have_contact = $self->contact_company;

    return() unless $have_contact;

    return $x->ContactPerson(
        {
            contactType      => 'technical',
        },
        $x->Company  ($self->contact_company    || ''),
        $x->GivenName(''),
        $x->SurName  (''),
    );
}


sub now_as_iso {
    return strftime('%FT%TZ', gmtime());
}


1;


__END__

=head1 NAME

Authen::NZRealMe::ServiceProvider - Class representing the local SAML2 Service Provider

=head1 DESCRIPTION

This class is used to represent the local SAML2 SP (Service Provider) which
will be used to access the NZ RealMe Login service IdP (Identity Provider) or
the NZ RealMe Assertion service IdP.  In normal use, an object of this class is
initialised from the F<metadata-sp.xml> in the configuration directory.  This
class can also be used to generate that metadata file.

=head1 METHODS

=head2 new

Constructor.  Should not be called directly.  Instead, call:

  Authen::NZRealMe->service_provider( args );

The following options are recognised:

=over 4

=item conf_dir => '/path/to/directory'

The C<conf_dir> parameter B<must> be provided.  It specifies the full pathname
of the directory containing SP and IdP metadata files as well as certificate
and key files for request signing and mutual-SSL.

=item type => ( "login" | "assertion" )

Indicate whether you wish to communicate with the "login" service or the
"assertion" service (for identity information).  Default: "login".

=item skip_signature_check => [ 0 | 1 | 2 ]

This (seldom used) option allows you to turn off verification of digital
signatures in the assertions returned from the IdP.  The default value is 0 -
meaning B<signatures will be checked>.

If set to 1, a failed signature check will result in a warning to STDERR but
further processing of the assertion will continue.  This mode is useful if the
signing certificate is scheduled to be replaced on the IdP.  Enabling this
option allows you to update your metadata before or after the scheduled change
without needing to coordinate your timing exactly with the IdP service.

Setting this option to 2 will completely skip signature checks (i.e. no errors
or warnings will be generated).

=back

=head2 new_defaults

Alternative constructor which is called to set up some sensible defaults when
generating metadata.

=head2 conf_dir

Accessor for the C<conf_dir> parameter passed in to the constructor.

=head2 entity_id

Accessor for the C<entityID> parameter in the Service Provider metadata file.

=head2 acs_list

Accessor for the details from the C<AssertionConsumerService> parameters in the
Service Provider metadata file.  This method returns a list of hashes.

=head2 organization_name

Accessor for the C<OrganizationName> component of the C<Organization> parameter in the
Service Provider metadata file.

=head2 organization_url

Accessor for the C<OrganizationURL> component of the C<Organization> parameter in the
Service Provider metadata file.

=head2 contact_company

Accessor for the C<Company> component of the C<ContactPerson> parameter in the
Service Provider metadata file.

=head2 signing_cert_pathname

Accessor for the pathname of the Service Provider's signing certificate.  This
will always be the file F<sp-sign-crt.pem> in the configuration directory.

=head2 signing_key_pathname

Accessor for the pathname of the Service Provider's signing key.  This will
always be the file F<sp-sign-key.pem> in the configuration directory.

=head2 ssl_cert_pathname

Accessor for the pathname of the Service Provider's mutual SSL certificate.
This will always be the file F<sp-ssl-crt.pem> in the configuration directory.

=head2 ssl_key_pathname

Accessor for the pathname of the Service Provider's mutual SSL private key.
This will always be the file F<sp-sign-crt.pem> in the configuration directory.

=head2 ca_cert_pathname

Name of the sub-directory (beneath F<conf_dir>) that contains the CA
certficates required to verify the certficate presented by the IdP on the back
channel when resolving an assertion.

=head2 idp

Accessor for an object representing the Identity Provider for the selected
service type ("login" or "assertion").  See:
L<Authen::NZRealMe::IdentityProvider>.

=head2 nameid_format

Returns a string URN representing the format of the NameID
requested/expected from the Identity Provider.

When this value is C<urn:urn:oasis:names:tc:SAML:2.0:nameid-format:persistent>
then the NameID value is the Federated Logon Tag (FLT).

Otherwise, it is C<urn:oasis:names:tc:SAML:2.0:nameid-format:transient>
and the FLT must be obtained via the back-channel service, iCMS.

=head2 token_generator

Creates and returns an object of the class responsible for generating random
ID tokens.

=head2 generate_saml_id

Used by the request classes to generate a unique identifier for each request.
It accepts one argument, being a string like 'AuthenRequest' to identify the
type of request.

=head2 generate_certs

Called by the C<< nzrealme make-certs >> command to run an interactive Q&A
session to generate either self-signed certificates or Certificate Signing
Requests (CSRs).  Delegates to L<Authen::NZRealMe::ServiceProvider::CertFactory>

=head2 build_meta

Called by the C<< nzrealme make-meta >> command to run an interactive Q&A
session to initialise or edit the contents of the Service Provider metadata
file.  Delegates to L<Authen::NZRealMe::ServiceProvider::Builder>

=head2 make_bundle

Called by the C<< nzrealme make-bundle >> command to create a zip archive of
the files needed by the IdP.  The archive will include the SP metadata and
certificate files.  Delegates to L<Authen::NZRealMe::ServiceProvider::Builder>

=head2 new_request( options )

Creates a new L<Authen::NZRealMe::AuthenRequest> object.  The caller would
typically use the C<as_url> method of the request to redirect the client to the
Identity Provider's single logon service.  The request object's C<request_id>
method should be used to get the request ID and save it in session state for
use later during artifact resolution.

The C<new_request> method does not B<require> any arguments, but accepts the
following optional key => value pairs:

=over 4

=item allow_create => boolean

Controls whether the user should be allowed to create a new account on the
"login" service IdP.  Not used when talking to the "assertion service".
Default: false.

=item auth_strength => string

The logon strength required.  May be supplied as a URN, or as keyword ('low',
'mod', 'sms', etc).  See L<Authen::NZRealMe::LogonStrength> for constants.
Default: 'low'.

=item relay_state => string

User-supplied string value that will be returned as a URL parameter to the
assertion consumer service.

=item acs_index => integer or 'default'

Used to specify the numeric index of the Assertion Consumer Service
you would like the response sent to.
The value C<default> may also be used to specify the ACS marked as the default.

=back

=head2 metadata_xml

Serialises the current Service Provider config parameters to a SAML2
EntityDescriptor metadata document.

=head2 sign_query_string

Used by the L<Authen::NZRealMe::AuthenRequest> class to create a digital
signature for the AuthnRequest HTTP-Redirect URL.

=head2 resolve_posted_assertion

Used to resolve the SAML response when the HTTP-POST binding is being used.

Takes the value of the SAMLResponse from the IdP's HTTP-POST response; validates
the contents and return an L<Authen::NZRealMe::ResolutionResponse> object.

Parameters (including the original request_id) must be supplied as key => value
pairs, for example:

  my $resp = $sp->resolve_artifact(
      saml_response   => $framework->param('SAMLResponse'),
      request_id      => $framework->state('login_request_id'),
      logon_strength  => 'low',        # optional
      strength_match  => 'minimum',    # optional - default: 'minimum'
  );

Recognised parameter names are:

=over 4

=item saml_response

The contents of the 'SMLResponse' parameter in the HTTP POST request from the
IdP.  This will be a Base-64 encoded string, but it should simply be passed on
without any processing.

=item see "Common resolver parameters" below

=back

=head2 resolve_artifact

Used to resolve the SAML response when the HTTP-Artifact binding is being used.

Takes an artifact (either the whole URL or just the C<SAMLart> parameter) and
contacts the Identity Provider to resolve it to a set of attributes.  An
artifact from the login server will only provide an 'FLT' attribute.  An
artifact from the assertion server will provide identity and/or address
attributes.

Parameters (including the original request_id) must be supplied as key => value
pairs, for example:

  my $resp = $sp->resolve_artifact(
      artifact        => $framework->param('SAMLart'),
      request_id      => $framework->state('login_request_id'),
      logon_strength  => 'low',        # optional
      strength_match  => 'minimum',    # optional - default: 'minimum'
  );

The assertion returned by the Identity Provider will be validated and its
contents returned as an L<Authen::NZRealMe::ResolutionResponse> object.  If an
unexpected error occurs while resolving the artifact or while validating the
resulting assertion, an exception will be thrown.  Expected error conditions
(eg: timeouts, user presses 'Cancel' etc) will not throw an exception, but will
return a response object that can be interrogated to determine the nature of
the error.  The calling application may wish to log the expected errors with
a severity of 'WARN' or 'INFO'.

Recognised parameter names are:

=over 4

=item artifact

Either the whole URL of the client request to the ACS, or just the C<SAMLart>
parameter from the querystring.

=item see "Common resolver parameters" below

=back

=head2 I<Common resolver parameters>

The following parameters can be used with both the resolve_posted_assertion()
method (for HTTP-POST binding) and the resolve_artifact() method (for
HTTP-Artifact binding).

=over 4

=item request_id

The C<request_id> returned in the original call to C<new_request>.  Your
application will need to store this in session state when initiating the
dialogue with the IdP and retrieve it from state when resolving the artifact.

=item acs_index

Optional parameter which may be used to specify the numeric index of the
Assertion Consumer Service you would like the response sent to.  This would
normally be omitted, resulting in the default being used.  Currently
the primary reason for specifying this value is if your metadata defines one or
more ACS entries using the HTTP-Artifact binding and one or more which use the
HTTP-POST binding. This parameter will allow you to tell the server which
binding to use - which may be useful while transitioning your system from one
binding to another.

=item logon_strength

Optional parameter which may be used to check that the response from the logon
service matches your application's logon strength requirements.  Specify as a
URN string or a word (e.g.: "low", "moderate").  If not provided, no check will
be performed.

=item strength_match

If a logon_strength was specified, this parameter will determine how the values
will be matched.  Provide either "minimum" (the default) or "exact".

=item resolve_flt

When resolving an artifact from the assertion service, you can provide this
option with a true value to indicate that the opaque token should be resolved
to an FLT.  If this option is not set, only the attributes from the assertion
service will be returned and no attempt will be made to connect to the iCMS
service.

=back

=head2 decrypt_assertion( $xml_string )

Called by C<resolve_posted_assertion> (or optionally by C<resolve_artifact> if
an encrypted assertion was returned) to replace any <EncryptedData> elements
with their unencrypted contents.

As a security precuation, this method will die if any unencrypted
C<< <Assertion> >> elements are present in the supplied XML.

=head2 select_acs_by_index ( $index )

Used by C<new_request> to validate the requested acs_index value.
The value C<default> may also be used to specify the ACS marked as the default.

Returns the selected ACS.

=head2 now_as_iso

Convenience method returns the current time (UTC) formatted as an ISO date/time
string.


=head1 SEE ALSO

See L<Authen::NZRealMe> for documentation index.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2022 Enrolment Services, New Zealand Electoral Commission

Written by Grant McLean E<lt>grant@catalyst.net.nzE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


