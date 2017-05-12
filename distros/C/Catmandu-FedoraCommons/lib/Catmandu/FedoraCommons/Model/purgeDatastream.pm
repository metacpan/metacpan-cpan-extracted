=head1 NAME

Catmandu::FedoraCommons::Model::purgeDatastream - Perl model for the Fedora 'purgeDatastream' REST call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $obj = $fedora->purgeDatastream(pid => 'demo:29', dsID => 'TEST')->parse_content;
  
  [
            '2013-02-08T10:18:21.019Z'
  ];
  
=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::purgeDatastream;

use JSON;

sub parse {
     my ($class,$bytes) = @_;
     return decode_json($bytes);
}

1;