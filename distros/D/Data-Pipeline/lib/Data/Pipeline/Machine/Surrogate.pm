package Data::Pipeline::Machine::Surrogate;

use Moose;

use MooseX::Types::Moose qw( CodeRef );

has named_pipeline => (
    isa => 'Str',
    is => 'rw',
    required => 1
);

has machine => (
    isa => 'Object',
    required => 1,
    is => 'rw'
);

has options => (
    isa => 'HashRef',
    required => 0,
    lazy => 1,
    is => 'rw',
    default => sub { +{ } }
);

sub from {
    my $self = shift;

    my %options = (%{$self -> options}, @_);

    #print STDERR ">>> Surrogate\n";
    for my $k (keys %options) { #grep { is_CodeRef( $options{$_} ) } keys %options) {
        $options{$k} = $options{$k} -> ( ) if is_CodeRef( $options{$k} );
        #print STDERR "surrogate $k => $options{$k}\n";
    }

    $self -> machine -> from( $self -> named_pipeline, %{$self -> options}, @_ );
}

1;

__END__
