=head1 NAME

Catmandu::FedoraCommons::Model::modifyObject - Perl model for the Fedora 'modifyObject' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->modifyObject(pid => 'demo:29' , state => 'I')->parse_content;
  
  {
    'date' => '2013-02-08T10:09:09.273Z'
  }
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::modifyObject;

sub parse {
    my ($class,$bytes) = @_;
    return { date => $bytes };
}

1;