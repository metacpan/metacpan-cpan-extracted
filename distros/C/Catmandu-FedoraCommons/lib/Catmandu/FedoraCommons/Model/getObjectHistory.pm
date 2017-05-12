=head1 NAME

Catmandu::FedoraCommons::Model::getObjectHistory - Perl model for the Fedora 'getObjectHistory'  REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->getObjectHistory(pid => 'demo:29')->parse_content;
  
  {
    'pid'     => 'demo:29' ,
    'objectChangeDate' => [
        '2008-07-02T05:09:43.234Z' ,
        '2013-02-07T18:42:24.672Z' ,
    ] ,
  }
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::getObjectHistory;

use XML::LibXML;

sub parse {
    my ($class,$xml) = @_;
    my $dom  = XML::LibXML->load_xml(string => $xml);
    $dom->getDocumentElement()->setNamespace('http://www.fedora.info/definitions/1/0/access/','a');

    my $result = {};

    my @nodes = $dom->findnodes("/a:fedoraObjectHistory/*");

    for my $node (@nodes) {
        my $name  = $node->nodeName;
        my $value = $node->textContent;
        push @{ $result->{$name} } , $value;    
     }
     
     my $pid = $dom->firstChild()->getAttribute('pid');
     $result->{pid} = $pid;
     
     return $result;
}

1;