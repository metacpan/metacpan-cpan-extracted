package Catmandu::WoS::WSDL;

use Catmandu::Sane;

our $VERSION = '0.02';

sub xml {
    state $xml = do {binmode DATA, 'encoding(utf-8)'; local $/; <DATA>};
}

1;

1;

=encoding utf-8

=head1 NAME

Catmandu::WoS::WSDL - WoK web service wsdl

=cut

__DATA__
<?xml version='1.0' encoding='UTF-8'?><wsdl:definitions xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:woksearch="http://woksearch.v3.wokmws.thomsonreuters.com" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" name="WokSearchService" targetNamespace="http://woksearch.v3.wokmws.thomsonreuters.com">
<wsdl:documentation>The namespace in the WokSearch Web service version 2 was "http://woksearch.cxf.wokmws.thomsonreuters.com".</wsdl:documentation>
  <wsdl:types>
<xs:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:woksearch="http://woksearch.v3.wokmws.thomsonreuters.com" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" attributeFormDefault="unqualified" elementFormDefault="unqualified" targetNamespace="http://woksearch.v3.wokmws.thomsonreuters.com">

<xs:element name="citedReferences" type="woksearch:citedReferences"/>
<xs:element name="citedReferencesResponse" type="woksearch:citedReferencesResponse"/>

<xs:element name="citedReferencesRetrieve" type="woksearch:citedReferencesRetrieve"/>
<xs:element name="citedReferencesRetrieveResponse" type="woksearch:citedReferencesRetrieveResponse"/>

<xs:element name="citingArticles" type="woksearch:citingArticles"/>
<xs:element name="citingArticlesResponse" type="woksearch:citingArticlesResponse"/>

<xs:element name="relatedRecords" type="woksearch:relatedRecords"/>
<xs:element name="relatedRecordsResponse" type="woksearch:relatedRecordsResponse"/>

<xs:element name="retrieve" type="woksearch:retrieve"/>
<xs:element name="retrieveResponse" type="woksearch:retrieveResponse"/>

<xs:element name="retrieveById" type="woksearch:retrieveById"/>
<xs:element name="retrieveByIdResponse" type="woksearch:retrieveByIdResponse"/>

<xs:element name="search" type="woksearch:search"/>
<xs:element name="searchResponse" type="woksearch:searchResponse"/>


<xs:complexType name="citedReferences">
<xs:sequence>
    <xsd:annotation>
        <xsd:documentation>In version 2, the sequence was databaseId, uid, editions, timeSpan, queryLanguage, retrieveParameters. 
    Now the sequence is databaseId, uid, queryLanguage, retrieveParameters. Now the editions and timeSpan elements no longer valid element names.</xsd:documentation>
      </xsd:annotation> 
    <xs:element name="databaseId" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
    <xs:element name="uid" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>
    <xs:element name="queryLanguage" type="xs:string"/>
    <xs:element name="retrieveParameters" type="woksearch:retrieveParameters">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
</xs:sequence>
</xs:complexType>

<xs:complexType name="citedReferencesResponse">
<xs:sequence>
<xs:element minOccurs="0" name="return" type="woksearch:citedReferencesSearchResults"/>
</xs:sequence>
</xs:complexType>

<xs:complexType name="citedReferencesRetrieve">
<xs:sequence>
    <xs:element name="queryId" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation>  
    </xs:element>
    <xs:element name="retrieveParameters" type="woksearch:retrieveParameters">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation>    
    </xs:element>
</xs:sequence>
</xs:complexType>

<xs:complexType name="citedReferencesRetrieveResponse">
<xs:sequence>
<xs:element maxOccurs="unbounded" minOccurs="0" name="return" type="woksearch:citedReference"/>
</xs:sequence>
</xs:complexType>

<xs:complexType name="citingArticles">
<xsd:annotation>
      <xsd:documentation>citingArticles, relatedRecords have identical structure (e.g., parameters).</xsd:documentation>
    </xsd:annotation>

<xs:sequence>
    <xs:element name="databaseId" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
    <xs:element name="uid" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>        
    <xs:element maxOccurs="unbounded" minOccurs="0" name="editions" type="woksearch:editionDesc">
<xsd:annotation>
          <xsd:documentation>In version 3, this is no longer nillable.</xsd:documentation>
        </xsd:annotation>     
    </xs:element>   
    <xs:element minOccurs="0" name="timeSpan" type="woksearch:timeSpan"/>
    <xs:element name="queryLanguage" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>     
    <xs:element name="retrieveParameters" type="woksearch:retrieveParameters">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
</xs:sequence>
</xs:complexType>

