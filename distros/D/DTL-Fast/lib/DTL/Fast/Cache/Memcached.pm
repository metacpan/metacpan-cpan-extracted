package DTL::Fast::Cache::Memcached;
use strict;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Cache::Runtime';

our %SUPPORTS = qw(
    Cache::Memcached        1
    Cache::Memcached::Fast  1
    );

#@Override
sub new
{
    my ( $proto, $memcached ) = @_;

    if (not exists $SUPPORTS{ref $memcached})
    {
        die sprintf(
                "You may construct %s object using one of the following modules:\n\t%s\n"
                , $proto // 'undef'
                , join( "\n\t", keys %SUPPORTS )
            );
    }

    return $proto->SUPER::new( mc => $memcached );

}

#@Override
sub read_data
{
    my ( $self, $key ) = @_;
    return $self->{mc}->get($key);
}

#@Override
sub write_data {
    my ( $self, $key, $data ) = @_;

    return $self->{mc}->set($key, $data);
}

1;