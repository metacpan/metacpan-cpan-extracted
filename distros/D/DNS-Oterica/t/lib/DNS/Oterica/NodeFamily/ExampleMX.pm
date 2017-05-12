package DNS::Oterica::NodeFamily::ExampleMX;
use Moose;
extends 'DNS::Oterica::NodeFamily';

sub name { 'com.example.mx' }

has mx_nodes => (
  is  => 'ro',
  isa => 'HashRef',
  default    => sub { {} },
);

after add_node => sub {
  my ($self, $node) = @_;
  my $nodes = $self->mx_nodes;
  my $i = keys %$nodes;
  
  my $next_name = sprintf 'mx-%s.example.com', $i+1;

  $self->mx_nodes->{ $next_name } = $node;
};

augment as_data_lines => sub {
  my ($self) = @_;
  my @lines;

  my $mx = $self->mx_nodes;
  for my $mxname (sort keys %$mx) {
    push @lines, $self->rec->a({
      name => $mxname,
      node => $mx->{$mxname},
    });
  }
  return @lines;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;