<xs:complexType name="citingArticlesResponse">
<xs:sequence>
<xs:element minOccurs="0" name="return" type="woksearch:fullRecordSearchResults"/>
</xs:sequence>
</xs:complexType>

<xs:complexType name="relatedRecords">
<xsd:annotation>
      <xsd:documentation>citingArticles, relatedRecords have identical structure (e.g., parameters).</xsd:documentation>
    </xsd:annotation>

<xs:sequence>
    <xs:element name="databaseId" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>            
    <xs:element name="uid" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>        
    <xs:element maxOccurs="unbounded" minOccurs="0" name="editions" type="woksearch:editionDesc">
		<xsd:annotation>
          <xsd:documentation>In version 3, this is no longer nillable.</xsd:documentation>
        </xsd:annotation>     
    </xs:element>  
    <xs:element minOccurs="0" name="timeSpan" type="woksearch:timeSpan"/>
    <xs:element name="queryLanguage" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>     
    <xs:element name="retrieveParameters" type="woksearch:retrieveParameters">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
</xs:sequence>
</xs:complexType>

<xs:complexType name="relatedRecordsResponse">
<xs:sequence>
<xs:element minOccurs="0" name="return" type="woksearch:fullRecordSearchResults"/>
</xs:sequence>
</xs:complexType>

<xs:complexType name="retrieve">
<xs:sequence>
    <xs:element name="queryId" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation>
    </xs:element> 
    <xs:element name="retrieveParameters" type="woksearch:retrieveParameters">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
</xs:sequence>
</xs:complexType>

<xs:complexType name="retrieveResponse">
<xs:sequence>
<xs:element minOccurs="0" name="return" type="woksearch:fullRecordData"/>
</xs:sequence>
</xs:complexType>

<xs:complexType name="retrieveById">
<xs:sequence>
    <xsd:annotation>
    <xsd:documentation>
    In version 2, the sequence was databaseId, uids, queryLanguage, retrieveParameters.
    Now the sequence is databaseId, uid, queryLanguage, retrieveParameters. 
    </xsd:documentation>
    </xsd:annotation>
    
    <xs:element name="databaseId" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
    <xs:element maxOccurs="unbounded" name="uid" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required. In version 2, the element name was uids.</xsd:documentation>
        </xsd:annotation>
    </xs:element>    
    <xs:element name="queryLanguage" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>     
    <xs:element name="retrieveParameters" type="woksearch:retrieveParameters">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
</xs:sequence>
</xs:complexType>

<xs:complexType name="retrieveByIdResponse">
<xs:sequence>
    <xs:element minOccurs="0" name="return" type="woksearch:fullRecordSearchResults"/>
</xs:sequence>
</xs:complexType>

<xs:complexType name="search">
<xs:sequence>
    <xs:element name="queryParameters" type="woksearch:queryParameters">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
    <xs:element name="retrieveParameters" type="woksearch:retrieveParameters">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
</xs:sequence>
</xs:complexType>

<xs:complexType name="searchResponse">
<xs:sequence>
<xs:element minOccurs="0" name="return" type="woksearch:fullRecordSearchResults"/>
</xs:sequence>
</xs:complexType>


<xs:complexType name="queryParameters">
<xs:sequence>
    <xsd:annotation>
      <xsd:documentation>
      In version 2, the sequence was databaseID, editions, queryLanguage, symbolicTimeSpan, timeSpan, userQuery. 
      In version 3, the sequence is: databaseId, userQuery, editions, symbolicTimeSpan, timeSpan, queryLanguage. 
      </xsd:documentation>
    </xsd:annotation>
    <xs:element name="databaseId" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, the element name was databaseID and minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element> 
    <xs:element name="userQuery" type="xs:string">  
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>          
    <xs:element maxOccurs="unbounded" minOccurs="0" name="editions" type="woksearch:editionDesc">
        <xsd:annotation>
            <xsd:documentation>In version 3, it is no longer nillable.</xsd:documentation>
        </xsd:annotation>     
    </xs:element>
    <xs:element minOccurs="0" name="symbolicTimeSpan" type="xs:string"/>
    <xs:element minOccurs="0" name="timeSpan" type="woksearch:timeSpan"/>
    <xs:element name="queryLanguage" type="xs:string">
        <xsd:annotation>
        <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        <!--  <xsd:documentation>The value AUTO will be accepted as meaning use the default language for this databaseId.</xsd:documentation> -->
        </xsd:annotation> 
    </xs:element>     
</xs:sequence>
</xs:complexType>

<xs:complexType name="editionDesc">
<xs:sequence>
    <xs:element name="collection" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
    <xs:element name="edition" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
