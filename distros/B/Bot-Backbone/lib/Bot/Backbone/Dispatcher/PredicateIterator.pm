package Bot::Backbone::Dispatcher::PredicateIterator;
$Bot::Backbone::Dispatcher::PredicateIterator::VERSION = '0.161950';
use v5.10;
use Moose;

use Bot::Backbone::Types qw( PredicateList );

# ABSTRACT: Iterator over the predicates in a dispatcher


has dispatcher => (
    is          => 'ro',
    isa         => 'Bot::Backbone::Dispatcher',
    required    => 1,
);

has predicate_list => (
    is          => 'rw',
    isa         => PredicateList,
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        have_more_predicates     => 'count',
        next_from_predicate_list => 'shift',
        add_predicates           => 'push',
    },
);


sub BUILD {
    my $self = shift;
    $self->reset;
}


sub next_predicate {
    my $self = shift;

    return unless $self->have_more_predicates;

    my $predicate = $self->next_from_predicate_list;
    $self->add_predicates($predicate->more_predicates);

    return $predicate;
}


sub reset {
    my $self = shift;

    $self->predicate_list([
        $self->dispatcher->list_predicates,
        $self->dispatcher->list_also_predicates,
    ]);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Dispatcher::PredicateIterator - Iterator over the predicates in a dispatcher

=head1 VERSION

version 0.161950

=head1 SYNOPSIS

  my $iterator = $dispatcher->predicate_iterator;
  while (my $predicate = $iterator->next_predicate) {
      # do something...
  }

=head1 DESCRIPTION

This is a helper for iterating over predicates in a L<Bot::Backbone::Dispatcher>.

=head1 ATTRIBUTES

=head2 dispatcher

This is the dispatcher this iterator iterates over.

=head1 METHODS

=head2 BUILD

Resets the iterator to the start at construction.

=head2 next_predicate

Returns the next L<Bot::Backbone::Dispatcher::Predicate> or C<undef> if all predicates have been iterated through.

=head2 reset

Starts over by retriving the list of predicates that belong to the associated L<Bot::Backbone::Dispatcher>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
