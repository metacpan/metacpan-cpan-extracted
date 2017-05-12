package FooExport;

use Class::NonOO;

our @EXPORT = qw/ bar baz /;
our @EXPORT_OK = qw/ boop /;

sub new {
    my $class = shift;
    my $self  = {@_};
    $self->{bar} //= 1;
    bless $self, $class;
    return $self;
}

sub bar {
    my ( $self, $val ) = @_;
    if ( defined $val ) {
        $self->{bar} = $val;
    }
    else {
        $self->{bar};
    }
}

sub baz {
    my ($self) = @_;
    $self->bar + 1;
}

sub boop {
    my ($self) = @_;
    return ( $self->bar, $self->baz );
}

as_function args => [ bar => 5 ];

1;
