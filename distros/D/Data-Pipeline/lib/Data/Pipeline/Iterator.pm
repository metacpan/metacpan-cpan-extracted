package Data::Pipeline::Iterator;

use Moose;

use Data::Pipeline::Types qw( IteratorSource );
use MooseX::Types::Moose qw( Object );

has coded_source => (
    isa => 'CodeRef',
    is => 'rw',
);

has source => (
    isa => IteratorSource,
    is => 'rw',
    coerce => 1,
    trigger => sub {
       my $self = shift;
       #print STDERR "registering($self) with ", $self -> source, "\n";
       $self -> source -> register($self);
    },
    default => sub {
        #print STDERR "getting coded source for $_[0]\n";
        $_[0] -> coded_source -> ();
    },
    lazy => 1,
    predicate => 'has_source'
);

has _can_duplicate => (
    isa => 'Bool',
    is => 'rw',
    default => '1'
);

#sub BUILD {
#    my($self) = @_;
#
#    # do it ourselves for a while
#    #$self -> source -> register($self) if defined $self -> source;
#}

sub DEMOLISH {
    my($self) = @_;

    $self -> source -> unregister($self) if $self -> has_source && $self -> source;
}

sub iterator { $_[0] }

sub finished {
    my $self = shift;
    $self -> source -> finished($self);
}

sub next { 
    my $self = shift;
    $self -> _can_duplicate(0); # if we try to act as a source
    $self -> source -> next($self);
}

sub duplicate {
    my($self) = @_;

    my $source = eval { $self -> source -> duplicate } || ($self -> _can_duplicate ? $self -> as_source : $self -> source );

    return __PACKAGE__ -> new( source => $source );
}

#
# making an iterate the source of another:
# Iterator -> new (source => $iterator -> as_source )
#
# this decouples the stream
#
sub as_source {
    my $self = shift;

    my $new_self = __PACKAGE__ -> new( source => $self -> source );

    return Data::Pipeline::Iterator::Source -> new(
        has_next => sub { !$new_self -> finished },
        get_next => sub { $new_self -> next }
    );
}

no Moose;

1;

__END__

we need a way to have observers of an iterator -- basically, anyone using the
iterator is an observer.  This allows multiple pipelines to share a common
pipeline (one splits into multiple) while only running the common pipeline once
