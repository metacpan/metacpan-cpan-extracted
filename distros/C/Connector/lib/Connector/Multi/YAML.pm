package Connector::Multi::YAML;

use strict;
use warnings;
use English;
use YAML;
use Data::Dumper;

use Moose;

extends 'Connector::Builtin::Memory';

has '+LOCATION' => ( required => 1 );

sub _build_config {

    my $self = shift;

    # File not exist or not readable
    my $file = $self->LOCATION();
    if ( ! ( ( -e $file ) && ( -r $file ) ) )  {
        die 'configuration file '.$file.' not found ';
    }

    my $yaml = YAML::LoadFile( $file );

    my $config = $self->makeRefs($yaml);

    return $config;

}

# Traverse the tree read from the YAML file and replace the "@" keys by
# scalar references

sub makeRefs {

    my $self = shift;
    my $config = shift;

    if ( ref($config) eq 'HASH' ) {
        my $ret = {};
        foreach my $key ( keys %{$config} ) {
            if ( $key =~ m{ (?: \A @ (.*?) @ \z | \A @ (.*) | (.*?) @ \z ) }xms ) {
                my $match = $1 || $2 || $3;
                # make it a ref to an anonymous scalar so we know it's a symlink
                $ret->{$match} = \$config->{$key};
            } else {
                $ret->{$key} = $self->makeRefs( $config->{$key} );
            }
        }
        return $ret;
    }
    elsif ( ref($config) eq 'ARRAY' ) {
        my $ret = [];
        my $i = 0;
        foreach my $entry ( @{$config} ) {
            $ret->[ $i++ ] = $self->makeRefs($entry);
        }
        return $ret;
    }
    else {
        return $config;
    }
}

1;

__DATA__


=head1 Name

Connector::Multi::YAML

=head1 Description

This is a glue connector to create the required reference syntax for
Connector::Multi based on a backend configuration handled by YAML.

LOCATION is passed over as file to load by YAML.

Internally, the constructor walks down the whole tree and translates
all keys starting or ending with the "@" character into references as
understood by Connector::Multi.

=head1 CONFIGURATION

There is no special configuration besides the mandatory LOCATION property.

=head1 Example

   my $backend = Connector::Multi::YAML->new({
       LOCATION = /etc/myconfig.yaml
   })

   my $multi = Connector::Multi->new({
       BASECONNECTOR => $backend
   })


