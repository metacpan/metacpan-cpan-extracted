package Data::Pipeline::Adapter::Array;

use Moose;
extends 'Data::Pipeline::Adapter';

use Data::Pipeline::Iterator::Source;

use Data::Pipeline::Types qw(Iterator);

use MooseX::Types::Moose qw(ArrayRef CodeRef GlobRef);

has array => (
    is => 'ro',
    isa => 'ArrayRef|Data::Pipeline::Types::Iterator|CodeRef',
    default => sub { [ ] },
    lazy => 1
);

has '+source' => (
    lazy => 1,
    coerce => 1,
    default => sub {
        my($self) = @_;

        my $i = 0;

        #print STDERR "Array source\n";

        if( is_ArrayRef($self -> array) ) {
            Data::Pipeline::Iterator::Source -> new(
                get_next => sub { ($i <= $#{$self -> array}) ? $self -> array -> [$i++] : undef },
                has_next => sub { $i <= $#{$self -> array} }
            );
        }
        else {
 ### TODO: fix this so CodeRefs are genericly handled
            my $it = $self -> array;
            if(is_CodeRef( $it )) {
                $it = $it -> ();
                Carp::carp "Code does not return an iterator";
            }
            to_Iterator($it) -> source;
        }
    }
);

override serialize => sub {
    my($self, $iterator, $target) = @_;

    if(is_ArrayRef($target)) {
        @{$target} = ( );
        push @{$target}, $iterator -> next until $iterator -> finished;
    }
    elsif(is_GlobRef($target)) {
        print $target $iterator->next until $iterator -> finished;
    }
    else {
        local($Carp::CarpLevel) = 1;
        Carp::croak "Array serialization only works with an array reference target";
    }
};

1;

__END__
