package Data::Pipeline::Action;

use Moose::Role;

use MooseX::Types::Moose qw( ArrayRef );

use Data::Pipeline::Types qw( Iterator );

sub to {
    Carp::croak "Action called expecting an output adapter";
}

sub make_iterator {
    my($self, $iterator) = @_;

    Carp::confess "deprecated call to make_iterator";
}

sub transform {
    my($self, $iterator) = @_;

    my $source;
    $iterator = to_Iterator($iterator);

    if( $self -> can('reduce_iterator') ) {
        $source = Data::Pipeline::Iterator::Source -> new(
            has_next => sub { 1 },
            get_next => sub {
                my $r = $self -> reduce_iterator($iterator);
                if( is_Iterator($r) ) {
                    $source -> has_next( $r -> has_next );
                    $source -> get_next( $r -> get_next );
                    return $r -> get_next -> ();
                }
                else {
                    $source -> has_next(sub{ 0 });
                    return $r;
                }
            },
        );

    }
    elsif( $self -> can('map_item') ) {
        $source = Data::Pipeline::Iterator::Source -> new(
            has_next => sub { !$iterator -> finished },
            get_next => sub { $self -> map_item($iterator -> next) },
        );
    }
    else {
        $source = inner;
    }

    my $it = Data::Pipeline::Iterator -> new(
        source => $source,
    );
    return $it;
}

no Moose;

1;

__END__
