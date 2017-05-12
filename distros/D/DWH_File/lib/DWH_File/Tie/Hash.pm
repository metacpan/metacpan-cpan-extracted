package DWH_File::Tie::Hash;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

use DWH_File::Subscript::Wired;
use DWH_File::Tie::Subscripted;
use DWH_File::Tie::Hash::Node;

@ISA = qw( DWH_File::Tie::Subscripted );
$VERSION = 0.01;

sub TIEHASH {
    my $this = shift;
    my $self = $this->perform_tie( @_ );
    #$self->{ cache } = DWH_File::Cache->new;
}

sub DELETE {
    my ( $self, $key ) = @_;
    my $subscript = $self->get_subscript( $key );
    my $node = $self->get_node( $subscript ) or return undef;
    my ( $p_node, $s_node, $p_sub, $s_sub );
    if ( defined $node->{ pred } ) {
	$p_sub = $self->subscript_from_value_object( $node->{ pred } );
	$p_node = $self->get_node( $p_sub );
    }
    if ( defined $node->{ succ } ) {
	$s_sub = $self->subscript_from_value_object( $node->{ succ } );
	$s_node = $self->get_node( $s_sub );
    }
    my $value = $node->{ value };
    $node->release;
    $subscript->release;
    $self->{ kernel }->delete( $subscript );
    if ( not $p_node ) {
	if ( not $s_node ) { $self->{ first } = undef } # first, last, only
	else {
            # first
	    $self->{ first } = $s_sub->{ value };
	    $s_node->{ pred } = undef;
	    $self->{ kernel }->store( $s_sub, $s_node );
	}
	# make lazy
	$self->{ kernel }->save_custom_grounding( $self );
    }
    else {
	if ( not $s_node ) {
            # last
	    $p_node->{ succ } = undef;
	    $self->{ kernel }->store( $p_sub, $p_node );
	}
	else {
            # general (mid)
	    $p_node->{ succ } = $s_sub->{ value };
	    $self->{ kernel }->store( $p_sub, $p_node );
	    $s_node->{ pred } = $p_sub->{ value };
	    $self->{ kernel }->store( $s_sub, $s_node );
	}
    }
    return $value->actual_value;
}

sub CLEAR {
    my ( $self ) = @_;
    my $k = $self->{ first };
    while ( defined $k and defined $k->actual_value ) {
	my $sub = $self->subscript_from_value_object( $k );
	my $node = $self->get_node( $sub );
	$k = $node->{ succ };
	$node->release;
	$sub->release;
	$self->{ kernel }->delete( $sub );
    }
    $self->{ first } = undef;
    $self->{ kernel }->save_custom_grounding( $self );
}

sub FIRSTKEY {
    defined $_[ 0 ]->{ first } ? $_[ 0 ]->{ first }->actual_value : undef;
}

sub NEXTKEY {
    my $subscript = $_[ 0 ]->get_subscript( $_[ 1 ] );
    my $node = $_[ 0 ]->get_node( $subscript ) or return undef;
    return defined $node->{ succ } ? $node->{ succ }->actual_value : undef;
}

sub tie_reference {
    $_[ 2 ] ||= {};
    my ( $this, $kernel, $ref, $blessing, $id, $tail, $tie_class ) = @_;
    my $class = ref $this || $this;
    $tie_class ||= '';
    $blessing ||= ref $ref;
    my $instance = tie %$ref, $tie_class || $class, $kernel, $ref, $id, $tail;
    if ( $blessing ne 'HASH' ) { bless $ref, $blessing }
    $tie_class and bless $instance, $class;
    return $instance;
}

sub wake_up_call {
    my ( $self, $tail ) = @_;
    unless ( defined $tail ) { die "Tail anomaly" }
    my ( $signal, $first ) = unpack "a a*", $tail;
    if ( $signal eq '>' ) {
	$self->{ first } = DWH_File::Value::Factory->
	                   from_stored( $self->{ kernel }, $first );
    }
    elsif ( $signal eq '<' ) { $self->{ first } = undef }
    else { die "Unknown signal byte: '$signal'" }
}

sub sign_in_first_time {
    my ( $self ) = @_;
    while ( my ( $k, $v ) = each %{ $self->{ content } } ) {
	$self->STORE( $k, $v );
    }
}

sub node_class { 'DWH_File::Tie::Hash::Node' }

sub handle_new_node {
    my ( $self, $node, $subscript ) = @_;
    $node->set_successor( $self->{ first } );
    $self->set_first_key( $subscript->{ value } );
    $subscript->retain;
}

sub get_subscript {
    return DWH_File::Subscript::Wired->from_input( @_[ 0, 1 ] );
}

sub subscript_from_value_object {
    return DWH_File::Subscript::Wired->new( @_[ 0, 1 ] );
}

sub set_first_key {
    my ( $self, $new_first ) = @_;
    my $first = $self->FIRSTKEY;
    if ( defined $first ) {
        my $subscript = $self->get_subscript( $first );
        my $node = $self->get_node( $subscript );
        $node->set_predecessor( $new_first );
	# make lazy
	$self->{ kernel }->store( $subscript, $node );
    }
    $self->{ first } = $new_first;
    # make lazy
    $self->{ kernel }->save_custom_grounding( $self );
}

sub custom_grounding {
    my $k = $_[ 0 ]->{ first };
    if ( defined $k and defined $k->actual_value ) { return ">$k" }
    else { return '<' }
}

1;

__END__

=head1 NAME

DWH_File::Tie::Hash - 

=head1 SYNOPSIS

DWH_File::Tie::Hash is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Hash.pm,v $
    Revision 1.4  2003/01/25 20:53:19  schmidt
    Bugfix. The return value of DELETE was invalid

    Revision 1.3  2003/01/16 21:28:34  schmidt
    Dynamic binding of tier class in tie_reference.
    Optional argument to tie_reference added to allow override of dynamic
    binding. Specifically, this is needed by DWH_File::Work

    Revision 1.2  2002/12/18 22:23:06  schmidt
    Support for references as keys added

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

