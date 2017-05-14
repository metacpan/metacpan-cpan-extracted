package DTL::Fast::Cache::Runtime;
use strict;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Cache';

# Runtime cache for compiled templates

#@Override
sub new
{
    my ( $proto, %kwargs ) = @_;

    $kwargs{cache} = { };

    return $proto->SUPER::new(%kwargs);
}

sub read_data
{
    my ( $self, $key ) = @_;
    return if (not defined $key);
    return exists $self->{cache}->{$key} ? $self->{cache}->{$key} : undef;
}


sub write_data
{
    my ( $self, $key, $data ) = @_;
    return if (not defined $key);
    return if (not defined $data);
    $self->{cache}->{$key} = $data;
    return $self;
}

#@Override
sub clear
{
    my ( $self ) = @_;
    $self->{cache} = { };
    return $self;
}

1;