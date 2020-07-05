# Connector::Proxy::YAML
#
# Proxy class for reading YAML configuration
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy::YAML;

use strict;
use warnings;
use English;
use YAML;
use Data::Dumper;

use Moose;

extends 'Connector::Builtin::Memory';

# set Location required (unset by parent class)
has '+LOCATION' => ( required => 1 );

sub _build_config {
    my $self = shift;

    # File not exist or not readable
    my $config;
    my $file = $self->LOCATION();
    if ( ( -e $file ) && ( -r $file ) )  {
         eval {
            $config = YAML::LoadFile( $file );
        };
        if ($@) {
            $self->log()->error('Proxy::Yaml error parsing file '.$file);
            $self->log()->debug( Dumper( $@ ) );
            return $self->_node_not_exists( $file );
        }
        $self->log()->debug('Proxy::Yaml loading configuration from file '.$file);
    } else {
        $self->log()->warn('Proxy::Yaml configuration file '.$file.' not found ');
    }
    $self->_config($config);
}

sub set { shift;  die "No set() method defined";  };

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 Name

Connector::Proxy::YAML

=head1 Description

Reads a yaml file from the path given as LOCATION and makes its structure
available via the accessor methods.

If the file could not be loaded this connector returns undef for all requests.

B<Note>: Changes made to the YAML file after the connector was first
initialized will not be visible as the file is read once on startup and
persited into memory.

=head1 Parameters

=over

=item LOCATION

The location of the yaml file.

=back
