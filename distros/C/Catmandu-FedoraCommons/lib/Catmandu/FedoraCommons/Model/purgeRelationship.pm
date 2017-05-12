=head1 NAME

Catmandu::FedoraCommons::Model::purgeRelationship - Perl model for the Fedora 'purgeRelationship' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->purgeRelationship(pid => 'demo:29' , relation => [ 'info:fedora/demo:29' , 'http://my.org/name' , 'Peter'])->parse_content;
  
  {
    'purged' => 'upload://11'
  }
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::purgeRelationship;

sub parse {
    my ($class,$bytes) = @_;
    return { purged => $bytes };
}

1;