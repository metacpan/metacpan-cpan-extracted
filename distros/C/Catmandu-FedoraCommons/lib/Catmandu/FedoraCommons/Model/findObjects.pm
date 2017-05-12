=head1 NAME

Catmandu::FedoraCommons::Model::findObjects - Perl model for the Fedora 'findObjects' and 'resumeFindObjects' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->findObjects(terms=>'*')->parse_content;
  
  {
    'token'  => '92b0ae4028f9459ce7cd0600f562adb2' ,
    'cursor' => 0,
    'expirationDate' => '2013-02-08T09:37:55.860Z',
    'results' => [
        {
        'pid'     => 'demo:29' ,
        'label'   => 'Data Object for Image Manipulation Demo' ,
        'state'   => 'I' ,
        'ownerId' => 'fedoraAdmin' ,
        'cDate'   => '2008-07-02T05:09:42.015Z' ,
        'mDate'   => '2013-02-07T19:57:27.140Z' ,
        'dcmDate' => '2008-07-02T05:09:43.234Z' ,
        'title'   => [ 'Coliseum in Rome' ] ,
        'creator' => [ 'Thornton Staples' ] ,
        'subject' => [ 'Architecture, Roman' ] ,
        'description' => [ 'Image of Coliseum in Rome' ] ,
        'publisher'   => [ 'University of Virginia Library' ] ,
        'format'      => [ 'image/jpeg' ] ,
        'identifier'  => [ 'demo:29' ],
        },
    ] ,
  }
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::findObjects;

use XML::LibXML;

our %SCALAR_TYPES = (pid => 1 , label => 1 , state => 1 , ownerId => 1 , cDate => 1 , mDate => 1 , dcmDate => 1);

sub parse {
    my ($class,$xml) = @_;
    my $dom  = XML::LibXML->load_xml(string => $xml);
    $dom->getDocumentElement()->setNamespace('http://www.fedora.info/definitions/1/0/types/','t');

    my $result = { results => [] };

    my @nodes;
    
    @nodes = $dom->findnodes("/t:result/t:listSession/*");

    for my $node (@nodes) {
        my $name  = $node->nodeName;
        my $value = $node->textContent;
        $result->{$name} = $value;
    }

    @nodes = $dom->findnodes("/t:result/t:resultList/t:objectFields");

    for my $node (@nodes) {
        my @vals  = $node->findnodes("./*");
        my $rec   = {};
        foreach my $val (@vals) {
            my $name  = $val->nodeName;
            my $value = $val->textContent;
            
            if (exists $SCALAR_TYPES{$name}) {
                $rec->{$name} = $value;
            }
            else {
                push @{ $rec->{$name} } , $value;
            }
        }
   
        push @{$result->{results}}, $rec;
    }

    return $result;
}

1;
