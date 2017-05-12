package Data::Pipeline::Aggregator::Union;

use Moose;
extends 'Data::Pipeline::Aggregator';

use Data::Pipeline::Types qw( Iterator );

has actions => (
    isa => 'ArrayRef',
    is => 'rw',
    predicate => 'has_actions',
    default => sub { [ ] },
    lazy => 1
);

sub transform {
    my($self, @iterators) = @_;

    $_ = to_Iterator($_) for @iterators;

    my $n = scalar(@{$self -> actions});

    $n = scalar(@iterators) if scalar(@iterators) < $n;

    while( $n > 0 ) {
        $n--;
        $iterators[$n] = $self -> actions -> [$n] -> transform( $iterators[$n] );
    }

    # we want to round-robin between them
    return Data::Pipeline::Iterator -> new(
        source => Data::Pipeline::Source::Iterator -> new(
            has_next => sub {
                @iterators = grep { !$_ -> finished } @iterators;
                return 1 if @iterators;
                return 0;
            },
            get_next => sub {
                my $i;
                $i = shift @iterators while $i && $i -> finished;
                return unless defined $i;
                push @iterators, $i;
                return $i -> next;
            }
        )
    );
}

1;

__END__
