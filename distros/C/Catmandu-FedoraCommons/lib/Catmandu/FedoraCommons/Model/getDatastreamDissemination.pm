=head1 NAME

Catmandu::FedoraCommons::Model::getDatastreamDissemination - Perl model for the Fedora 'getDatastreamDissemination' or 'getDissemination' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->purgeDatastream(pid => 'demo:29', dsID => 'TEST')->parse_content;
  
  Returns the bytes returned.
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::getDatastreamDissemination;

sub parse {
     my ($class,$bytes) = @_;
     return $bytes;
}

1;