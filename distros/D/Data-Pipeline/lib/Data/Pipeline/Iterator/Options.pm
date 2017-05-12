package Data::Pipeline::Iterator::Options;

use Moose;
extends 'Data::Pipeline::Iterator';

# builds an iterator for a set of options
# we find the first set, then build iterators in a chain for each
# of the options left that still has a next value
# return as a hash
# we don't do a deep scan -- just a top-level scan of the options hash

use Data::Pipeline::Types qw( Iterator Aggregator );

has params => (
    isa => 'HashRef',
    is => 'rw',
    required => 1
);

has '+source' => (
    required => 0,
    default => sub {
        my $self = shift;
        $self -> build_source;
        $self -> source;
    },
    lazy => 1
);

sub build_source {
    my($self) = @_;

    #given the options, we want to find all of the constant bits and
    #factor them out... then add them to an iterator that gives us the
    #variable ones.   When the iterator runs out, we're done.

    my %constants;

    for my $key (keys %{$self -> params}) {
        my $it;
        if( is_Aggregator( $self -> params -> {$key} ) ) {
            $it = $self -> params -> {$key} -> from( );
        }
        else {
            $it = to_Iterator($self -> params -> {$key}) -> duplicate;
        }
        $constants{$key} = $it -> next;
        delete $constants{$key} unless $it -> finished;
    }

    if( %constants ) {
        my %params = (
                map { $_ => $self -> params -> {$_} }
                grep { !exists $constants{$_} }
                keys %{$self -> params}
        );

        if( keys %params ) {
            my $iterator = Data::Pipeline::Iterator::Options -> new(
                params => {
                    map { $_ => $self -> params -> {$_} }
                    grep { !exists $constants{$_} }
                    keys %{$self -> params}
                }
            );

            $self -> source(
                Data::Pipeline::Iterator::Source -> new(
                    get_next => sub {
                        my $v = $iterator -> next;
                        @{$v}{keys %constants} = (values %constants);
                        return $v;
                    },
                    has_next => sub {
                        !$iterator -> finished;
                    },
                )
            );
        }
        else {
            $self -> source(
                Data::Pipeline::Iterator::Source -> new(
                    get_next => sub {
                        $self -> source(
                            Data::Pipeline::Iterator::Source -> new(
                                get_next => sub { },
                                has_next => sub { 0 }
                            )
                        );
                        return \%constants;
                    },
                    has_next => sub { 1 }
                )
            );
        }
    }
    else {
        my %params = %{$self -> params};
        if(! keys %params ) {
            $self -> source(
                Data::Pipeline::Iterator::Source -> new(
                    has_next => sub { 0 },
                    get_next => sub { }
                )
            );
        }
        else {
            my $own_key = (keys %params)[0];
            my $own_iterator = to_Iterator(delete $params{$own_key});

            if( keys(%params) ) {
                my $iterator = Data::Pipeline::Iterator::Options -> new(
                    params => \%params,
                );
                my $dup_iterator = $own_iterator -> duplicate;
                my $other_stuff = $iterator -> next;
                $self -> source(
                    Data::Pipeline::Iterator::Source -> new(
                        get_next => sub {
                            if($dup_iterator -> finished) {
                                $other_stuff = $iterator -> next;
                                $dup_iterator = $own_iterator -> duplicate;
                            }
                            my %v = %$other_stuff;
                            $v{$own_key} = $dup_iterator -> next;
                            return \%v;
                        },
                        has_next => sub {
                            !($dup_iterator -> finished
                            && $iterator -> finished)
                        },
                    )
                );
            }
            else {
                $self -> source( 
                    Data::Pipeline::Iterator::Source -> new(
                        get_next => sub { +{
                            $own_key => $own_iterator -> next
                        } },
                        has_next => sub { !$own_iterator -> finished }
                    )
                );
            }
        }
    }
}
     
1;

__END__
