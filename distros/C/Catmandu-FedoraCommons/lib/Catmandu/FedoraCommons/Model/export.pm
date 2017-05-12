=head1 NAME

Catmandu::FedoraCommons::Model::export - Perl model for the Fedora 'export' and 'getObjectXML' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->export(pid => 'demo:29')->parse_content;
  
  {
     'pid'  => 'demo:29' ,
     'version' => '1.1',
     'objectProperties' => {
         'state' => 'Inactive' ,
         'label' => 'Data Object for Image Manipulation Demo' ,
         'ownerId' => 'fedoraAdmin' ,
         'createdDate' => '2008-07-02T05:09:42.015Z' ,
         'lastModifiedDate' => '2013-02-07T19:57:27.140Z' ,
     },
     'auditTrail' => [
         {
         'id' => 'AUDREC1' ,
         'process' => 'Fedora API-M' ,
         'action' => 'addDatastream' ,
         'componentID' => 'TEST' ,
         'responsibility' => 'fedoraAdmin' ,
         'date' => '2013-02-07T18:42:24.518Z' ,
         'justification' => '' ,
         },
     ],
     'dc' => {
         'title'   => [ 'Coliseum in Rome' ] ,
         'creator' => [ 'Thornton Staples' ] ,
         'subject' => [ 'Architecture, Roman' ] ,
         'description' => [ 'Image of Coliseum in Rome' ] ,
         'publisher'   => [ 'University of Virginia Library' ] ,
         'format'      => [ 'image/jpeg' ] ,
         'identifier'  => [ 'demo:29' ],
     },
  }
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::export;

use XML::LibXML;

sub parse {
    my ($class,$xml) = @_;
    my $dom  = XML::LibXML->load_xml(string => $xml);
    $dom->getDocumentElement()->setNamespace('info:fedora/fedora-system:def/foxml#','foxml');
    
    my $xc = XML::LibXML::XPathContext->new( $dom );
    $xc->registerNs('audit', 'info:fedora/fedora-system:def/audit#');
    $xc->registerNs('oai_dc','http://www.openarchives.org/OAI/2.0/oai_dc/');
    $xc->registerNs('dc','http://purl.org/dc/elements/1.1/');
    
    my @nodes;
    
    @nodes = $xc->findnodes("/foxml:digitalObject/foxml:objectProperties//foxml:property");
    
    my $result;
    
    for my $node (@nodes) {
        my $name  = $node->getAttribute('NAME');
        my $value = $node->getAttribute('VALUE');
        
        $name =~ s{.*#}{};
            
        $result->{objectProperties}->{$name} = $value;
    }
    
    @nodes = $xc->findnodes("//audit:auditTrail/audit:record");
    
    my @auditTrail = ();

    for my $node (@nodes) {
        my $id      = $node->findvalue('@ID');
        my $process = $node->findvalue('./audit:process/@type');
        my $action  = $node->findvalue('./audit:action');
        my $componentID    = $node->findvalue('./audit:componentID');
        my $responsibility = $node->findvalue('./audit:responsibility');
        my $date           = $node->findvalue('./audit:date');
        my $justification  = $node->findvalue('./audit:justification');
        
        push(@auditTrail , {
            id => $id ,
            process => $process ,
            action  => $action ,
            componentID => $componentID ,
            responsibility => $responsibility ,
            date => $date ,
            justification => $justification ,
       });
    }

    $result->{auditTrail} = \@auditTrail;
    
    @nodes = $xc->findnodes("//oai_dc:dc/*");
        
    for my $node (@nodes) {
        my $name  = $node->nodeName;
        my $value = $node->textContent;
        
        push @{ $result->{dc}->{$name} } , $value;
    }
    
    my $pid = $dom->firstChild()->getAttribute('PID');
    $result->{pid} = $pid;

    my $version = $dom->firstChild()->getAttribute('VERSION');
    $result->{version} = $version;

    
    return $result;
}

1;