</xs:sequence>
</xs:complexType>

<xs:complexType name="timeSpan">
<xs:sequence>
    <xs:element name="begin" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation> 
    </xs:element>    
    <xs:element name="end" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation>     
    </xs:element>
</xs:sequence>
</xs:complexType>


<xs:complexType name="retrieveParameters">
<xs:sequence>
    <xsd:annotation>
      <xsd:documentation>
      In version 2, the sequence was: collectionFields, count, fields, firstRecord, options.
      In version 3, the sequence is: firstRecord, count, sortField, viewField, option.
      </xsd:documentation>
    </xsd:annotation>
    <xs:element name="firstRecord" type="xs:int"/>  
    <xs:element name="count" type="xs:int"/>   
    <xs:element maxOccurs="unbounded" minOccurs="0" name="sortField" type="woksearch:sortField">
        <xsd:annotation>
            <xsd:documentation>In version 2, the name was fields and the type was woksearch:queryField. In version 3, it is no longer nillable.</xsd:documentation>
        </xsd:annotation>    
    </xs:element>       
    <xs:element maxOccurs="unbounded" minOccurs="0" name="viewField" type="woksearch:viewField">
        <xsd:annotation>
            <xsd:documentation>In version 2, the name was collectionFields and the type was woksearch:collectionFields. In version 3, it is no longer nillable.</xsd:documentation>
        </xsd:annotation>    
    </xs:element>     
    <xs:element maxOccurs="unbounded" minOccurs="0" name="option" type="woksearch:keyValuePair">
        <xsd:annotation>
            <xsd:documentation>In version 3, it is no longer nillable.</xsd:documentation>
        </xsd:annotation>     
    </xs:element>      
</xs:sequence>
</xs:complexType>

<xs:complexType name="sortField">
   <xsd:annotation>
        <xsd:documentation>In version 2, the name of the type was queryField.</xsd:documentation>
   </xsd:annotation>   
<xs:sequence>
    <xs:element name="name" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation>  
    </xs:element>
    <xs:element name="sort" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        <!--  
        <xsd:documentation>The value AUTO will be accepted as meaning use the default sort order for this sort field for this databaseId.</xsd:documentation> 
        -->
        </xsd:annotation>  
    </xs:element>        
</xs:sequence>
</xs:complexType>

<xs:complexType name="viewField">
    <xsd:annotation>
        <xsd:documentation>In version 2, the name of the type was collectionFields.</xsd:documentation>
    </xsd:annotation> 
<xs:sequence>
    <xsd:annotation>
      <xsd:documentation>
      In version 2, the sequence was collectionName, fieldList and listName. However, listName was ignored.
      In version 3, the sequence is: collectionName and fieldName. The name fieldList has changed to fieldName. listName is no longer a valid XML element.
      </xsd:documentation>
    </xsd:annotation>
    <xs:element minOccurs="1" name="collectionName" type="xs:string">
    <xsd:annotation>
      <xsd:documentation>
      In version 2, minOccurs='0'. Now this element is required.
      </xsd:documentation>
    </xsd:annotation>
    </xs:element>
    <xs:element maxOccurs="unbounded" minOccurs="0" name="fieldName" type="xs:string">
      <xsd:annotation>
        <xsd:documentation>A single fieldName whose value is an empty string, a string of length zero, will return 
        the minimal XML record structure. 
        </xsd:documentation>
      </xsd:annotation>
    </xs:element>
</xs:sequence>
</xs:complexType>

<xs:complexType name="keyValuePair">
<xs:sequence>
    <xs:element name="key" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0. Now this element is required.</xsd:documentation>
        </xsd:annotation>      
    </xs:element>
    <xs:element name="value" nillable="true" type="xs:string">
        <xsd:annotation>
          <xsd:documentation>In version 2, minOccurs=0 and nillable was not specified (hence, false). Now this element is required and is nillable.</xsd:documentation>
        </xsd:annotation>  
    </xs:element>    
</xs:sequence>
</xs:complexType>


<xs:complexType name="fullRecordSearchResults">

    <xsd:annotation>
        <xsd:documentation>In version 2, the sequence of the elements was options, parent, queryID, records, recordsFound, recordsSearched.
        In version 3, the sequence is:  queryId, recordsFound, recordsSearched, parent, optionValue, records. The name options has changed to optionValue. 
        </xsd:documentation>
    </xsd:annotation> 
    
<xs:sequence>

<xs:element minOccurs="0" name="queryId" type="xs:string">
    <xsd:annotation>
          <xsd:documentation>In version 2, this element name was queryID. Now it is queryId.</xsd:documentation>
        </xsd:annotation>  
