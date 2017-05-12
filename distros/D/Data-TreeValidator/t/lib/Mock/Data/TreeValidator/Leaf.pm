package Mock::Data::TreeValidator::Leaf;
use Moose;
use aliased 'Mock::Data::TreeValidator::Result';

with 'Data::TreeValidator::Node';

has process_count => (
    is => 'rw',
    traits => [ 'Counter' ],
    default => 0,
    handles => {
        processed => 'inc',
    }
);

sub was_processed { shift->process_count > 0 }

sub process {
    shift->processed;
    my $input = shift;
    return Result->new( clean => $input, input => $input );

}

1;
