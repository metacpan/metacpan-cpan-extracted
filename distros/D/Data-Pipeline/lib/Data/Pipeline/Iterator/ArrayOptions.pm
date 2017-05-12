package Data::Pipeline::Iterator::ArrayOptions;

use Moose;
extends 'Data::Pipeline::Iterator';

# builds an iterator for a set of options
# we find the first set, then build iterators in a chain for each
# of the options left that still has a next value
# return as a hash
# we don't do a deep scan -- just a top-level scan of the options hash

use Data::Pipeline::Types qw( Iterator Aggregator );

has params => (
    isa => 'ArrayRef',
    is => 'rw',
    required => 1
);

has '+source' => (
    required => 0,
    default => sub {
        my $self = shift;
        $self -> build_source;
        $self -> source;
    },
    lazy => 1
);

has '_pos' => (
    isa => 'Int',
    is => 'rw',
    lazy => 1,
    default => sub { 0 }
);

sub build_source {
    my($self) = @_;

    #given the options, we want to find all of the constant bits and
    #factor them out... then add them to an iterator that gives us the
    #variable ones.   When the iterator runs out, we're done.

    my $own_iterator = to_Iterator($self -> params -> [ $self -> _pos ]);

    if($self -> _pos < @{$self -> params}-1) {
        my $iterator = Data::Pipeline::Iterator::ArrayOptions -> new(
            params => $self -> params,
            _pos => $self -> _pos+1
        );
        my $dup_iterator = $own_iterator -> duplicate;
        my $other_stuff = $iterator -> next;
        $self -> source(
            Data::Pipeline::Iterator::Source -> new(
                get_next => sub {
                    if($dup_iterator -> finished) {
                        $other_stuff = $iterator -> next;
                        $dup_iterator = $own_iterator -> duplicate;
                    }
                    return [ $dup_iterator -> next, @$other_stuff ];
                },
                has_next => sub {
                    !($dup_iterator -> finished
                    && $iterator -> finished)
                },
            )
        );
    }
    else {
        $self -> source( 
            Data::Pipeline::Iterator::Source -> new(
                 get_next => sub { [
                     $own_iterator -> next
                 ] },
                 has_next => sub { !$own_iterator -> finished }
            )
        );
    }
}
     
1;

__END__
