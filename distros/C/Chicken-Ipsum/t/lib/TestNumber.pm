package TestNumber 0.000001;
use 5.012;
use warnings FATAL => 'all';
use parent 'Math::BigInt';

sub sample {
    my $self = shift;
    $self->{sample_called} = 1;
    return;
}

1;
