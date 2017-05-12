package Data::Pipeline::Action::Truncate;

use Moose;
with 'Data::Pipeline::Action';

use Data::Pipeline::Types qw( Iterator );

has length => (
    isa => 'Int',
    is => 'ro',
    required => 1
);

sub transform {
    my($self, $iterator) = @_;

    my $count = $self -> length;

    $iterator = to_Iterator($iterator);

    return Data::Pipeline::Iterator -> new(
        source => Data::Pipeline::Iterator::Source -> new(
            has_next => sub {
                $count > 0 && defined($iterator) && !$iterator -> finished;
            },
            get_next => sub {
                if($count > 0) {
                    $count--;
                    return $iterator -> next;
                }
                else {
                    $iterator = undef; # release resources
                }
                return undef;
            },
        )
    );
}

1;

__END__