</xs:element>
<xs:element name="recordsFound" type="xs:int"/>
<xs:element name="recordsSearched" type="xs:long"/>
<xs:element minOccurs="0" name="parent" type="xs:string"/>
<xs:element maxOccurs="unbounded" minOccurs="0" name="optionValue" nillable="true" type="woksearch:labelValuesPair">
    <xsd:annotation>
          <xsd:documentation>In version 2, this element name was options.</xsd:documentation>
        </xsd:annotation>  
</xs:element>

<xs:element minOccurs="0" name="records" type="xs:string"/>

</xs:sequence>
</xs:complexType>

<xs:complexType name="fullRecordData">
<xs:sequence>
<xs:element maxOccurs="unbounded" minOccurs="0" name="optionValue" nillable="true" type="woksearch:labelValuesPair">
    <xsd:annotation>
          <xsd:documentation>In version 2, this element name was options.</xsd:documentation>
        </xsd:annotation>  
</xs:element>
<xs:element minOccurs="0" name="records" type="xs:string"/>
</xs:sequence>
</xs:complexType>

<xs:complexType name="labelValuesPair">
<xs:sequence>
<xs:element minOccurs="0" name="label" type="xs:string"/>
<xs:element maxOccurs="unbounded" minOccurs="0" name="value" nillable="true" type="xs:string">
    <xsd:annotation>
          <xsd:documentation>In version 2, this element name was values.</xsd:documentation>
        </xsd:annotation>  
</xs:element>
</xs:sequence>
</xs:complexType>


<xs:complexType name="citedReferencesSearchResults">
<xs:sequence>
<xs:element minOccurs="0" name="queryId" type="xs:string">
    <xsd:annotation>
          <xsd:documentation>In version 2, this element name was queryID.</xsd:documentation>
        </xsd:annotation> 
</xs:element>
<xs:element maxOccurs="unbounded" minOccurs="0" name="references" nillable="true" type="woksearch:citedReference">
    <xsd:annotation>
          <xsd:documentation>In version 2, this element name was records. However, the data within this element is references not source records.</xsd:documentation>
        </xsd:annotation> 
</xs:element>
<xs:element name="recordsFound" type="xs:int"/>
<xs:element name="recordsSearched" type="xs:long"/>
</xs:sequence>
</xs:complexType>

<xs:complexType name="citedReference">
    <xsd:annotation>
      <xsd:documentation>
    In version 2, the sequence was articleID, citedAuthor, citedTitle, citedWork, page, recID, refID, timesCited, volume, year.
    </xsd:documentation>
    </xsd:annotation> 
<xs:sequence>
<xs:element minOccurs="0" name="uid" type="xs:string">
    <xsd:annotation>
          <xsd:documentation>In version 2, this element name was recID. Now recID does not exist.</xsd:documentation>
        </xsd:annotation> 
</xs:element>
<xs:element minOccurs="0" name="docid" type="xs:string">
    <xsd:annotation>
          <xsd:documentation>In version 2, this element name was refID. Now refID does not exist.</xsd:documentation>
        </xsd:annotation> 
</xs:element>
<xs:element minOccurs="0" name="articleId" type="xs:string">
    <xsd:annotation>
          <xsd:documentation>In version 2, this element name was articleID. Now articleID does not exist.</xsd:documentation>
        </xsd:annotation> 
</xs:element>
<xs:element minOccurs="0" name="citedAuthor" type="xs:string"/>
<xs:element minOccurs="0" name="timesCited" type="xs:string"/>
<xs:element minOccurs="0" name="year" type="xs:string"/>
<xs:element minOccurs="0" name="page" type="xs:string"/>
<xs:element minOccurs="0" name="volume" type="xs:string"/>
<xs:element minOccurs="0" name="citedTitle" type="xs:string"/>
<xs:element minOccurs="0" name="citedWork" type="xs:string"/>
<xs:element minOccurs="0" name="hot" type="xs:string">
    <xsd:annotation>
          <xsd:documentation>In version 2, this element name did not exist.</xsd:documentation>
        </xsd:annotation>
</xs:element>
</xs:sequence>
</xs:complexType>

<xs:complexType name="FaultInformation">
    <xsd:annotation>
      <xsd:documentation>
      The FaultInformation is detail for the SOAP fault. This information did not exist in WokSearch version 2. However the Fault did 
      exist.  
      </xsd:documentation>
    </xsd:annotation>
