package Catmandu::WoS::AuthWSDL;

use Catmandu::Sane;

our $VERSION = '0.01';

sub xml {
    state $xml = do {binmode DATA, 'encoding(utf-8)'; local $/; <DATA>};
}

1;

=encoding utf-8

=head1 NAME

Catmandu::WoS::AuthWSDL - WoK authentication web service wsdl

=cut

__DATA__
<?xml version='1.0' encoding='UTF-8'?><wsdl:definitions xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:WOKMWSAuthenticate="http://auth.cxf.wokmws.thomsonreuters.com" name="WOKMWSAuthenticateService" targetNamespace="http://auth.cxf.wokmws.thomsonreuters.com">
  <wsdl:types>
<xs:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:WOKMWSAuthenticate="http://auth.cxf.wokmws.thomsonreuters.com" attributeFormDefault="unqualified" elementFormDefault="unqualified" targetNamespace="http://auth.cxf.wokmws.thomsonreuters.com">
<xs:element name="authenticate" type="WOKMWSAuthenticate:authenticate"/>
<xs:element name="authenticateResponse" type="WOKMWSAuthenticate:authenticateResponse"/>
<xs:element name="closeSession" type="WOKMWSAuthenticate:closeSession"/>
<xs:element name="closeSessionResponse" type="WOKMWSAuthenticate:closeSessionResponse"/>
<xs:complexType name="authenticate">
<xs:sequence/>
</xs:complexType>
<xs:complexType name="authenticateResponse">
<xs:sequence>
<xs:element minOccurs="0" name="return" type="xs:string"/>
</xs:sequence>
</xs:complexType>
<xs:complexType name="closeSession">
<xs:sequence/>
</xs:complexType>
<xs:complexType name="closeSessionResponse">
<xs:sequence/>
</xs:complexType>
<xs:element name="InternalServerException" type="WOKMWSAuthenticate:InternalServerException"/>
<xs:complexType name="InternalServerException">
<xs:sequence/>
</xs:complexType>
<xs:element name="ESTIWSException" type="WOKMWSAuthenticate:ESTIWSException"/>
<xs:complexType name="ESTIWSException">
<xs:sequence/>
</xs:complexType>
<xs:element name="SessionException" type="WOKMWSAuthenticate:SessionException"/>
<xs:complexType name="SessionException">
<xs:sequence/>
</xs:complexType>
<xs:element name="AuthenticationException" type="WOKMWSAuthenticate:AuthenticationException"/>
<xs:complexType name="AuthenticationException">
<xs:sequence/>
</xs:complexType>
<xs:element name="QueryException" type="WOKMWSAuthenticate:QueryException"/>
<xs:complexType name="QueryException">
<xs:sequence/>
</xs:complexType>
<xs:element name="InvalidInputException" type="WOKMWSAuthenticate:InvalidInputException"/>
<xs:complexType name="InvalidInputException">
<xs:sequence/>
</xs:complexType>
</xs:schema>
  </wsdl:types>
  <wsdl:message name="closeSession">
    <wsdl:part element="WOKMWSAuthenticate:closeSession" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="SessionException">
    <wsdl:part element="WOKMWSAuthenticate:SessionException" name="SessionException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="ESTIWSException">
    <wsdl:part element="WOKMWSAuthenticate:ESTIWSException" name="ESTIWSException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="QueryException">
    <wsdl:part element="WOKMWSAuthenticate:QueryException" name="QueryException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="authenticate">
    <wsdl:part element="WOKMWSAuthenticate:authenticate" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="closeSessionResponse">
    <wsdl:part element="WOKMWSAuthenticate:closeSessionResponse" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="InvalidInputException">
    <wsdl:part element="WOKMWSAuthenticate:InvalidInputException" name="InvalidInputException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="InternalServerException">
    <wsdl:part element="WOKMWSAuthenticate:InternalServerException" name="InternalServerException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="authenticateResponse">
    <wsdl:part element="WOKMWSAuthenticate:authenticateResponse" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="AuthenticationException">
    <wsdl:part element="WOKMWSAuthenticate:AuthenticationException" name="AuthenticationException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:portType name="WOKMWSAuthenticate">
    <wsdl:operation name="authenticate">
      <wsdl:input message="WOKMWSAuthenticate:authenticate" name="authenticate">
    </wsdl:input>
      <wsdl:output message="WOKMWSAuthenticate:authenticateResponse" name="authenticateResponse">
    </wsdl:output>
      <wsdl:fault message="WOKMWSAuthenticate:InvalidInputException" name="InvalidInputException">
    </wsdl:fault>
      <wsdl:fault message="WOKMWSAuthenticate:QueryException" name="QueryException">
    </wsdl:fault>
      <wsdl:fault message="WOKMWSAuthenticate:AuthenticationException" name="AuthenticationException">
    </wsdl:fault>
      <wsdl:fault message="WOKMWSAuthenticate:InternalServerException" name="InternalServerException">
    </wsdl:fault>
      <wsdl:fault message="WOKMWSAuthenticate:SessionException" name="SessionException">
    </wsdl:fault>
      <wsdl:fault message="WOKMWSAuthenticate:ESTIWSException" name="ESTIWSException">
    </wsdl:fault>
    </wsdl:operation>
    <wsdl:operation name="closeSession">
      <wsdl:input message="WOKMWSAuthenticate:closeSession" name="closeSession">
    </wsdl:input>
      <wsdl:output message="WOKMWSAuthenticate:closeSessionResponse" name="closeSessionResponse">
    </wsdl:output>
      <wsdl:fault message="WOKMWSAuthenticate:InvalidInputException" name="InvalidInputException">
    </wsdl:fault>
      <wsdl:fault message="WOKMWSAuthenticate:QueryException" name="QueryException">
    </wsdl:fault>
      <wsdl:fault message="WOKMWSAuthenticate:AuthenticationException" name="AuthenticationException">
    </wsdl:fault>
      <wsdl:fault message="WOKMWSAuthenticate:InternalServerException" name="InternalServerException">
    </wsdl:fault>
      <wsdl:fault message="WOKMWSAuthenticate:SessionException" name="SessionException">
    </wsdl:fault>
      <wsdl:fault message="WOKMWSAuthenticate:ESTIWSException" name="ESTIWSException">
    </wsdl:fault>
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:binding name="WOKMWSAuthenticateServiceSoapBinding" type="WOKMWSAuthenticate:WOKMWSAuthenticate">
    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
    <wsdl:operation name="authenticate">
      <soap:operation soapAction="" style="document"/>
      <wsdl:input name="authenticate">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="authenticateResponse">
        <soap:body use="literal"/>
      </wsdl:output>
      <wsdl:fault name="InvalidInputException">
        <soap:fault name="InvalidInputException" use="literal"/>
      </wsdl:fault>
      <wsdl:fault name="QueryException">
        <soap:fault name="QueryException" use="literal"/>
      </wsdl:fault>
      <wsdl:fault name="AuthenticationException">
        <soap:fault name="AuthenticationException" use="literal"/>
      </wsdl:fault>
      <wsdl:fault name="InternalServerException">
        <soap:fault name="InternalServerException" use="literal"/>
      </wsdl:fault>
      <wsdl:fault name="SessionException">
        <soap:fault name="SessionException" use="literal"/>
      </wsdl:fault>
      <wsdl:fault name="ESTIWSException">
        <soap:fault name="ESTIWSException" use="literal"/>
      </wsdl:fault>
    </wsdl:operation>
    <wsdl:operation name="closeSession">
      <soap:operation soapAction="" style="document"/>
      <wsdl:input name="closeSession">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="closeSessionResponse">
        <soap:body use="literal"/>
      </wsdl:output>
      <wsdl:fault name="InvalidInputException">
        <soap:fault name="InvalidInputException" use="literal"/>
      </wsdl:fault>
      <wsdl:fault name="QueryException">
        <soap:fault name="QueryException" use="literal"/>
      </wsdl:fault>
      <wsdl:fault name="AuthenticationException">
        <soap:fault name="AuthenticationException" use="literal"/>
      </wsdl:fault>
      <wsdl:fault name="InternalServerException">
        <soap:fault name="InternalServerException" use="literal"/>
      </wsdl:fault>
      <wsdl:fault name="SessionException">
        <soap:fault name="SessionException" use="literal"/>
      </wsdl:fault>
      <wsdl:fault name="ESTIWSException">
        <soap:fault name="ESTIWSException" use="literal"/>
      </wsdl:fault>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:service name="WOKMWSAuthenticateService">
    <wsdl:port binding="WOKMWSAuthenticate:WOKMWSAuthenticateServiceSoapBinding" name="WOKMWSAuthenticatePort">
      <soap:address location="http://search.webofknowledge.com/esti/wokmws/ws/WOKMWSAuthenticate"/>
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>
