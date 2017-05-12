package Array::Queue;
$Array::Queue::VERSION = '0.1.2';
use Moose;

use namespace::autoclean;


=head1 NAME

Array::Queue - A simple fifo queue

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

    my $queue = Array::Queue->new;
    $ar->add({ id => 20 });
    $ar->add({ id => 18 });
    $ar->add({ id => 22 });

    while ($node = $queue->first) {
        # do things with node
        $queue->remove;
    }

=head1 DESCRIPTION

Array::Queue is a fairly simple First-In / First-Out queue build with Moose.

Any data structure can be added to the queue and retrieved in the order it was 
added.  

Originally part of Array::Queue::Priority until I decided to break them into two
classes, the one dependant on the other.


=head1 METHODS

=head2 C<add>

    $ar->add( 99 );

You can add any type of item to the queue.

=head2 C<remove>

    $ar->remove;

Remove the oldest item on the queue.  

Returns value removed.

=head2 C<first>

    $ar->first;

Returns the first / oldest item in the queue.

Leaves the item in the queue.

=head2 C<queue>

    $ar->queue;

Reference directly the array used to store the queued items.

=head2 C<size>

    $ar->size;

How many elements are in the queue.

=head2 C<empty>

    $ar->empty;

Boolean, is queue empty?

=head1 AUTHOR

Dan Burke C<< dburke at addictmud.org >>

=head1 BUGS

If you encounter any bugs, or have feature requests, please create an issue
on github. https://github.com/dwburke/perl-Array-Queue/issues

Pull requests also welcome.

=head1 LICENSE AND COPYRIGHT

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut


sub first {
	my ($self) = @_;
	$self->get(0);
}


has queue => (
    is => 'rw',
    isa => 'ArrayRef[Item]', 
    traits => [ 'Array' ],
    default => sub { [ ] },
    handles => {
        add => 'push',
        remove => 'shift',
        size => 'count',
        get => 'get',
        empty => 'is_empty',
        _insert => 'insert',
    },
    );



__PACKAGE__->meta->make_immutable;

1;
