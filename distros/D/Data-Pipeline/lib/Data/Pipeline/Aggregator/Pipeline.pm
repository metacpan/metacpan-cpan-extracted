package Data::Pipeline::Aggregator::Pipeline;

use Moose;
extends 'Data::Pipeline::Aggregator';

use MooseX::Types::Moose qw(ArrayRef CodeRef);

use Data::Pipeline::Types qw(Iterator Adapter);

use Data::Pipeline::Machine ();

has actions => (
    isa => 'ArrayRef',
    is => 'rw',
    predicate => 'has_actions',
    default => sub { [ ] },
    lazy => 1
);

sub from {
    my($self, %options) = @_;

    if( !$self -> has_actions ) {
        Carp::croak "Pipeline doesn't have an adapter from which to get data";
    }

    my($source, @rest) = @{$self -> actions};
    $source = $source -> () if is_CodeRef( $source );
    $source = $source -> duplicate( %options ) if is_Adapter( $source );
    $source = to_Iterator( $source );
    if( !is_Iterator( $source ) ) {
        Carp::croak "Pipeline doesn't have a source from which to get data";
    }

    my $cascade = $source;
    for my $action ( @rest ) {
        $cascade = $action -> transform( $cascade );
    }

    return $cascade;
}

sub transform {
    my($self, $iterator) = @_;

    #Data::Pipeline::Machine::with_options($options, sub {
        $iterator = to_Iterator( $iterator );
    #$iterator -> options( $options );

        return $iterator unless $self -> has_actions;

        my $cascade = $iterator;

        #my $first = 1;
        for my $action (@{$self -> actions}) {
            #next if $first && $action -> isa('Data::Pipeline::Adapter');

            #$first = 0;
            #$action -> options( $options );
            $cascade = $action -> transform( $cascade );
      #      $cascade -> options( $options );
        }

        return $cascade;
    #});
}

1;

__END__

=head1 NAME

Data::Pipeline::Aggregator::Pipeline - serial aggregation of actions

=head1 SYNOPSIS

=head2 Creation

 $pipeline = Data::Pipeline::Aggregator::Pipeline -> new( 
     actions => \@actions
 )

or

 use Data::Pipeline qw( Pipeline );
 $pipeline = Pipeline( @actions );
 
=head2 Use

 $out_iterator = $pipeline -> from( %options )
 
 $out_iterator = $pipeline -> transform( $in_iterator )

=head1 DESCRIPTION