<xs:sequence>
    <xs:element name="code" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The code is an identifier for the specific message found in the SOAP Fault faultstring element. 
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>

    <xs:element minOccurs="0" name="message" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The message is the detail of the code element.  
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>
        
    <xs:element minOccurs="0" name="reason" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The reason is a more detailed explanation of the message element.
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>
        
    <xs:element minOccurs="0" name="causeType" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The causeType should be one of "service", "handshake" or "remote". Any other value should be considered "service".
      If the causeType is "service" then the exception occurred within this Web service. 
      If the causeType is "handshake" then the exception occurred within this Web service while attempting to access 
      a supporting Web service (see the remoteException element for more information on the exception). 
      If the causeType is "remote" then an exception has been sent from a supporting Web service 
      (see the remoteException element for more information on the exception).
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>
        
    <xs:element minOccurs="0" name="cause" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The cause is a low-level explanation of the reason for the exception. 
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>
    
    <xs:element minOccurs="0" name="supportingWebServiceException" type="woksearch:SupportingWebServiceException">
      <xsd:annotation>
      <xsd:documentation>
      The remoteException contains error information from a supporting Web service or while attempting to access a 
      supporting Web service. Also see causeType. 
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>
        
    <xs:element minOccurs="0" name="remedy" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The remedy indicates the action that should be taken on the client side, or requester side, to correct the problem.
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>  
    
</xs:sequence>
</xs:complexType>

<xs:complexType name="RawFaultInformation">
    <xsd:annotation>
      <xsd:documentation>
      The RawFaultInformation is consists of the static message text of the faultstring, message, reason, cause and remedy elements
      along with the message data used to instantiate the message parameters. Message parameters are of the form {0}, {1}, etc. 
      and conform to the Java 5 java.text.MessageFormat API.  
       
      This information did not exist in WokSearch version 2. However the Fault did exist.  
      </xsd:documentation>
    </xsd:annotation>
<xs:sequence>
    
    <xs:element minOccurs="0" name="rawFaultstring" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The rawFaultstring is the text of the faultstring element without the messageData applied.  
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>
                
    <xs:element minOccurs="0" name="rawMessage" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The rawMessage is the text of the message element without the messageData applied.  
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>
    
    <xs:element minOccurs="0" name="rawReason" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The rawReason is the text of the reason element without the messageData applied.  
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>

    <xs:element minOccurs="0" name="rawCause" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The rawCause is the text of the cause element without the messageData applied.  
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>

    <xs:element minOccurs="0" name="rawRemedy" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The rawRemedy is the text of the remedy element without the messageData applied.  
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>
                
    <xs:element maxOccurs="unbounded" minOccurs="0" name="messageData" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The messageData is the data to be applied to the rawFaultstring, rawMessage, rawReason, rawCause and rawRemedy elements, 
      to create the text of the faultstring, message, reason, cause and remedy element, respectively.  
      </xsd:documentation>
      </xsd:annotation>
    </xs:element>
    
    
</xs:sequence>
</xs:complexType>

<xs:complexType name="SupportingWebServiceException">
<xs:sequence>
    <xs:element minOccurs="0" name="remoteNamespace" type="xs:string">
    <xsd:annotation>
      <xsd:documentation>
      The remoteNamespace is the XML namespace of the supporting Web service. 
      </xsd:documentation>
    </xsd:annotation>
    </xs:element>
    
    <xs:element minOccurs="0" name="remoteOperation" type="xs:string">
    <xsd:annotation>
      <xsd:documentation>
      The remoteOperation is in the form WS.operation, where WS is the name of the Web service and operation is the name of the 
      requested Web service operation. The Web service may or may not be a SOAP Web service. 
      </xsd:documentation>
    </xsd:annotation>
    </xs:element>
    
    <xs:element minOccurs="0" name="remoteCode" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The remoteCode is the error code returned by the supporting Web service. If this is blank then the supporting Web service did not return 
      a fault message. The error could have occurred while attempting to contact the supporting Web service: 
      look in the handshakeCauseId and handshakeCause. 
      </xsd:documentation>
    </xsd:annotation>
    </xs:element>
    
    <xs:element minOccurs="0" name="remoteReason" type="xs:string">
      <xsd:annotation>
      <xsd:documentation>
      The remoteReason is the description corresponding to the remoteCode. 
      </xsd:documentation>
    </xsd:annotation>
    </xs:element>    
    
    <xs:element minOccurs="0" name="handshakeCauseId" type="xs:string">
    <xsd:annotation>
      <xsd:documentation>
      The handshakeCauseId is the implementation class name of the exception within this Web service (which may change).
      If the handshakeCauseId or the handshakeCause exist then an error occurred attempting to access the supporting Web service specified in 
      the remoteOperation element. If there is a remoteCode and/or remoteReason then the handshake error information indicates an exception
      within this Web service while handling the (error) response message from the supporting Web service.  
      If the remoteCode and remoteReason are empty strings or are not present then the handshake error information corresponds to an exception
      within this Web service while attempting to send a request to the supporting Web service.  
      </xsd:documentation>
    </xsd:annotation>
    </xs:element>    
        
    <xs:element minOccurs="0" name="handshakeCause" type="xs:string">
    <xsd:annotation>
      <xsd:documentation>
      See the annotation for the handshakeCauseId element.
      </xsd:documentation>
    </xsd:annotation>
    </xs:element> 
