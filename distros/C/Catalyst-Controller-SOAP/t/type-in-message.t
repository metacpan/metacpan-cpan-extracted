use Test::More tests => 2;

BEGIN { use_ok('Catalyst::Controller::SOAP') };
use Catalyst::Action::SOAP::DocumentLiteral;
use lib qw(t/lib);
use Catalyst::Test 'TestApp2';
use Encode;
use HTTP::Request::Common;

my $response = soap_xml_post('/hello',<<SOAPENV);
   <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
      <Body>
        <GreetingSpecifier xmlns="http://example.com/hello">
          <who>World</who>
          <greeting>Hello</greeting>
          <count>1</count>
        </GreetingSpecifier>
      </Body>
    </Envelope>
SOAPENV

like($response->content, qr/Hello World/, 'Hello World!');

sub soap_xml_post {
    my $path = shift;
    my $content = shift;

    return request POST $path, 
        Content => $content,
        Content_Type => 'application/soap+xml', 
        SOAPAction => 'http://example.com/actions/Greet';
}
