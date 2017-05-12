package MockSP;

use 5.010;
use strict;
use warnings;
use autodie;

use parent 'Authen::NZRealMe::ServiceProvider';

use AuthenNZRealMeTestHelper;

use MIME::Base64    qw(decode_base64);
use HTTP::Response  qw();


sub resolve_artifact {
    my $self = shift;
    $self->{_test_request_log_} = [];
    return $self->SUPER::resolve_artifact(@_);
}


sub test_request_log {
    my $self = shift;
    return @{ $self->{_test_request_log_} };
}


sub _https_post {
    my($self, $url, $headers, $soap_body) = @_;

    push @{ $self->{_test_request_log_} }, $soap_body;

    my $response_file = $url =~ /ws.test.logon.fakeme.govt.nz/
        ? $self->_icms_response_file($soap_body)
        : $self->_saml_response_file($soap_body);

    my $content = do {
        local($/);
        open my $fh, '<', $response_file;
        <$fh>;
    };

    my $resp = HTTP::Response->new(200, 'OK', [], $content );
    return $resp;
}


sub _saml_response_file {
    my($self, $soap_body) = @_;

    my($artifact) = $soap_body =~ m{
        <\w+:Artifact>
          ([^<]+)
        </\w+:Artifact>
    }x;

    my $bytes = decode_base64($artifact);
    my($type_code, $index, $source_id, $msg_handle) = unpack('nna20a20', $bytes);
    my $file_name = sprintf('%s-assertion-%d.xml',
        $self->type eq 'login' ? 'login' : 'identity',
        $msg_handle
    );
    return test_data_file($file_name);
}


sub _icms_response_file {
    my($self, $soap_body) = @_;

    my($request_number) = $soap_body =~ m{
        <fakeToken>identity-(\d+)</fakeToken>
    }x;
    return test_data_file("icms-response-$request_number.xml");
}


sub _extract_flt {
    my($self, $xml, %args) = @_;
    # Work around fact that sigs on test-data/icms-response.xml are borked

    my $xc = $self->_xpath_context_dom($xml,
        [ soap  => "http://www.w3.org/2003/05/soap-envelope" ],
        [ wst   => "http://docs.oasis-open.org/ws-sx/ws-trust/200512/" ],
        [ saml  => 'urn:oasis:names:tc:SAML:2.0:assertion' ],
    );
    return $xc->findvalue(q{/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/wst:RequestedSecurityToken/saml:Assertion/saml:Subject/saml:NameID});
}


sub wind_back_clock {
    my $self = shift;
    $self->{_stopped_clock_time_} = shift;
}


sub now_as_iso {
    my $self = shift;

    return $self->{_stopped_clock_time_} if $self->{_stopped_clock_time_};
    return $self->SUPER::now_as_iso();
}


1;
