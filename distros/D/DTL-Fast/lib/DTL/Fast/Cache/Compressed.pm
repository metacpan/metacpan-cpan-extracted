package DTL::Fast::Cache::Compressed;
use strict;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Cache::Serialized';

our %CACHE;

#@Override
sub new
{
    my ( $proto, %kwargs ) = @_;
    require Compress::Zlib;

    return $proto->SUPER::new(%kwargs);
}

#@Override
sub read_serialized_data
{
    my ( $self, $key ) = @_;

    return
        $self->decompress(
            $self->read_compressed_data(
                $key
            )
        );
}

#@Override
sub write_serialized_data
{
    my ( $self, $key, $data ) = @_;

    $self->write_compressed_data(
        $key,
        $self->compress(
            $data
        )
    ) if (defined $data); # don't store undef values
    return $self;
}


sub read_compressed_data { return shift->SUPER::read_serialized_data(@_) };

sub write_compressed_data { return shift->SUPER::write_serialized_data(@_) };

sub compress
{
    my ( $self, $data ) = @_;
    return if (not defined $data);
    return Compress::Zlib::memGzip($data);
}

sub decompress
{
    my ( $self, $data ) = @_;
    return if (not defined $data);
    return Compress::Zlib::memGunzip($data);
}



1;