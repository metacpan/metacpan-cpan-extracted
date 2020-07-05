# Connector::Proxy::JSON
#
# Proxy class for reading a JSON file

package Connector::Proxy::JSON;

use strict;
use warnings;
use English;
use JSON;
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

        my $content = do {
          local $INPUT_RECORD_SEPARATOR;
          open my $fh, '<', $file;
          <$fh>;
        };
         eval {
            $config = JSON->new()->decode($content);
        };
        if ($@ || !$config || !ref $config) {
            $self->log()->error('Proxy::JSON error parsing content from file '.$file);
            $self->log()->debug( Dumper( $@ ) );
            return $self->_node_not_exists( $file );
        }
        $self->log()->debug('Proxy::JSON loading configuration from file '.$file);
    } else {
        $self->log()->warn('Proxy::JSON configuration file '.$file.' not found ');
    }
    $self->_config($config);
}

sub set { shift;  die "No set() method defined";  };

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 Name

Connector::Proxy::JSON

=head1 Description

Reads a json file from the path given as LOCATION and makes its structure
available via the accessor methods.

If the file could not be loaded this connector returns undef for all requests.

B<Note>: Changes made to the YAML file after the connector was first 
initialized will not be visible as the file is read once on startup and
persited into memory.

=head1 Parameters

=over

=item LOCATION

The location of the json file.

=back
