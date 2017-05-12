package Connector::Iterator;

use strict;
use warnings;
use English;
use Moose;
use DateTime;
use Data::Dumper;

extends 'Connector';

has 'BASECONNECTOR' => ( is => 'ro', required => 1 );

# Location must not be used
has '+LOCATION' => ( required => 0, 'isa' => 'Undef' );

has target => (
    is  => 'rw',
    isa => 'Undef|ArrayRef',
    lazy => 1,
    builder => '_init_target',
);

has skip_on_error => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

sub _init_target {

    my $self = shift;

    # the connectors prefix points to the root node of the target list    
    my @target_node = $self->_build_path_with_prefix();
    
    if (!$self->BASECONNECTOR()->exists( \@target_node )) {
        $self->log()->warn( 'Target node does not exists ' . join(".", \@target_node) );
        return;
    }

    $self->log()->debug( 'Node with targets' . Dumper \@target_node );
    
    my @targets = $self->BASECONNECTOR()->get_keys( \@target_node );
    
    if (!scalar @targets) {
        $self->log()->warn( 'No targets found!' );
        return;
    }
     
    $self->log()->debug( 'Targets ' . Dumper \@targets );
    
    return \@targets;
}

sub set {
    
    my $self = shift;
    my $item = shift;
    my $data = shift;

    my $targets = $self->target();
    
    if (!$targets) {
        $self->log()->error( 'No targets found!' );
        return $self->_node_not_exists();
    }
    
    my @item_path = $self->_build_path( $item );
    $self->log()->debug( 'Item path' . Dumper \@item_path);
    
    # Initialize the base connector
    my $baseconn = $self->BASECONNECTOR();

    my $result;
    
    foreach my $target (@{$targets}) {
        
        $self->log()->debug( 'Publication to ' . $target . ' with item ' . Dumper $item );
        
        my @publication_target = $self->_build_path_with_prefix( [ $target, @item_path ] );
        
        $result->{$target} = '';
        my $res;
        if ($self->skip_on_error()) {
            eval{ $res = $baseconn->set( \@publication_target , $data ); };
            if ($EVAL_ERROR) {
                $EVAL_ERROR =~ /\A(.{1,200})/;
                $result->{$target} = $1;
            }
        } else {
            $res = $baseconn->set( \@publication_target , $data );
        }
        $self->log()->debug('Publication result: ' . Dumper $res );
    }

    return $result;    
}

1;

__END__;


=head1 Name

Connector::Iterator

=head1 Description

Helper to perform a I<set> operation over a list of connector endpoints
while handing errors individually for each connector. The return value
is a hashref with the processed target names as key and an empty value
if no errors occured and the exception message if the target failed. You
must set I<skip_on_error> to enable handling of expcetions, otherwise 
they just bubble up and terminate execution of the loop. 

Intended use case: write the same data to multiple targets by using 
multiple connectors. Failed write attemps can be skipped or queued
and redone

=head2 Supported methods

set

=head1 Configuration Example

    my $target = OpenXPKI::Connector::Iterator->new({
        BASECONNECTOR => $config,
        PREFIX => $prefix
    });

    $target->set( [ $data->{issuer}{CN}[0] ], $data );
    
=head1 OPTIONS

=over 

=item BASECONNECTOR

Reference to the connector for the underlying config.

=item PREFIX

The full path to the node above the targets.

=item target

List of targets to iterate thru, must be single path elements!

=item skip_on_error

By default, exceptions from the called connectors bubble up, the loop
over the targets terminate. If set, all connectors are processed and 
any exceptions are returned in the result.

=back    