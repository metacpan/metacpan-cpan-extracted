package Catmandu::WoS::SearchRecords;

use Catmandu::Sane;

our $VERSION = '0.0302';

use Moo::Role;
use Catmandu::Util qw(xml_escape);
use XML::LibXML::Simple qw(XMLin);
use namespace::clean;

with 'Catmandu::WoS::SearchBase';

sub _retrieve_content {
    my ($self, $query_id, $start, $limit) = @_;

    $query_id = xml_escape($query_id);

    <<EOF;
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
  <ns2:retrieve xmlns:ns2="http://woksearch.v3.wokmws.thomsonreuters.com">
    <queryId>$query_id</queryId>
    <retrieveParameters>
       <firstRecord>$start</firstRecord>
       <count>$limit</count>
    </retrieveParameters>
  </ns2:retrieve>
</soap:Body>
</soap:Envelope>
EOF
}

sub _retrieve_response_type {
    'retrieveResponse';
}

sub _find_records {
    my ($self, $xpc, $response_type) = @_;

    my $xml = $xpc->findvalue(
        "/soap:Envelope/soap:Body/ns2:$response_type/return/records");
    XMLin($xml, ForceArray => 1)->{REC};
}

1;
