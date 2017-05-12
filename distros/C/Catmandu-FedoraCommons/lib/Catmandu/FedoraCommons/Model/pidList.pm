=head1 NAME

Catmandu::FedoraCommons::Model::pidList - Perl model for the Fedora 'getNextPID' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->getNextPID()->parse_content;
  
  [
    'changeme:102'
  ]
  
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::pidList;

use XML::LibXML;

sub parse {
    my ($class,$xml) = @_;
    my $dom  = XML::LibXML->load_xml(string => $xml);
    $dom->getDocumentElement()->setNamespace('http://www.fedora.info/definitions/1/0/management/','m');

    my @nodes = $dom->findnodes("/m:pidList/m:pid");
    
    my $result;
    
    foreach my $node (@nodes) {
        my $value = $node->textContent;
        push @$result , $value;
    }
    
    return $result;
}

1;