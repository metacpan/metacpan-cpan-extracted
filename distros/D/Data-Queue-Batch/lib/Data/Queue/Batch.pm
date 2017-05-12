package Data::Queue::Batch;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

sub new {
    my ($class, %args) = @_;
    my $batch_size = delete($args{batch_size}) || 100;
    my $callback = delete($args{callback});
    return bless {
        callback => $callback,
        batch_size => $batch_size,,
        %args,
        available => 0,
        _queue => [],
    }, $class;
}

sub size       { scalar(@{ shift->{_queue} }) }
sub available  { shift->{available} }
sub batch_size { shift->{batch_size} }

sub push :method { shift->enqueue(@_) }
sub enqueue {
    my ($self, @values) = @_;
    push(@{ $self->{_queue} }, @values);

    my $unmarked = $self->size - $self->{available};
    my $marking = $unmarked - ($unmarked % $self->{batch_size});
    $self->{available} += $marking;
    
    if ($self->{callback} && $self->{available}) {
        $self->{callback}->($self->_take($self->{available}));
    }
    return;
}

sub shift :method { shift->dequeue(@_) }
sub dequeue {
    my ($self) = @_;
    return unless $self->{available};
    my ($dequeued) =  $self->_take(1);
    return $dequeued;
}

sub peek {
    my ($self, $count) = @_;
    $count = $self->{available} if $count > $self->{available};
    my @peeked =  @{$self->{_queue}}[0 .. $count - 1];
    return @peeked;
}

sub flush {
    my ($self) = @_;
    my @taken = $self->_take($self->size);
    if ($self->{callback} && @taken) {
        $self->{callback}->(@taken);
    }
    return @taken;
}

sub clear {
    my ($self) = @_;
    $self->_take($self->size);
    return;
}

sub _take {
    my ($self, $count) = @_;
    my @taken = splice(@{ $self->{_queue} }, 0, $count);
    $self->{available} -= $count;
    $self->{available} = 0 if $self->{available} < 0;
    return @taken;
}

sub DESTROY {
    my ($self) = @_;
    $self->flush if $self->{callback};
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Queue::Batch - FIFO data structure for "batching" items

=head1 SYNOPSIS

    use Data::Queue::Batch;

    # Callback interface
    {
        my @batched_items;
        my $q = Data::Queue::Batch->new(
            batch_size => 3,
            callback => sub {
                push(@batched_items, [@_]);
            },
        );

        $q->push(1, 2, 3, 4, 5);
        [@batched_items]; # => is_deeply [ [1, 2, 3] ]

        $q->push(6, 7);
        [@batched_items]; # => is_deeply [ [1, 2, 3], [4, 5, 6] ]

        $q->flush;
        [@batched_items]; # => is_deeply [ [1, 2, 3], [4, 5, 6], [7] ]

        $q->push(8);
        undef $q; # automatically flush on destroy
        [@batched_items]; # => is_deeply [ [1, 2, 3], [4, 5, 6], [7], [8] ]
    }

    # Procedual interface
    {
        my $q = Data::Queue::Batch->new(batch_size => 3);
        $q->enqueue(1);
        $q->push(2); # alias for 'enqueue'

        $q->dequeue; # => undef
        $q->shift; # alias for 'dequeue';

        $q->size; # => 2

        $q->push(3); # the first batch gets filled, so you can dequeue items
        $q->shift; # => 1
        $q->shift; # => 2

        $q->clear;
        $q->size; # => 0
    }


=head1 DESCRIPTION

This is a simple FIFO data structure library to dequeue items by configured batch size.

This will be usable for processing items B<in batch>, like bulk insertion to the database, etc.

For clarification, imagine the following queue:

    <- head
    [ ooooo | ooo ]

This queue's C<batch_size> is 5, and there are 8 items in the queue.
But you can see only first 5 items, and can't dequeue / peek last 3 items, because the second I<batch> hasn't been filled yet.

Then, push additional 3 items:

    <- head
    [ ooooo | ooooo | o ]

At this time, you can retrieve fist 10 items since the first and second I<batch>es get filled.

Let's dequeue 2 items. After that, the queue can be described as the following:

    <- head
    [ ooo | ooooo | o ]

You can dequeue / peek the first 8 items, but the last element is still not available yet.

=head1 METHOD

=head2 new(%options)

Creates a new queue object.

Options are:

=over

=item C<< batch_size => $size || 100 >>

The batch size for retrieving items. The enqueued items are placed in each I<batch> with the C<batch_size> capacity. The items will never be available without having their batches filled.

=item C<< callback =>\&cb || undef >> 

The callback subroutine which will be called when the first batch gets filled.
When you use callback interface, you don't need dequeue manually.

If the C<callback> is set, C<flush()> will be automarically called when the queue is destroyed.

=back

=head2 enqueue(@items)

=head2 push(@items)

Enqueues the items into the queue.


=head2 dequeue()

=head2 shift()

Dequeues the first item from the queue, and returns it.

If the C<callback> is set, you don't need to dequeue manually (but you can also do it).

=head2 peek(n)

Returns the available C<c> itmes from the head, but don't remove from the queue.

=head2 clear()

Clears the queue. The callback won't be called.

=head2 flush()

Dequeues all items remained in the last (unfilled) batch with calling callback, and returns dequeued items.

This will be gets called when the queue is destroyed and the callback is set.

=head2 size()

Returns the total size of the queue.

This is the real size of the queue, i.e. it includes the number of the items whose batch is unfilled yet.

=head2 available()

Returns the number of items which can be retrieved.

=head2 batch_size()

Getter for C<batch_size> option argument.

=head1 LICENSE

Copyright (C) Ichito Nagata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ichito Nagata E<lt>i.nagata110@gmail.comE<gt>

=cut

