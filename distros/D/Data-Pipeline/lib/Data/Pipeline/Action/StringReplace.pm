package Data::Pipeline::Action::StringReplace;

use Moose;
with 'Data::Pipeline::Action';

has replace => (
    isa => 'HashRef',
    is => 'rw',
    default => sub { +{ } },
    lazy => 1,
    trigger => sub {
        my $self = shift;
        $self -> _tr( $self -> _build_tr );
    }
);

has _tr => ( isa => 'ArrayRef', is => 'rw' );

sub BUILD {
    my $self = shift;

    $self -> _tr( $self -> _build_tr );
}

sub _build_tr {
    my($self) = @_;

    my($left, $right);

    my @keys = sort keys %{$self -> replace};

    $left = join('', @keys);
    $right = join('', @{$self -> replace}{@keys});
    return [ $left, $right ];
}

sub map_item {
    my($self, $i) = @_;

    my($left, $right) = @{$self -> _tr};

    eval "\$i =~ tr/$left/$right/";
    $i;
}

1;

__END__
