package # hide from PAUSE
    Local::TN2;

use parent 'Local::TN';

sub int2 {
    my $self = shift;
    $self->{int2} = $_[0] if @_;
    $self->{int2};
}

1;
