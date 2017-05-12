package AI::Categorizer::ObjectSet;
use strict;

sub new {
  my $pkg = shift;
  my $self = bless {}, $pkg;
  $self->insert(@_) if @_;
  return $self;
}

sub members {
  return values %{$_[0]};
}

sub size {
  return scalar keys %{$_[0]};
}

sub insert {
  my $self = shift;
  foreach my $element (@_) {
    #warn "types are ", @_;
    $self->{ $element->name } = $element;
  }
}

sub retrieve { $_[0]->{$_[1]} }

sub includes { exists $_[0]->{ $_[1]->name } }
sub includes_name  { exists $_[0]->{ $_[1] } }

1;
