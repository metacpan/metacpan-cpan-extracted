package Example::View::TestSubs;

use Moose;
extends 'Catalyst::View::EmbeddedPerl::PerRequest';

has 'name' => (is => 'ro', isa => 'Str', default => 'world');

sub wrap {
  my ($self, $content_cb) = @_;
  my $content = $content_cb->();
  return "....@{[ $self->trim($content_cb->()) ]}....";
}

__PACKAGE__->meta->make_immutable;
