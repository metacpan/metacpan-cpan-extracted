=head1 NAME

Catmandu::FedoraCommons::Model::listMethods - Perl model for the Fedora 'listMethods'  REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->listMethods(pid => 'demo:29')->parse_content;
  
  {
    'pid'     => 'demo:29' ,
    'baseURL' => 'http://localhost:8080/fedora/' ,
    'sDef' => [
        {
            'pid' => 'demo:27',
            'method' => [
                {
                    'name' => 'resizeImage' ,
                    'methodParm' => [
                         {
                        'parmDefaultValue' => '150',
                        'parmLabel' => 'fix me',
                        'parmRequired' => 'true',
                        'parmName' => 'width'
                         }
                    ],
                },
             ]
        }
    ]
  }
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::listMethods;

use XML::LibXML;

sub parse {
    my ($class,$xml) = @_;
    my $dom  = XML::LibXML->load_xml(string => $xml);
    $dom->getDocumentElement()->setNamespace('http://www.fedora.info/definitions/1/0/access/','a');

    my @nodes = $dom->findnodes("/a:objectMethods/*");
    
    my $result;
    
    for my $node (@nodes) {
        my @attributes = $node->attributes();
        my %values = map { $_->getName() , $_->getValue() } @attributes;
        
        my $sDef = \%values;
        
        for my $method ($node->findnodes("./a:method")) {
            my $name = $method->getAttribute('name');
            my $m    = { name => $name };
            
            for my $param ($method->findnodes("./a:methodParm")) {
                my @attributes = $param->attributes();
                my %values = map { $_->getName() , $_->getValue() } @attributes;
                
                for my $domain ($param->findnodes("./a:methodParmDomain/a:methodParmValue")) {
                     my $value = $domain->textContent;
                     push @{ $values{methodParmValue}} , $value;
                }
                
                push @{ $m->{methodParm} } , \%values;
            }
            
            push @{ $sDef->{method} } , $m;
        } 
        
        push @{ $result->{sDef} }, $sDef;
    }
    
    my $pid = $dom->firstChild()->getAttribute('pid');
    $result->{pid} = $pid;

    my $baseURL = $dom->firstChild()->getAttribute('baseURL');
    $result->{baseURL} = $baseURL;
    
    return $result;
}

1;