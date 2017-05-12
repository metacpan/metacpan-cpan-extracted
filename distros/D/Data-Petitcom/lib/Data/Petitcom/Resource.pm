package Data::Petitcom::Resource;

use strict;
use warnings;

use parent qw{ Exporter };
our @EXPORT = qw{ get_resource };

use Carp ();
use Module::Load ();

sub get_resource {
    my %opts     = @_;
    my $resource = delete $opts{resource} || 'PRG';
    my $pkg_resource = join '::', __PACKAGE__, uc($resource);
    Module::Load::load $pkg_resource;
    my $obj_resource = $pkg_resource->new( resource => $resource, %opts );
    Carp::croak "initialize failed: $!"
        unless ( $obj_resource->isa(__PACKAGE__) );
    return $obj_resource;
}

my %defaults = ( data => undef );

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $self = bless {@_}, $class;
    $self->init() if ( $self->can('init') );
    return $self;
}

sub init {
    my $self = shift;
    for ( keys %defaults ) {
        my $value = $self->{$_} || $defaults{$_};
        ( $self->can($_) ) ? $self->$_($value) : ( $self->{$_} = $value );
    }
    return $self;
}

sub data {
    my $self = shift;
    $self->{data} = shift if (@_);
    return $self->{data};
}

sub save { die "override save" }
sub load { die "override load" }

1;
