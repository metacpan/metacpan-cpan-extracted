package DNS::Oterica::NodeFamily::ExampleArchiver;
use Moose;
extends 'DNS::Oterica::NodeFamily';

sub name { 'com.example.archiver' }

augment as_data_lines => sub {
  my ($self) = @_;
  my @lines;

  for my $node ($self->nodes) {
    push @lines, $self->rec->mx({
      name => 'archive.example.com',
      mx   => $node->fqdn,
      node => $node,
    });

    for my $name (qw/www.archives.example.com archive.example.com/) {
      push @lines, $self->rec->a({
        name => $name,
        node => $node,
      });
    }
  }

  return @lines;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;
