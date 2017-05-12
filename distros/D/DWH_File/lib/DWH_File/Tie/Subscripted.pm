package DWH_File::Tie::Subscripted;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

use DWH_File::Subscript;
use DWH_File::Value::Factory;
use DWH_File::Tie;

@ISA = qw( DWH_File::Tie );
$VERSION = 0.01;

sub STORE {
    my ( $self, $key, $value_in ) = @_;
    my $subscript = $self->get_subscript( $key );
    my $value = DWH_File::Value::Factory->from_input( $self->{ kernel },
						      $value_in );
    my $node = $self->get_node( $subscript );
    unless ( $node ) {
	$node = $self->node_class->new;
	$self->handle_new_node( $node, $subscript, $value );
    }
    $node->set_value( $value );
    # make lazy
    $self->{ kernel }->store( $subscript, $node );
}

sub FETCH {
    my $subscript = $_[ 0 ]->get_subscript( $_[ 1 ] );
    my $node = $_[ 0 ]->get_node( $subscript ) or return undef;
    return $node->{ value }->actual_value;
}

sub EXISTS {
    my $subscript = $_[ 0 ]->get_subscript( $_[ 1 ] );
    my $node = $_[ 0 ]->get_node( $subscript ) or return 0;
    return 1;
}

sub get_subscript {
    return DWH_File::Subscript->from_input( @_[ 0, 1 ] );
}

sub get_node {
    my ( $self, $subscript ) = @_;
    my $data = $self->{ kernel }->fetch( $subscript );
    if ( $data ) {
	return $self->node_class->from_stored( $self->{ kernel },
					       $data, $subscript );
    }
    else { return undef }
}

sub CLEAR { die "Abstract method called" }

sub vanish {
    my ( $self ) = @_;
    $self->CLEAR;
    $self->{ kernel }->unground( $self );
}

1;

__END__

=head1 NAME

DWH_File::Tie::Subscripted - 

=head1 SYNOPSIS

DWH_File::Tie::Subscripted is part of the DWH_File distribution. For
user-oriented documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Subscripted.pm,v $
    Revision 1.4  2003/03/30 22:17:09  schmidt
    Addede value param for DWH_Lib use in handle_new_node()

    Revision 1.3  2003/01/16 21:29:32  schmidt
    Declaration of method CLEAR

    Revision 1.2  2002/12/18 22:20:33  schmidt
    Slight refactoring

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

