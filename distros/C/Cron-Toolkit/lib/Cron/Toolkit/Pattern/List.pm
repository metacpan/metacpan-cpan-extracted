package Cron::Toolkit::Pattern::List;
use strict;
use warnings;
use parent 'Cron::Toolkit::Pattern';

sub type {
   return 'list';
}

sub match {
    my ($self, $value, $tm) = @_;
    return scalar (grep { $_->match($value, $tm) } @{ $self->{children} }) ? 1 : 0;
}

sub to_english {
   my ($self) = @_;
   my @items = map { $_->to_english } @{ $self->{children} };
   return join(', ', @items);
}

1;
