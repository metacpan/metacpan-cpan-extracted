use strict;
use warnings;
package Array::Circular;
# ABSTRACT: Provide an array data structure that can go around in circles

use Carp;
use Scalar::Util qw/refaddr/;
use Storable qw/dclone/;

my %DATA;

sub new {
    my ($class, @self) = @_;
    my $self = bless \@self, $class;
    $self->me( { current => 0, count => 0 } ); 
    return $self;
}

sub clone {
    my ($self) = @_;
    my $class = ref $self;
    my $new = $class->new(@$self);
    $new->index($self->index);
    $new->loops($self->loops);
    return $new;
}

sub me {
    my ($self, $args) = @_;
    my $loc = refaddr $self;
    $DATA{$loc} = $args if $args;
    return $DATA{$loc};
}

sub current {
    my ($self) = @_;
    return $self->[ $self->me->{current} ];
}

*curr = \&current;

sub index {
    my ($self, $idx) = @_;
    $self->me->{current} = $idx if defined $idx;
    return $self->me->{current};
}

sub loops {
    my ($self, $new_ct) = @_;
    $self->me->{count} = $new_ct if defined $new_ct;
    return $self->me->{count};
}

sub next {
    my ($self, $num) = @_;
    return unless @$self;
    return $self->current if defined $num && $num == 0; # undefined just goes next.  zero gives current.
    if ($num) {
	croak "Calls to next with a count of how many to go forward must be a positive number" if $num < 0;
	$num--;
	$self->next for 1 .. $num; # This is inefficient but simple.  Could use $self->me to compute where we are as optimisation
    }


    my $last_index = $#{$self};
    if ( $self->me->{current} == $last_index ) {
	$self->me->{current} = -1;
	$self->me->{count}++;
    }
    return $self->[ ++ $self->me->{current} ];
}

sub previous {
    my ($self, $num) = @_;
    return unless @$self;

    if ($num) {
	croak "Calls to next with a count of how many to go forward must be a positive number" if $num < 0;
	$num--;
	$self->previous for 1 .. $num; # This is inefficient but simple.  Could use $self->me to compute where we are as optimisation
    }

    if ( $self->me->{current} == 0 ) {
	$self->me->{current} = scalar(@$self);
	$self->me->{count}--;

    }
    return $self->[ -- $self->me->{current} ];
}

*prev = \&previous;

sub reset {
    my ($self) = @_;
    $self->me->{current} = 0;
    $self->me->{count} = 0;
    return $self->current;
}

sub _current_and_action {
    my ($self, $action) = @_;
    my $c = $self->current;
    $self->$action;
    return $c
}

sub current_and_next {
    my ($self) = @_;
    return $self->_current_and_action('next');
}

*curr_and_next = \&current_and_next;

sub current_and_previous {
    my ($self) = @_;
    return $self->_current_and_action('previous');
}

*curr_and_prev = \&curr_and_prev;

sub peek {
    my ($self, $count) = @_;
    return $self->current if $count == 0;
    my $meth = $count > 0 ? 'next': 'prev';
    my $undo = $count > 0 ? 'prev': 'next';
    $count = abs $count;
    my $val = $self->$meth($count);
    $self->$undo($count);
    return $val;
}

sub size {
    my ($self ) = @_;
    return scalar @$self;
}



sub DESTROY {
    my $self = shift;
    delete $DATA{refaddr $self};
}

1;

__END__

=head1 NAME

Array::Circular - Provide an array data structure that can go around in circles.

=head2 DESCRIPTION

Circular array, tracks how many times it's been round.

=head2 SYNOPSIS

    my $a = Array::Circular->new(qw/once upon a time there was/);
    my $current = $l->next;
    say "They are the same" if $current == $l->current;
    my $first = $l->previous;
    say "Also the same" if $first == $l->current;
    say "We went around the loop " . $l->loops . " times";

=head2 METHODS

=head3 new

    my $a = Array::Circular->new(qw/this is a test/);

=head3 clone

    my $new = $a->clone;

=head3 next

    my $element     = $l->next;
    my $two_forward = $l->next(2);

=head3 previous / prev

    my $element = $l->previous;
    my $two_back = $l->previous(2);

=head3 current / curr

    my $element = $l->current;

=head3 index

    my $idx = $l->index;
    $idx    = $l->index(3);

Gets or sets the current index.  Always returns the value of the
current index.  Does not reset the loop counter.  No validation is
performed.

=head3 loops

    my $number_of_times_been_around = $l->loops
    $l->loops(-3);

The loops method keeps track of how many times the array has been
around. Looping forwards increases the loop count.  Looping back
decreases it.  Sending in a number will set the counter but beware, no
validation is performed on set operations.

=head3 reset

    $l->reset

Resets the current index and loop count to 0.  

=head4 me

    my $internal_store = $l->me

This is the internal store that tracks the current state of the list.
It's intended for internal use only.

=head4 current_and_next / curr_and_next

Convenience method to return current value then proceed next.  Same
interface as C<next>.

=head4 current_and_previous / curr_and_prev

Convenience method to return current value then proceed previous.  Same
interface as C<previous>.

=head4 peek

Peek n forward (defaults to 1).  Take care if you're reliant on calculating
the number of loops as part of this.  This Returns the entry for each
without updating the value of C<loops>.

=head4 size

Returns the number of elements in the list.

=head2 GOTCHAS

Some array modification operations are supported.  For example splice,
push and pop operations are untested.  If you mutate the array you may
consider using C<reset>, C<loops> and C<index> to fix up the effects
of your mutation.

=head2 IMPLEMENTATION NOTES

This module is implemented as an inside out object.

=head2 SEE ALSO

L<Array::Iterator::Circular> provides similar functionality but it
does not support C<previous>.  L<Array::Iterator> contains a survey of
various similar modules.

=head2 TODO

Not thread safe.  See implementation of L<Hash::MultiValue> for
implementation of thread safety.  Alternatively use
L<Hash::Util::FieldHash> or L<Hash::Util::FieldHash::Compat>.

=head2 AUTHOR COPYRIGHT AND LICENSE

Copyright 2018 Kieren Diment L<zarquon@cpan.org>.  This software can
be redistributed under the same terms as perl itself.

=cut
