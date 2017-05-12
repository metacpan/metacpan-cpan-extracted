package Data::Pipeline::Action::Tail;

use Moose;
with 'Data::Pipeline::Action';

has length => (
    isa => 'Int',
    is => 'ro',
    required => 1
);

sub transform {
    my($self, $iterator) = @_;

    my $count = $self -> length;
    my @stack;

    $iterator = $self -> make_iterator($iterator);

    return Data::Pipeline::Iterator -> new(
        source => Data::Pipeline::Source::Iterator -> new(
            has_next => sub {
                @stack > 0
            },
            get_next => sub {
                while(defined( $iterator ) && !$iterator -> finished) {
                    push @stack, $iterator -> next;
                    shift @stack if @stack > $count;
                }
                $iterator = undef;

                return shift @stack;
            },
        )
    );
}

1;

__END__
