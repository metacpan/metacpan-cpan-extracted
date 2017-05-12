package DNS::Oterica::NodeFamily::ExampleDomain;
use Moose;
extends 'DNS::Oterica::NodeFamily';

sub name { 'com.example.domain' }

augment as_data_lines => sub {
  my ($self) = @_;
  my @lines;

  my $ns_nodes = $self->hub->node_family('com.example.ns')->ns_nodes;

  for my $node ($self->nodes) {
    push @lines, $self->rec->soa_and_ns({
      domain => $node->fqdn,
      ns     => 'ns.example.com',
      node   => $node,
    });
    for my $ns (keys %$ns_nodes) {
      push @lines, $self->rec->domain({
        domain => $node->fqdn,
        ns     => $ns,
      });
    }
  }

  return @lines;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;
