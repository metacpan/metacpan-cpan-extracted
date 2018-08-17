package Babble::PluginChain;

use Babble::Grammar;
use Module::Runtime qw(use_module);
use Mu;

lazy plugins => sub { [] };
lazy grammar => sub { Babble::Grammar->new };

sub add_plugin {
  my ($self, $plugin) = @_;
  $plugin =~ s/^::/Babble::Plugin::/;
  my $p = use_module($plugin)->new;
  $p->extend_grammar($self->grammar) if $p->can('extend_grammar');
  push @{$self->plugins}, $p;
  return $self;
}

sub transform_document {
  my ($self, $document) = @_;
  my $top = $self->grammar->match(Document => $document);
  $_->transform_to_plain($top) for @{$self->plugins};
  return $top->text;
}

1;