</xs:sequence>
</xs:complexType>

<xs:element name="QueryException" type="woksearch:QueryException">
    <xsd:annotation>
      <xsd:documentation>
      The QueryException indicates that there is an error within the userQuery element in the SOAP request message for the requested operation. 
      </xsd:documentation>
    </xsd:annotation>
</xs:element>
    
<xs:complexType name="QueryException">
    <xsd:annotation>
      <xsd:documentation>
      In version 2, the faultInformation and rawFaultInformation elements did not exist. It is not required that the service return 
      these elements. 
      </xsd:documentation>
    </xsd:annotation>
<xs:sequence>
    <xs:element minOccurs="0" name="faultInformation" type="woksearch:FaultInformation"/>
    <xs:element minOccurs="0" name="rawFaultInformation" type="woksearch:RawFaultInformation"/>    
</xs:sequence>
</xs:complexType>

<xs:element name="AuthenticationException" type="woksearch:AuthenticationException">
    <xsd:annotation>
      <xsd:documentation>
      The AuthenticationException indicates that there is a problem with the authentication credentials associated with the 
      SOAP request message for the requested operation. 
      </xsd:documentation>
    </xsd:annotation>
</xs:element>

<xs:complexType name="AuthenticationException">
    <xsd:annotation>
      <xsd:documentation>
      In version 2, the faultInformation and rawFaultInformation elements did not exist. It is not required that the service return 
      these elements. 
      </xsd:documentation>
    </xsd:annotation>
<xs:sequence>
    <xs:element minOccurs="0" name="faultInformation" type="woksearch:FaultInformation"/>
    <xs:element minOccurs="0" name="rawFaultInformation" type="woksearch:RawFaultInformation"/>     
</xs:sequence>
</xs:complexType>

<xs:element name="InvalidInputException" type="woksearch:InvalidInputException">
    <xsd:annotation>
      <xsd:documentation>
      The InvalidInputException indicates that format of the SOAP request message is valid XML and that it satisfies the WSDL but 
      that the content, or values found in one or more XML elements, of the 
      SOAP request message for the requested operation is invalid. 
      </xsd:documentation>
    </xsd:annotation>
</xs:element>

<xs:complexType name="InvalidInputException">
    <xsd:annotation>
      <xsd:documentation>
      In version 2, the faultInformation and rawFaultInformation elements did not exist. It is not required that the service return 
      these elements. 
      </xsd:documentation>
    </xsd:annotation>
<xs:sequence>
    <xs:element minOccurs="0" name="faultInformation" type="woksearch:FaultInformation"/>
    <xs:element minOccurs="0" name="rawFaultInformation" type="woksearch:RawFaultInformation"/>     
</xs:sequence>
</xs:complexType>

<xs:element name="ESTIWSException" type="woksearch:ESTIWSException">
    <xsd:annotation>
      <xsd:documentation>
      The ESTIWSException indicates that an exception occurred within this Web service while processing the incoming SOAP request message.
      </xsd:documentation>
    </xsd:annotation>
</xs:element>

<xs:complexType name="ESTIWSException">
    <xsd:annotation>
      <xsd:documentation>
      In version 2, the faultInformation and rawFaultInformation elements did not exist. It is not required that the service return 
      these elements. 
      </xsd:documentation>
    </xsd:annotation>
<xs:sequence>
    <xs:element minOccurs="0" name="faultInformation" type="woksearch:FaultInformation"/>
    <xs:element minOccurs="0" name="rawFaultInformation" type="woksearch:RawFaultInformation"/>     
</xs:sequence>
</xs:complexType>

<xs:element name="InternalServerException" type="woksearch:InternalServerException">
    <xsd:annotation>
      <xsd:documentation>
      The InternalServerException indicates that a supporting Web service encountered an problem while processing the request and 
      returned a general exception message.
      </xsd:documentation>
    </xsd:annotation>
</xs:element>

