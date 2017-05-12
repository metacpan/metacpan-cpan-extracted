=head1 NAME

Catmandu::FedoraCommons::Model::ingest - Perl model for the Fedora 'ingest' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->ingest(pid => 'demo:40', file => 't/obj_demo_40.zip', format => 'info:fedora/fedora-system:ATOMZip-1.1')->parse_content;
  
  {
    'pid' => 'demo:40'
  }
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::ingest;

sub parse {
    my ($class,$bytes) = @_;
    return { pid => $bytes };
}

1;