package DNS::Oterica::NodeFamily::ExampleVDom;
use Moose;
extends 'DNS::Oterica::NodeFamily';

sub name { 'com.example.vdom' }

augment as_data_lines => sub {
  my ($self) = @_;
  my @lines;


  for my $node ($self->nodes) {
    push @lines, $self->rec->soa_and_ns({
      domain => $node->fqdn,
      ns     => 'ns.example.com',
      node   => $node,
    });
  }
  return @lines;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;
