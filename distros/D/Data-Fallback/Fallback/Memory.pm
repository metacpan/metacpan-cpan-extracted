#!/usr/bin/perl -w

# set session - item
# set session - content

# set - item
# set - content

package Data::Fallback::Memory;

use strict;

use Data::Fallback;
use vars qw(@ISA);
@ISA = qw(Data::Fallback);

sub get_memory_cache_key {
  my $self = shift;
  return $self->get_cache_key('primary_key') . "-" . $self->{item};
}

sub _GET {
  my $self = shift;
  my $return = 0;
  my ($found_in_cache, $content) = 
    $self->check_cache('Memory', 'item', $self->get_memory_cache_key);

  if($found_in_cache) {
    # already set in $content, so we're done
    $self->{update}{item} = $content;
    $return = 1;
  }
  return $return;
}

sub SET_ITEM {
  my $self = shift;
  my ($key, $value) = ($self->get_memory_cache_key, $self->{update}{item});
  die "need a \$self->{list_name}" unless( (defined $self->{list_name}) && length $self->{list_name});
  die "need a \$key" unless( (defined $key) && length $key);
  die "need a \$value" unless( (defined $value) && length $value);

  return $self->set_cache('Memory', 'item', $key, $value);
}

sub SET_GROUP {
  my $self = shift;

  # can't really set a group in Memory, since the content name is different
  # at each driver level

  return 1;
}

1;
