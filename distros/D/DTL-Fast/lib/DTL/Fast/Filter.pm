package DTL::Fast::Filter;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Entity';

use DTL::Fast::Template;

sub new
{
    my ( $proto, $parameter, %kwargs) = @_;

    $proto = ref $proto || $proto;

    $kwargs{parameter} = $parameter // [ ];

    die $proto->get_parse_error("Parameter must be an ARRAY reference")
        if (ref $kwargs{parameter} ne 'ARRAY');

    my $self = $proto->SUPER::new(%kwargs);

    return $self->parse_parameters();
}

sub parse_parameters {return shift;}

sub filter
{
    my ($self) = @_;
    die sprintf( "filter was not overriden in a subclass %s", ref $self );
}

1;
