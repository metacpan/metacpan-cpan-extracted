=head1 NAME

Catmandu::FedoraCommons::Model::validate - Perl model for the Fedora 'validate' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->validate(pid => 'demo:29')->parse_content;
  
  {
    'pid'   => 'demo:29' ,
    'valid' => 'false' ,
    'asOfDateTime' => '2013-02-08T10:09:09.273Z' ,
    'model' => [
       'info:fedora/demo:UVA_STD_IMAGE' ,
       'info:fedora/fedora-system:FedoraObject-3.0' ,
    ],
    'problem' => [
       'test'
    ] ,
    'datastream' => [
        {
         'dsID' => 'url' ,
         'problem' => [
            "Datastream 'url' is does not have the FORMAT_URI and MIME_TYPE attributes required by 'demo:UVA_STD_IMAGE'" ,
         ]
        }
    ] ,
  }
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::validate;

use XML::LibXML;

sub parse {
    my ($class,$xml) = @_;
    my $dom  = XML::LibXML->load_xml(string => $xml);
    $dom->getDocumentElement()->setNamespace('http://www.fedora.info/definitions/1/0/management/','m');

    my $result;
  
    $result->{asOfDateTime} = $dom->findnodes("/m:validation/m:asOfDateTime")->[0]->textContent;
    
    my @nodes;
    
    @nodes = $dom->findnodes("/m:validation/m:contentModels/m:model");
    
    for my $node (@nodes) {
        my $value = $node->textContent;
        
        push @{$result->{model}} , $value;
    }
    
    @nodes = $dom->findnodes("/m:validation/m:datastreamProblems/m:datastream");
    
    for my $node (@nodes) {
        my $dsID  = $node->getAttribute('datastreamID');
        my $value = $node->textContent;
        my $datastream = { dsID => $dsID };
        
        my @subnodes = $node->findnodes("./m:problem");
        for my $subnode (@subnodes) {
            my $value = $node->textContent;
            push @{$datastream->{problem}} , $value;
        }
        
        push @{$result->{datastream}} , $datastream;
    }
    
    @nodes = $dom->findnodes("/m:validation/m:problems/m:problem");
    
    for my $node (@nodes) {
        my $value = $node->textContent;
        
        push @{$result->{problem}} , $value;
    }
    
    my $pid = $dom->firstChild()->getAttribute('pid');
    $result->{pid} = $pid;

    my $valid = $dom->firstChild()->getAttribute('valid');
    $result->{valid} = $valid;
 
    return $result;
}

1;