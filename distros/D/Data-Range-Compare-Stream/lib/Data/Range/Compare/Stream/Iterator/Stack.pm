package Data::Range::Compare::Stream::Iterator::Stack;

use strict;
use warnings;
use base qw(Data::Range::Compare::Stream::Iterator::Base);

sub new {
  my ($class,%args)=@_;
  my $self=$class->SUPER::new(stack=>[],%args);
}

sub stack_push {
  my ($self,$it)=@_;
  push @{$self->{stack}},$it;
}

sub has_next {
  my ($self)=@_;
  my $stack=$self->{stack};
  while($#$stack!=-1) {
    return 1 if $stack->[0]->has_next;
    shift @$stack;
  }
  return 0;
}

sub get_next { $_[0]->{stack}->[0]->get_next }


1;
