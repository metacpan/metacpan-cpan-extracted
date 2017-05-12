package DWH_File::Tie::Array;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

use DWH_File::Subscript;
use DWH_File::Value::Factory;
use DWH_File::Tie::Subscripted;
use DWH_File::Tie::Array::Node;

@ISA = qw( DWH_File::Tie::Subscripted );
$VERSION = 0.01;

sub TIEARRAY {
    my $this = shift;
    my $self = $this->perform_tie( @_ );
    #$self->{ cache } = DWH_File::Cache->new;
}

sub FETCHSIZE {
    my ( $self ) = @_;
    return $self->{ size } || 0;
}

sub STORESIZE {
    my ( $self, $size ) = @_;
    my $oldsize = $self->{ size } || 0;
    $self->{ size } = $size;
    my $kernel = $self->{ kernel };
    # make lazy
    $kernel->save_custom_grounding( $self );
    my $nc = $self->node_class;
    for ( my $i = $size; $i < $oldsize; $i++ ) {
        my $subscript = DWH_File::Subscript->from_input( $self, $i );
        my $data = $kernel->delete( $subscript );
	if ( $data ) {
	    $nc->from_stored( $kernel, $data )->release;
	}
    }
}

sub CLEAR { $_[ 0 ]->STORESIZE( 0 ) }

sub POP {
    my ( $self ) = @_;
    $self->{ size } or return undef;
    my $value = $self->DELETE( $self->{ size } - 1 );
    $self->{ size }--;
    $self->{ kernel }->save_custom_grounding( $self );
    return $value;
}

sub PUSH {
    my $self = shift; # @_ contains data to be pushed
    @_ or return;
    my $i = $self->{ size };
    my $kernel = $self->{ kernel };
    my $nc = $self->node_class;
    $self->STORESIZE( $i + @_ );
    for my $v ( @_ ) {
	my $subscript = DWH_File::Subscript->from_input( $self, $i );
	my $value = DWH_File::Value::Factory->from_input( $kernel, $v );
	my $node = $nc->new;
	$node->set_value( $value );
	# make lazy
	$kernel->store( $subscript, $node );
	$i++;
    }
}

sub SHIFT {
    my ( $self ) = @_;
    return $self->SPLICE( 0, 1 );
}

sub UNSHIFT {
    my $self = shift; # @_ contains data to be unshifted
    return $self->SPLICE( 0, 0, @_ );
}

sub SPLICE {
    my $self = shift;
    my $offset = shift;
    my $length = shift;
    # @_ contains data to be inserted
    my $insert_length = @_;

    if ( $offset > $self->{ size } ) { $offset = $self->{ size } }
    elsif ( $self->{ size } == 0 ) { $offset = 0 }
    else { while ( $offset < 0 ) { $offset += $self->{ size } } }

    my $last = $offset + $length - 1;
    if ( $last >= $self->{ size } ) { $last = $self->{ size } - 1 }
    $length = $last - $offset + 1;
    my @return = map { $self->DELETE( $_ ) } ( $offset..$last );

    if ( $insert_length ) {
    	if ( $last < $self->{ size } - 1
    	     and $offset < $self->{ size }
    	     and $insert_length != $length ) {
    	    $self->shove( $last + 1, $insert_length - $length );
	    $self->{ size } += $insert_length - $length;
	    # make lazy
	    $self->{ kernel }->save_custom_grounding( $self );
    	}
    	for my $v ( @_ ) {
    	    $self->STORE( $offset++, $v );
    	}
    }
    elsif ( $length ) {
    	if ( $last < $self->{ size } - 1 ) {
    	    $self->shove( $last + 1, -$length );
    	}
	$self->{ size } -= $length;
	# make lazy
	$self->{ kernel }->save_custom_grounding( $self );
    }

    wantarray and return @return;
    return $return[ 0 ];
}

sub DELETE {
    my ( $self, $index ) = @_;
    # check semantics. In this interpretation deleting never
    # affects the size of the array - it only differs from
    # the assignment of undef in terms of the way EXISTS()
    # responds (and as a side effect, in terms of space
    # complexity).
    my $subscript = DWH_File::Subscript->from_input( $self, $index );
    if ( my $node = $self->get_node( $subscript ) ) {
	my $value = $node->{ value }->actual_value;
	$node->release;
	$self->{ kernel }->delete( $subscript );
	return $value;
    }
    else { return undef }
}

sub EXTEND {
    my ( $self, $count ) = @_;
    # no-op in this class
}

sub shove {
    my ( $self, $start, $amount ) = @_;
    if ( $start + $amount < 0 ) { die "anomalous invocation of shove" }
    if ( $amount < 0 ) {
	for my $i ( $start .. ( $self->{ size } - 1 ) ) {
	    $self->move( $i, $amount );
	}
    }
    elsif ( $amount > 0 ) {
	for my $i ( 0 .. ( $self->{ size } - 1 - $start ) ) {
	    $self->move( $self->{ size } - 1 - $i, $amount );
	}
    }
}

sub move {
    my ( $self, $from, $amount ) = @_;
    my $subscript = DWH_File::Subscript->from_input( $self, $from );
    my $node_string = $self->{ kernel }->fetch( $subscript );
    $self->{ kernel }->delete( $subscript );
    $subscript = DWH_File::Subscript->from_input( $self, $from + $amount );
    $self->{ kernel }->store( $subscript, $node_string );
}

sub tie_reference {
    $_[ 2 ] ||= [];
    my ( $this, $kernel, $ref, $blessing, $id, $tail ) = @_;
    my $class = ref $this || $this;
    $blessing ||= ref $ref;
    my $instance = tie @$ref, $class,
                       $kernel, $ref, $id, $tail;
    if ( $blessing ne 'ARRAY' ) { bless $ref, $blessing }
    return $instance;
}

sub wake_up_call {
    my ( $self, $tail ) = @_;
    unless ( defined $tail ) { die "Tail anomaly" }
    $self->{ size } = int $tail;
}

sub sign_in_first_time {
    my ( $self ) = @_;
    my $i = 0;
    for my $v ( @{ $self->{ content } } ) {
	$self->STORE( $i, $v );
	$i++;
    }
}

sub node_class { 'DWH_File::Tie::Array::Node' }

sub handle_new_node {
    my ( $self, $node, $subscript ) = @_;
    my $index = $subscript->actual;
    if ( $index >= $self->FETCHSIZE ) { $self->STORESIZE( $index + 1 ) }
}

sub custom_grounding {
    return $_[ 0 ]->FETCHSIZE;
}

1;

__END__

=head1 NAME

DWH_File::Tie::Array - 

=head1 SYNOPSIS

DWH_File::Tie::Array is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Array.pm,v $
    Revision 1.4  2003/01/16 21:24:42  schmidt
    CLEAR implemented (by means of STORESIZE) + tie_reference() modified
    to allow dynamic binding to tier class

    Revision 1.3  2002/12/18 22:22:13  schmidt
    Uses new Slot methods for recounting

    Revision 1.2  2002/11/02 22:41:54  schmidt
    Bug-fix in PUSH

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

