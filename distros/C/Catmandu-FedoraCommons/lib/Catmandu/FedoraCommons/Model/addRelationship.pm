=head1 NAME

Catmandu::FedoraCommons::Model::addRelationship - Perl model for the Fedora 'addRelationship' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->addRelationship(pid => 'demo:29' , relation => [ 'info:fedora/demo:29' , 'http://my.org/name' , 'Peter'])->parse_content;
  
  Returns 1 on success.
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::addRelationship;

sub parse {
    1;
}

1;