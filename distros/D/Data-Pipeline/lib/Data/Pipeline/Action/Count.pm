package Data::Pipeline::Action::Count;

use Moose;
with 'Data::Pipeline::Action';

has name => (
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => 'count'
);

sub reduce_iterator {
    my($self, $iterator) = @_;

#    print STDERR "iterator: $iterator\n";
    my $count = 0;
    until( $iterator -> finished ) { $iterator -> next; $count++; } #print STDERR "count: ", $iterator -> next, "\n"; $count++; }
    return {
        $self -> name => $count
    };
}

sub meta_reduce {
    my($self, $iterator) = @_;

    my $count = 0;
    $count += $iterator -> next -> {$self -> name} until $iterator -> finished;
    return {
        $self -> name => $count
    };
}

1;

__END__
