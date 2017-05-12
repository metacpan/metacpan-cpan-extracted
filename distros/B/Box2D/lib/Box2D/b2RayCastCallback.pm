package Box2D::b2RayCastCallback;
use strict;
use warnings;
use Box2D;
use Carp;

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    $self->{_callback}
        = Box2D::PerlRayCastCallback->new( sub { $self->ReportFixture(@_) } );

    return $self;
}

sub ReportFixture {
    croak 'You must override Box2D::b2RayCastCallback::ReportFixture';
}

sub _getCallback { $_[0]->{_callback} }

1;
