package AnyEvent::Retry::Interval;
BEGIN {
  $AnyEvent::Retry::Interval::VERSION = '0.03';
}
# ABSTRACT: role representing a time sequence generator for C<AnyEvent::Retry>
use Moose::Role;

use true;
use namespace::autoclean;

with 'AnyEvent::Retry::Interval::API';

has 'counter' => (
    is      => 'bare', # has 'Moose' => ( is => 'bug ridden' );
    traits  => ['Counter'],
    reader  => 'counter',
    isa     => 'Num',
    lazy    => 1,
    default => 0,
    clearer => '_reset_counter',
    handles => { _inc_counter => 'inc' },
);

requires 'reset';
requires 'next';

before 'reset' => sub {
    my $self = shift;
    $self->_reset_counter;
};

around 'next' => sub {
    my ($orig, $self) = @_;
    $self->_inc_counter;
    my $counter = $self->counter;
    my $result  = $self->$orig($counter);
    return ($result, $self->counter) if wantarray;
    return $result;
};



=pod

=head1 NAME

AnyEvent::Retry::Interval - role representing a time sequence generator for C<AnyEvent::Retry>

=head1 VERSION

version 0.03

=head1 METHODS

=head1 reset

Reset the sequence generator to its initial state.

C<reset> accepts no arguments.

=head1 next

Return the next element in the sequence.  In scalar context, return
only the next element.  In list context, return a pair of the next
element and the number of times C<next> has been called since
C<reset>.

C<next> accepts no arguments.

=head1 IMPLEMENTING YOUR OWN INTERVAL CLASS

Consume this role.

Your C<next> method only needs to return the next value in the
sequence; the list context behavior is automatically added when you
consume this role.  It is automatically passed the counter as the only
argument, which is C<1> the first time after a reset.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

