=head1 NAME

Catmandu::FedoraCommons::Model::listDatastreams - Perl model for the Fedora 'listDatastreams'  REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->listDatastreams(pid => 'demo:29')->parse_content;
  
  {
    'pid'     => 'demo:29' ,
    'baseURL' => 'http://localhost:8080/fedora/' ,
    'datastream' => [
        {
          'dsid'  => 'DC' ,
          'label' => 'Dublin Core Record for this object' ,
          'mimeType' => 'text/xml' ,
        }, 
        {
          'dsid'  => 'RELS-EXT' ,
          'label' => 'RDF Statements about this object' ,
          'mimeType' => 'application/rdf+xml' ,
        },
        {
          'dsid'  => 'url' ,
          'label' => 'Thorny\'s Coliseum high jpg image' ,
          'mimeType' => 'text/xml' ,
        },
    ] ,
  }
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::listDatastreams;

use XML::LibXML;

sub parse {
    my ($class,$xml) = @_;
    my $dom  = XML::LibXML->load_xml(string => $xml);
    $dom->getDocumentElement()->setNamespace('http://www.fedora.info/definitions/1/0/access/','a');

    my @nodes = $dom->findnodes("/a:objectDatastreams/*");
    
    my $result;
    
    foreach my $node (@nodes) {
        my @attributes = $node->attributes();
        my %values = map { $_->getName() , $_->getValue() } @attributes;
        push @{ $result->{datastream} }, \%values;
    }
    
    my $pid = $dom->firstChild()->getAttribute('pid');
    $result->{pid} = $pid;

    my $baseURL = $dom->firstChild()->getAttribute('baseURL');
    $result->{baseURL} = $baseURL;
    
    return $result;
}

1;