<xs:complexType name="InternalServerException">
    <xsd:annotation>
      <xsd:documentation>
      In version 2, the faultInformation and rawFaultInformation elements did not exist. It is not required that the service return 
      these elements. 
      </xsd:documentation>
    </xsd:annotation>
<xs:sequence>
    <xs:element minOccurs="0" name="faultInformation" type="woksearch:FaultInformation"/>
    <xs:element minOccurs="0" name="rawFaultInformation" type="woksearch:RawFaultInformation"/>     
</xs:sequence>
</xs:complexType>

<xs:element name="SessionException" type="woksearch:SessionException">
    <xsd:annotation>
      <xsd:documentation>
      The SessionException indicates that there is a problem with the session identifier associated with the incoming SOAP request message.
      </xsd:documentation>
    </xsd:annotation>
</xs:element>

<xs:complexType name="SessionException">
    <xsd:annotation>
      <xsd:documentation>
      In version 2, the faultInformation and rawFaultInformation elements did not exist. It is not required that the service return 
      these elements. 
      </xsd:documentation>
    </xsd:annotation>
<xs:sequence>
    <xs:element minOccurs="0" name="faultInformation" type="woksearch:FaultInformation"/>
    <xs:element minOccurs="0" name="rawFaultInformation" type="woksearch:RawFaultInformation"/>     
</xs:sequence>
</xs:complexType>

