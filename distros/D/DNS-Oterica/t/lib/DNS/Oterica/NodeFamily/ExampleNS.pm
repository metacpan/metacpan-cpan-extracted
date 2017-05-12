package DNS::Oterica::NodeFamily::ExampleNS;
use Moose;
extends 'DNS::Oterica::NodeFamily';

sub name { 'com.example.ns' }

has ns_nodes => (
  is  => 'ro',
  isa => 'HashRef',
  default    => sub { {} },
);

after add_node => sub {
  my ($self, $node) = @_;
  my $nodes = $self->ns_nodes;
  my $i = keys %$nodes;
  
  my $next_name = sprintf 'ns%s.example.com', $i+1;

  $self->ns_nodes->{ $next_name } = $node;
};

augment as_data_lines => sub {
  my ($self) = @_;
  my @lines;

  my $ns = $self->ns_nodes;
  for my $name (sort keys %$ns) {
    push @lines, $self->rec->a({
      name => $name,
      node => $ns->{$name},
    });
    push @lines, $self->rec->a({
      name => 'mydns.ns.example.com',
      node => $ns->{$name},
    });
  }

  return @lines;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;
