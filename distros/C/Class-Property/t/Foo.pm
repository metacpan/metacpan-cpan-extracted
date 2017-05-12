package Foo;
use strict;
use Class::Property;

# Just blessing passed hash
sub new
{
    my( $proto, %data ) = @_;
    return bless {%data}, ref $proto || $proto;
}

property(
    'custom' => { 'set' => \&custom_setter, 'get' => \&custom_getter },
    'custom_get' => { 'set' => undef, 'get' => \&custom_getter_def },
    'custom_set' => { 'set' => \&custom_setter_def, 'get' => undef },
    'custom_ro' => { 'get' => \&custom_ro_getter },
    'custom_wo' => { 'set' => \&custom_wo_setter },
    'custom_lazy' => { 'get_lazy' => \&lazy_init, 'set' => undef },
    'custom_lazy2' => { 'get_lazy' => \&lazy_init2, 'set' => undef },
    'custom_lazy3' => { 'get_lazy' => \&lazy_init3, 'set' => undef },
    'lazy_custom_setter' => { 'get_lazy' => \&lazy_init4, 'set' => \&set_custom_lazy },
    'lazy_ro' => {'get_lazy' => \&lazy_ro_init }
);

rw_property( 'price', 'price3' );
ro_property( 'price_ro' );
wo_property( 'price_wo' );

sub lazy_ro_init
{
    return 123456;
}

sub set_custom_lazy
{
    my( $self, $value ) = shift;
    $self->{'custom_lazy_set'} = $value;
}

sub lazy_init4
{
    return 666;
}

sub lazy_init
{
    my $self = shift;
    return 100;
}

sub lazy_init2
{
    my $self = shift;
    return 300;
}

sub lazy_init3
{
    my $self = shift;
    return 500;
}

sub custom_setter
{
    my( $self, $value) = @_;
    $self->{'supercustom'} = $value;
}

sub custom_getter
{
    return shift->{'supercustom'};
}

sub custom_ro_getter
{
    return shift->{'supercustom_ro'};
}

sub custom_wo_setter
{
    return shift->{'supercustom_wo'};
}

sub custom_getter_def
{
    return shift->{'custom_get'} + 1;
}

sub custom_setter_def
{
    shift->{'custom_set'} = (shift) + 100;
}


1;