</xs:schema>
  </wsdl:types>
  <wsdl:message name="relatedRecordsResponse">
    <wsdl:part element="woksearch:relatedRecordsResponse" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="relatedRecords">
    <wsdl:part element="woksearch:relatedRecords" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="retrieveById">
    <wsdl:part element="woksearch:retrieveById" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="retrieveResponse">
    <wsdl:part element="woksearch:retrieveResponse" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="retrieve">
    <wsdl:part element="woksearch:retrieve" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="searchResponse">
    <wsdl:part element="woksearch:searchResponse" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="citingArticlesResponse">
    <wsdl:part element="woksearch:citingArticlesResponse" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="retrieveByIdResponse">
    <wsdl:part element="woksearch:retrieveByIdResponse" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="search">
    <wsdl:part element="woksearch:search" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="QueryException">
    <wsdl:part element="woksearch:QueryException" name="QueryException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="citingArticles">
    <wsdl:part element="woksearch:citingArticles" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="citedReferences">
    <wsdl:part element="woksearch:citedReferences" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="citedReferencesRetrieve">
    <wsdl:part element="woksearch:citedReferencesRetrieve" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="ESTIWSException">
    <wsdl:part element="woksearch:ESTIWSException" name="ESTIWSException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="citedReferencesRetrieveResponse">
    <wsdl:part element="woksearch:citedReferencesRetrieveResponse" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="SessionException">
    <wsdl:part element="woksearch:SessionException" name="SessionException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="InternalServerException">
    <wsdl:part element="woksearch:InternalServerException" name="InternalServerException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="citedReferencesResponse">
    <wsdl:part element="woksearch:citedReferencesResponse" name="parameters">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="AuthenticationException">
    <wsdl:part element="woksearch:AuthenticationException" name="AuthenticationException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="InvalidInputException">
    <wsdl:part element="woksearch:InvalidInputException" name="InvalidInputException">
    </wsdl:part>
  </wsdl:message>
  <wsdl:portType name="WokSearch">
    <wsdl:operation name="citedReferencesRetrieve">
      <wsdl:input message="woksearch:citedReferencesRetrieve" name="citedReferencesRetrieve">
    </wsdl:input>
      <wsdl:output message="woksearch:citedReferencesRetrieveResponse" name="citedReferencesRetrieveResponse">
    </wsdl:output>
      <wsdl:fault message="woksearch:InvalidInputException" name="InvalidInputException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:QueryException" name="QueryException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:AuthenticationException" name="AuthenticationException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:InternalServerException" name="InternalServerException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:SessionException" name="SessionException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:ESTIWSException" name="ESTIWSException">
    </wsdl:fault>
    </wsdl:operation>
    <wsdl:operation name="relatedRecords">
      <wsdl:input message="woksearch:relatedRecords" name="relatedRecords">
    </wsdl:input>
      <wsdl:output message="woksearch:relatedRecordsResponse" name="relatedRecordsResponse">
    </wsdl:output>
      <wsdl:fault message="woksearch:InvalidInputException" name="InvalidInputException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:QueryException" name="QueryException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:AuthenticationException" name="AuthenticationException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:InternalServerException" name="InternalServerException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:SessionException" name="SessionException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:ESTIWSException" name="ESTIWSException">
    </wsdl:fault>
    </wsdl:operation>
    <wsdl:operation name="citedReferences">
      <wsdl:input message="woksearch:citedReferences" name="citedReferences">
    </wsdl:input>
      <wsdl:output message="woksearch:citedReferencesResponse" name="citedReferencesResponse">
    </wsdl:output>
      <wsdl:fault message="woksearch:InvalidInputException" name="InvalidInputException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:QueryException" name="QueryException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:AuthenticationException" name="AuthenticationException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:InternalServerException" name="InternalServerException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:SessionException" name="SessionException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:ESTIWSException" name="ESTIWSException">
    </wsdl:fault>
    </wsdl:operation>
    <wsdl:operation name="retrieve">
      <wsdl:input message="woksearch:retrieve" name="retrieve">
    </wsdl:input>
      <wsdl:output message="woksearch:retrieveResponse" name="retrieveResponse">
    </wsdl:output>
      <wsdl:fault message="woksearch:InvalidInputException" name="InvalidInputException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:QueryException" name="QueryException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:AuthenticationException" name="AuthenticationException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:InternalServerException" name="InternalServerException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:SessionException" name="SessionException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:ESTIWSException" name="ESTIWSException">
    </wsdl:fault>
    </wsdl:operation>
    <wsdl:operation name="search">
      <wsdl:input message="woksearch:search" name="search">
    </wsdl:input>
      <wsdl:output message="woksearch:searchResponse" name="searchResponse">
    </wsdl:output>
      <wsdl:fault message="woksearch:InvalidInputException" name="InvalidInputException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:QueryException" name="QueryException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:AuthenticationException" name="AuthenticationException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:InternalServerException" name="InternalServerException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:SessionException" name="SessionException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:ESTIWSException" name="ESTIWSException">
    </wsdl:fault>
    </wsdl:operation>
    <wsdl:operation name="citingArticles">
      <wsdl:input message="woksearch:citingArticles" name="citingArticles">
    </wsdl:input>
      <wsdl:output message="woksearch:citingArticlesResponse" name="citingArticlesResponse">
    </wsdl:output>
      <wsdl:fault message="woksearch:InvalidInputException" name="InvalidInputException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:QueryException" name="QueryException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:AuthenticationException" name="AuthenticationException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:InternalServerException" name="InternalServerException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:SessionException" name="SessionException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:ESTIWSException" name="ESTIWSException">
    </wsdl:fault>
    </wsdl:operation>
    <wsdl:operation name="retrieveById">
      <wsdl:input message="woksearch:retrieveById" name="retrieveById">
    </wsdl:input>
      <wsdl:output message="woksearch:retrieveByIdResponse" name="retrieveByIdResponse">
    </wsdl:output>
      <wsdl:fault message="woksearch:InvalidInputException" name="InvalidInputException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:QueryException" name="QueryException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:AuthenticationException" name="AuthenticationException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:InternalServerException" name="InternalServerException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:SessionException" name="SessionException">
    </wsdl:fault>
      <wsdl:fault message="woksearch:ESTIWSException" name="ESTIWSException">
    </wsdl:fault>
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:binding name="WokSearchServiceSoapBinding" type="woksearch:WokSearch">
    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
    <wsdl:operation name="citedReferencesRetrieve">
      <soap:operation soapAction="" style="document"/>
      <wsdl:input name="citedReferencesRetrieve">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="citedReferencesRetrieveResponse">
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
    <wsdl:operation name="relatedRecords">
      <soap:operation soapAction="" style="document"/>
      <wsdl:input name="relatedRecords">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="relatedRecordsResponse">
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
    <wsdl:operation name="citedReferences">
      <soap:operation soapAction="" style="document"/>
      <wsdl:input name="citedReferences">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="citedReferencesResponse">
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
    <wsdl:operation name="retrieve">
      <soap:operation soapAction="" style="document"/>
      <wsdl:input name="retrieve">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="retrieveResponse">
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
    <wsdl:operation name="search">
      <soap:operation soapAction="" style="document"/>
      <wsdl:input name="search">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="searchResponse">
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
    <wsdl:operation name="citingArticles">
      <soap:operation soapAction="" style="document"/>
      <wsdl:input name="citingArticles">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="citingArticlesResponse">
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
    <wsdl:operation name="retrieveById">
      <soap:operation soapAction="" style="document"/>
      <wsdl:input name="retrieveById">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="retrieveByIdResponse">
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
  <wsdl:service name="WokSearchService">
    <wsdl:port binding="woksearch:WokSearchServiceSoapBinding" name="WokSearchPort">
      <soap:address location="http://search.webofknowledge.com/esti/wokmws/ws/WokSearch"/>
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>
