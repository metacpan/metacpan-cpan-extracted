use strict;
use warnings; 
use Test::More tests => 19;
use lib 't/PostApp/lib';
use Catalyst::Test 'PostApp';
use HTTP::Request::Common;

my $response;

$response = soap_xml_post
  ('/ws/hello',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body>World</Body></Envelope>'
  );

like($response->content, qr/Hello World/, 'Document Literal correct response: '.$response->content);
# diag("/ws/hello: ".$response->content);

$response = soap_xml_post
  ('/ws2',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><hello>World</hello></Body></Envelope>'
  );
like($response->content, qr/Hello World/, 'RPC Literal Correct response: '.$response->content);
# diag("/ws2: ".$response->content);

$response = soap_xml_post
  ('/ws/foo',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body>World</Body></Envelope>'
  );
like($response->content, qr/\<foo\>\<bar\>\<baz\>Hello World\!\<\/baz\>\<\/bar\>\<\/foo\>/, 'Literal response: '.$response->content);
# diag("/wsl/foo: ".$response->content);

$response = soap_xml_post
  ('/withwsdl/Greet',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
      <Body>
        <GreetingSpecifier xmlns="http://example.com/hello">
          <who>World</who>
          <greeting>Hello</greeting>
          <count>1</count>
        </GreetingSpecifier>
      </Body>
    </Envelope>'
  );
like($response->content, qr/greeting\>1 Hello World\!\<\//, 'Literal response: '.$response->content);
# diag("/withwsdl/Greet: ".$response->content);


$response = soap_xml_post
  ('/withwsdl/doclw',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><GreetingSpecifier xmlns="http://example.com/hello"><who>World</who><greeting>Hello</greeting><count>2</count></GreetingSpecifier></Body></Envelope>'
  );
like($response->content, qr/greeting\>2 Hello World\!\<\//, ' Document/Literal Wrapped response: '.$response->content);
# diag("/withwsdl/doclw: ".$response->content);

$response = soap_xml_post
  ('/withwsdl2/Greet','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><Greet xmlns="http://example.com/hello"><who>World</who><greeting>Hello</greeting><count>312312312312312312313</count></Greet></Body></Envelope>
  ');
like($response->content, qr/greeting[^>]+\>312312312312312312313 Hello World\!Math::BigInt\<\//, 'RPC Literal response: '.$response->content);
# diag("/withwsdl2/Greet: ".$response->content);

$response = soap_xml_post
  ('/withwsdl2/Greet','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
         <Body>
            <Greet xmlns="http://example.com/hello">
               <who>World</who>
               <greeting>Hello</greeting>
               <count>4123123123123123123</count>
            </Greet>
         </Body>
    </Envelope>
  ');
ok($response->content =~ /greeting[^>]+\>4123123123123123123 Hello World\!Math::BigInt\<\//, 'RPC Literal response: '.$response->content);
# diag("/withwsdl2/Greet: ".$response->content);

my $oldstderr = \*STDERR;
open STDERR, '>', 't/ignored_error.log';
$response = soap_xml_post
  ('/withwsdl/Greet',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><GreetingSpecifier xmlns="http://example.com/hello"><name>World</name><greeting>Hello</greeting></GreetingSpecifier></Body></Envelope>'
  );
open STDERR, '>&', \$oldstderr;
like($response->content, qr/Fault/, 'Fault on malformed body for Document-Literal: '.$response->content);
# diag("/withwsdl/Greet: ".$response->content);

$response = soap_xml_post
  ('/ws/bar',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body>World</Body></Envelope>'
  );
like($response->content, qr/Fault/, 'Fault for uncaugh exception: '.$response->content);
# diag("/ws/bar: ".$response->content);

$response = soap_xml_post
  ('/hello/Greet',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
      <Body>
        <GreetingSpecifier xmlns="http://example.com/hello">
          <who>World</who>
          <greeting>Hello</greeting>
        </GreetingSpecifier>
      </Body>
    </Envelope>'
  );
like($response->content, qr/greeting\>Hello World\!\<\//, ' using WSDLPort response: '.$response->content);
# diag("/withwsdl/Greet: ".$response->content);

$response = soap_xml_post
  ('/hello/Shout',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
      <Body>
        <GreetingSpecifier xmlns="http://example.com/hello">
          <who>World</who>
          <greeting>Hello</greeting>
        </GreetingSpecifier>
      </Body>
    </Envelope>'
  );
like($response->content, qr/greeting\>HELLO WORLD\!\!\<\//, ' using WSDLPort response: '.$response->content);
# diag("/withwsdl/Shout: ".$response->content);


$response = soap_xml_post
  ('/rpcliteral','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><Greet xmlns="http://example.com/hello"><who>World</who><greeting>Hello</greeting></Greet></Body></Envelope>
  ');
like($response->content, qr/greeting[^>]+\>Hello World\!\<\//, ' WSDLPort RPC Literal response: '.$response->content);
# diag("/withwsdl2/Greet: ".$response->content);

$response = soap_xml_post
  ('/rpcliteral','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><Shout xmlns="http://example.com/hello"><who>World</who><greeting>Hello</greeting></Shout></Body></Envelope>
  ');
like($response->content, qr/greeting[^>]+\>HELLO WORLD\!\<\//, ' WSDLPort RPC Literal response: '.$response->content);
# diag("/withwsdl2/Greet: ".$response->content);

# provoke a SOAP Fault
$response = soap_xml_post
  ('/ws/hello','');
my $soapfault = 'Fault'; 
ok($response->content =~ /$soapfault/ , ' SOAP Fault response: '.$response->content);

$response = soap_xml_post
  ('/rpcliteral','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><Blag xmlns="http://example.com/hello"><who>World</who><greeting>ok 15</greeting></Blag></Body></Envelope>
  ');
is($response->content, 'ok 15');

$response = soap_xml_post
  ('/hello5','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><GreetingSpecifier xmlns="http://example.com/hello"><who>World</who><greeting>ok 16</greeting></GreetingSpecifier></Body></Envelope>
  ');
is($response->content, 'ok 16');

$response = soap_xml_post
  ('/doclitwrapped','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><who xmlns="http://example.com/hello">World</who><greeting xmlns="http://example.com/hello">Blag</greeting></Body></Envelope>
  ', 'http://example.com/Blag');
is($response->content, 'Blag Blag World!');

$response = soap_xml_post
  ('/doclitwrapped','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><who xmlns="http://example.com/hello">World</who><greeting xmlns="http://example.com/hello">Hello</greeting></Body></Envelope>
  ', 'http://example.com/Greet');
like($response->content, qr/greeting[^>]+\>Greet Hello World\!\<\//, ' WSDLPort Document/Literal-Wrapped response: '.$response->content);

$response = soap_xml_post
  ('/doclitwrapped','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><who xmlns="http://example.com/hello">World</who><greeting xmlns="http://example.com/hello">Hello</greeting></Body></Envelope>
  ', 'http://example.com/Shout');
like($response->content, qr/greeting[^>]+\>Shout Hello World\!\<\//, ' WSDLPort Document/Literal-Wrapped response: '.$response->content);

sub soap_xml_post {
    my $path = shift;
    my $content = shift;
    my $soap_action = shift || 'http://example.com/actions/Greet';

    return request POST $path,
        Content => $content,
        Content_Type => 'application/soap+xml',
        SOAPAction => $soap_action;
}

1;
