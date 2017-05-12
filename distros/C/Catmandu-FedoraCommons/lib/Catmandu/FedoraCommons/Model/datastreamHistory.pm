=head1 NAME

Catmandu::FedoraCommons::Model::datastreamHistory - Perl model for the Fedora 'getDatastreamHistory' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->getDatastreamHistory(pid => 'demo:29', dsID => 'DC')->parse_content;
  
  {
     'pid'  => 'demo:29' ,
     'dsID' => 'DC',
     'profile' => [
        {
        'dsLabel' => 'Dublin Core Record for this object' ,
        'dsVersionID' => 'DC1.0' ,
        'dsCreateDate' => '2008-07-02T05:09:43.234Z' ,
        'dsState' => 'A' ,
        'dsMIME' => 'text/xml' ,
        'dsFormatURI' => 'http://www.openarchives.org/OAI/2.0/oai_dc/' ,
        'dsControlGroup' => 'X' ,
        'dsSize' => 626,
        'dsVersionable' => 'true' ,
        'dsInfoType' => '' ,
        'dsLocation' => 'demo:29+DC+DC1.0' ,
        'dsLocationType' => '' ,
        'dsChecksumType' => 'DISABLED' ,
        'dsChecksum' => 'none' ,
        }
     ]
  }
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::datastreamHistory;

use XML::LibXML;

sub parse {
    my ($class,$xml) = @_;
    my $dom  = XML::LibXML->load_xml(string => $xml);
    $dom->getDocumentElement()->setNamespace('http://www.fedora.info/definitions/1/0/management/','m');

    my @nodes = $dom->findnodes("/m:datastreamHistory/m:datastreamProfile");

    my $result;
     
    for my $node (@nodes) {
        my @sub_nodes = $node->findnodes("./*");
    
        my $profile;
    
        for my $sub_node (@sub_nodes) {
            my $name  = $sub_node->nodeName;
            my $value = $sub_node->textContent;
        
            $profile->{$name} = $value;
        }
                
        push  @{ $result->{profile} }, $profile;
    }
    
    my $pid = $dom->firstChild()->getAttribute('pid');
    $result->{pid} = $pid;

    my $dsID = $dom->firstChild()->getAttribute('dsID');
    $result->{dsID} = $dsID;

    return $result;
}

1;