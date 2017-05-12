package Autocache::Strategy::Statistics;

use Any::Moose;

extends 'Autocache::Strategy';

use Autocache;
use Autocache::Logger qw(get_logger);

#
# base_strategy : underlying strategy that handles storage and expiry -
# defaults
#
has 'base_strategy' => (
    is => 'ro',
    isa => 'Autocache::Strategy',
    lazy_build => 1,
);

#
# hashref containing our stats
#
has 'statistics' => (
    is => 'rw',
    isa => 'HashRef',
    lazy_build => 1,
);

#
# create REQ
#
sub create
{
    my ($self,$req) = @_;
    get_logger()->debug( "create" );
    ++$self->statistics->{create};
    return $self->base_strategy->create( $req );
}

#
# get REQ
#
sub get
{
    my ($self,$req) = @_;
    get_logger()->debug( "get" );
    my $rec = $self->base_strategy->get(
        $req );
    if( $rec )
    {
        ++$self->statistics->{hit};
    }
    else
    {
        ++$self->statistics->{miss};
    }
    ++$self->statistics->{total};
    return $rec;
}

#
# REQ REC
#
sub set
{
    my ($self,$req,$rec) = @_;
    get_logger()->debug( "set " . $rec->name );
    return $self->base_strategy->set( $req, $rec );
}

#
# delete KEY
#
sub delete
{
    my ($self,$key) = @_;
    return $self->base_strategy->delete( $key );
}

sub clear
{
    my ($self) = @_;
    return $self->base_strategy->clear;
}

sub _build_base_strategy
{
    return Autocache->singleton->get_default_strategy();
}

sub _build_statistics
{
    return {
        hit => 0,
        miss => 0,
        create => 0,
        total => 0,
    };
}

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    get_logger()->debug( __PACKAGE__ . " - BUILDARGS" );

    if( ref $_[0] )
    {
        my $config = $_[0];
        my %args;
        my $node;

        if( $node = $config->get_node( 'base_strategy' ) )
        {
            get_logger()->debug( "base strategy node found" );
            $args{base_strategy} = Autocache->singleton->get_strategy( $node->value );
        }

        return $class->$orig( %args );
    }
    else
    {
        return $class->$orig(@_);
    }
};

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
