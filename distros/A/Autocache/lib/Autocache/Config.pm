package Autocache::Config;

use strict;
use warnings;

use base 'Autocache::Config::Node';

use Carp;
use IO::File;
use Data::Dumper;

sub new
{
    my ($class,$filename) = @_;
    my $self = $class->SUPER::new( '' );

    if( $filename )
    {
        confess "configuration file supplied cannot be found/read"
            unless _file_good( $filename );
        $self->_load_config_file( $filename );
    }
    else
    {
        $filename = _locate_config_file();
        $self->_load_config_file( $filename )
            if defined $filename;
    }


    return $self;
}

sub _load_config_file
{
    my ($self,$filename) = @_;

    my $fh = IO::File->new( $filename, 'r' )
        or confess "cannot open file for reading '$filename'";

    while( my $line = <$fh> )
    {
        next if $line =~ /^\s*$/;
        next if $line =~ /^#/;
        next unless $line =~ /^autocache./;
        $line =~ s/^autocache.//;
        chomp $line;
        my ( $key, $value ) = split /\s+=\s+/, $line, 2;
        $self->get_node( $key )->value( $value );
    }

    $fh->close;
    return 1;
}

sub _locate_config_file
{
    my $filename = sprintf '%s/etc/autocache.conf', $ENV{HOME};

    if( _file_good( $filename ) )
    {
        return $filename;
    }

    $filename = '/etc/autocache.conf';

    if( _file_good( $filename ) )
    {
        return $filename;
    }

    return undef;
}

sub _file_good
{
    return ( -e $_[0] && -r _ );
}

1;
