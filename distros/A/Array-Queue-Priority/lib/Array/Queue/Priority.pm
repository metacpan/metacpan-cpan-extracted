package Array::Queue::Priority;
$Array::Queue::Priority::VERSION = '0.1.2';
use Moose;

extends 'Array::Queue';

use namespace::autoclean;


=head1 NAME

Array::Queue::Priority - A custom sorted queue

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

    my $queue = Array::Queue::Priority->new(
        sort_cb => sub {
            $_[0]->{last_name} cmp $_[1]->{last_name}
        });
    $ar->add({ last_name => 'Rogers' });
    $ar->add({ last_name => 'Stark' });
    $ar->add({ last_name => 'Banner' });

    while ($node = $queue->first) {
        # do things with node
        $queue->remove;
    }

=head1 DESCRIPTION

Array::Queue::Priority priority queue, sorted by whatever you desire.

As values are inserted, they are sorted on the fly, ensuring the values
come out in the order you desire.  You simply supply the sort_cb at the
time of construction.

If no sort_cb is supplied, it will try to sort by values passed.  You'll
probably get warnings if that's just a string, and who knows what you will
get if it's a hashref.  Straight numbers will work just find though.

Call first() then remove() for a little "transactional safety" if there's
an error processing the first item in the queue.


Inherits from Array::Queue.

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

sub add {
    my ($self, $node) = @_;

    if ($self->size == 0) {
        $self->_insert(0, $node);
    }
    else {
        my $sort_cb = $self->sort_cb;

        my $found = 0;

        my $idx;
        for ($idx = 0; $idx < $self->size; $idx++) {

            my $sort_it = $sort_cb->($node, $self->get($idx));

            if ($sort_it == -1) {
                $self->_insert($idx, $node);
                $found = 1;
                last;
            }

        }

        unless ($found) {
            $self->_insert($idx, $node);
        }

    }

    $node;
}


has sort_cb => (
	is => 'ro',
	isa => 'CodeRef',
	default => sub { sub { $_[0] <=> $_[1] } },
	);


__PACKAGE__->meta->make_immutable;

1;
