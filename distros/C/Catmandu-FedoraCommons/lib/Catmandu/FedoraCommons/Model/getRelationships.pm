=head1 NAME

Catmandu::FedoraCommons::Model::getRelationships - Perl model for the Fedora 'getRelationships'  REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->getRelationships(pid => 'demo:29')->parse_content;
  
  Returns a RDF::Trine::Model model
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>
L<RDF::Trine::Model>

=cut
package Catmandu::FedoraCommons::Model::getRelationships;

use RDF::Trine;

sub parse {
    my ($class,$xml) = @_;
    my $model  = RDF::Trine::Model->temporary_model; 
    my $parser = RDF::Trine::Parser->new('rdfxml');
    
    $parser->parse_into_model(undef,$xml,$model);
    
    return $model;
}

1;