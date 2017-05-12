=head1 NAME

Catmandu::FedoraCommons::Model::upload - Perl model for the Fedora 'upload' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->upload(file => 't/marc.xml')->parse_content;
  
  {
    'id' => 'upload://11'
  }
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::upload;

sub parse {
    my ($class,$bytes) = @_;
    return { id => $bytes };
}

1;