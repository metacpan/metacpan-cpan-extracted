package AI::Categorizer::Collection::InMemory;
use strict;

use AI::Categorizer::Collection;
use base qw(AI::Categorizer::Collection);

use Params::Validate qw(:types);

__PACKAGE__->valid_params
  (
   data => { type => HASHREF },
  );

sub new {
  my $self = shift()->SUPER::new(@_);
  
  while (my ($name, $params) = each %{$self->{data}}) {
    foreach (@{$params->{categories}}) {
      next if ref $_;
      $_ = AI::Categorizer::Category->by_name(name => $_);
    }
  }

  return $self;
}

sub next {
  my $self = shift;
  my ($name, $params) = each %{$self->{data}} or return;
  return AI::Categorizer::Document->new(name => $name, %$params);
}

sub rewind {
  my $self = shift;
  scalar keys %{$self->{data}};
  return;
}

sub count_documents {
  my $self = shift;
  return scalar keys %{$self->{data}};
}

1;
