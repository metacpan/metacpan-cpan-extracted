package Connector::Multi::Merge;

use strict;
use warnings;
use English;
use Config::Merge;
use Data::Dumper;

use Moose;

extends 'Connector::Builtin::Memory';

has '+LOCATION' => ( required => 1 );

sub _build_config {

    my $self = shift;

    # Skip the workflow directories
    my $cm    = Config::Merge->new( $self->LOCATION() );
    my $cmref = $cm->();
    my $tree = $self->cm2tree($cmref);

    return $tree;

}

# Traverse the tree read from Config::Merge and replace the "@" keys by
# scalar references 

sub cm2tree {
    my $self = shift;
    my $cm   = shift;

    if ( ref($cm) eq 'HASH' ) {
        my $ret = {};
        foreach my $key ( keys %{$cm} ) {
            if ( $key =~ m{ (?: \A @ (.*?) @ \z | \A @ (.*) | (.*?) @ \z ) }xms ) {
                my $match = $1 || $2 || $3;
                # make it a ref to an anonymous scalar so we know it's a symlink
                $ret->{$match} = \$cm->{$key};
            } else {
                $ret->{$key} = $self->cm2tree( $cm->{$key} )
            }
        }
        return $ret;
    }
    elsif ( ref($cm) eq 'ARRAY' ) {
        my $ret = [];
        my $i = 0;
        foreach my $entry ( @{$cm} ) {
            $ret->[ $i++ ] = $self->cm2tree($entry);
        }
        return $ret;
    }
    else {
        return $cm;
    }
}

1;

__DATA__


=head1 Name

Connector::Multi::Merge
 
=head1 Description

This is a glue connector to create the required reference syntax for 
Connector::Multi based on a backend configuration handled by Config::Merge.

LOCATION is passed over as path to Config::Merge and must point to the 
root node of the config directory.

Internally, the constructor walks down the whole tree and translates 
all keys starting or ending with the "@" character into references as 
understood by Connector::Multi.

=head1 CONFIGURATION

There is no special configuration besides the mandatory LOCATION property.

=head1 Example

   my $backend = Connector::Multi::Merge->new({
       LOCATION = /etc/myconfigtree/
   })
   
   my $multi = Connector::Multi->new({
       BASECONNECTOR => $backend
   })


