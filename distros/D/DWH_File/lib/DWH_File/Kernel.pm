package DWH_File::Kernel;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

use UNIVERSAL;

use DWH_File::ID_Mill;
use DWH_File::Cache;
use DWH_File::Registry::URI;
use DWH_File::Registry::Class;
use DWH_File::Value::Factory;

use URI::file;

@ISA = qw( );
$VERSION = 0.01;

sub new {
    my $this = shift;
    my $file = $_[ 0 ];
    my $class = ref $this || $this;
    my %dummy = ();
    my $dbm = tie %dummy, $DWH_File::default_dbm, @_;
    unless ( $dbm ) { die "Failed to create dbm file $file: $!" }
    my $self = { dbm => $dbm,
		 file => $file,
                 cache => DWH_File::Cache->new,
                 garbage => {},
		 dummy => \%dummy,
		 alive => 1,
                };
    bless $self, $class;
    $self->{ id_mill } = DWH_File::ID_Mill->new( $self, 'id_mill' );
    $self->{ id_mill }{ current } ||= 0;
    $self->{ uri_pool } = DWH_File::Registry::URI->new( $self, 'uri_pool' );
    DWH_File::Registry::URI->register( $self );
    $self->{ class_pool } = DWH_File::Registry::Class->new( $self,
							    'class_pool' );
    my $worker_id = $self->fetch_property( 'worker' );
    if ( defined $worker_id ) {
	$self->{ work } = $self->activate_by_id( $worker_id );
    }
    else {
        $self->{ work } = DWH_File::Value::Factory->from_input( $self, {},
						       'DWH_File::Work' );
        $self->store_property( 'worker', $self->{ work }{ id } );
    }
    return $self;
}

sub uri {
    return URI::file->new_abs( $_[ 0 ]->{ file } );
}

sub store {
    $_[ 0 ]->{ dbm }->STORE( @_[ 1, 2 ] );
}

sub store_property {
    $_[ 0 ]->store( pack( 'La*', 0, $_[ 1 ] ), $_[ 2 ] );
}

sub fetch {
    return $_[ 0 ]->{ dbm }->FETCH( $_[ 1 ] );
}

sub fetch_property {
    return $_[ 0 ]->fetch( pack 'La*', 0, $_[ 1 ] );
}

sub delete {
    $_[ 0 ]->{ dbm }->DELETE( $_[ 1 ] );
}

sub next_id {
    return $_[ 0 ]->{ id_mill }->next;
}

sub save_state {
    $_[ 0 ]->{ id_mill }->save;
    $_[ 0 ]->{ class_pool }->save;
    $_[ 0 ]->{ uri_pool }->save;
}

sub class_id {
    $_[ 0 ]->{ class_pool }->class_id( $_[ 1 ] );
}

sub reference_string {
    my $tag;
    if ( $_[ 1 ]->{ kernel } == $_[ 0 ] ) { $tag = 0 }
    else { $tag = $_[ 0 ]->{ uri_pool }->tag( $_[ 1 ]->{ kernel } ) }
    pack "aSL", '^', $tag, $_[ 1 ]->{ id };
}

sub activate_reference {
    my ( $self, $stored ) = @_;
    my ( $head, $tag, $id ) =
	unpack "aSL", $stored;
    $head eq '^' or return undef;
    if ( $tag ) {
        return DWH_File::Tie::Foreign->
	    new( $self, $self->{ uri_pool }->retrieve( $tag )->
		 activate_by_id( $id ) );
    }
    else { return $self->activate_by_id( $id ) }
}

sub activate_by_id {
    my ( $self, $id ) = @_;
    my $val_obj;
    unless ( $val_obj = $self->{ cache }->retrieve( $id ) ) {
	my $ground = $self->fetch( pack "L", $id );
	my ( $tie_class_id, $blessing_id, $refcount, $tail )
	    = unpack "SSLa*", $ground;
        my $ref;
        my $tie_class = $self->{ class_pool }->fetch( $tie_class_id );
        my $blessing = $self->{ class_pool }->fetch( $blessing_id );
        $tie_class or die "Invalid class id: '$tie_class_id'";
        $val_obj = $tie_class->tie_reference( $self, $ref, $blessing,
					      $id, $tail );
	if ( UNIVERSAL::isa( $ref, 'DWH_File::Aware' ) ) {
	    $ref->dwh_activate( $val_obj );
	}
    }
    return $val_obj;
}

sub ground_reference {
    my ( $self, $value_obj ) = @_;
    unless ( ref $value_obj and
             $value_obj->isa( 'DWH_File::Value' ) and
             $value_obj->isa( 'DWH_File::Reference' ) ) {
        die "ground_reference() called for inapproproate object";
    }
    my $ground = pack "SSLa*", $self->class_id( $value_obj ),
                               $self->class_id( $value_obj->actual_value ),
                               0, # refcount
                               $value_obj->custom_grounding;
    $self->store( pack( "L", $value_obj->{ id } ), $ground );
}

sub save_custom_grounding {
    my ( $self, $value_obj ) = @_;
    unless ( ref $value_obj and
             $value_obj->isa( 'DWH_File::Value' ) and
             $value_obj->isa( 'DWH_File::Reference' ) ) {
	die "save_custom_grounding() called for inapproproate object";
    }
    my $id = $value_obj->{ id };
    defined $id or return;
    my $idstring = pack "L", $id;
    my $ground = $self->fetch( $idstring ) or return;
    my ( $pre ) = unpack "a8", $ground;
    $pre or return;
    $self->store( $idstring, pack "a8a*", $pre,
                  $value_obj->custom_grounding );
}

sub unground {
    my ( $self, $value_obj ) = @_;
    unless ( ref $value_obj and
             $value_obj->isa( 'DWH_File::Value' ) and
             $value_obj->isa( 'DWH_File::Reference' ) ) {
        die "unground() called for inapproproate object";
    }
    $self->delete( pack( "L", $value_obj->{ id } ) );
}

sub bump_refcount {
    my ( $self, $id ) = @_;
    my $idstring = pack "L", $id;
    my ( $pre, $refcount, $post ) = unpack "a4La*", $self->fetch( $idstring );
    $refcount++;
    $self->store( $idstring, pack( "a4La*", $pre, $refcount, $post ) );
    delete $self->{ garbage }{ $id };
}

sub cut_refcount {
    my ( $self, $id ) = @_;
    my $idstring = pack "L", $id;
    my ( $pre, $refcount, $post ) = unpack "a4La*",
                                           $self->fetch( $idstring );
    $refcount--;
    $self->store( $idstring, pack "a4La*", $pre, $refcount, $post );
    if ( $refcount == 0 ) { $self->{ garbage }{ $id } = 1 }
    elsif ( $refcount < 0 ) { die "Negative refcount exception! [$id]" }
}

sub tieing {
    $_[ 0 ]->{ cache }->encache( $_[ 1 ] );
}

sub did_tie {
}

sub purge_garbage {
    while ( my @goids = keys %{ $_[ 0 ]->{ garbage } } ) {
        for my $goid ( @goids ) {
            my $goner = $_[ 0 ]->activate_by_id( $goid );
            if ( $goner and
                 UNIVERSAL::isa( $goner, 'DWH_File::Reference' ) ) {
                 $goner->vanish;
                 delete $_[ 0 ]->{ garbage }{ $goid };
            }
            else { warn "Garbage anomaly: $goid ~ $goner" }
        }
    }
}

sub release {
    my ( $self ) = @_;
    $self->{ uri_pool }->release( $self );
    delete $_[ 0 ]->{ dbm };
    untie %{ $_[ 0 ]->{ dummy } };
    $self->{ alive } = 0;
}

sub wipe {
    my ( $self ) = @_;
    $self->save_state;
    $self->purge_garbage;
    $self->release;
}

1;

__END__

=head1 NAME

DWH_File::Kernel - 

=head1 SYNOPSIS

DWH_File::Kernel is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Kernel.pm,v $
    Revision 1.7  2003/01/16 21:10:08  schmidt
    Calls dwh_activate() hook for objects that have DWH_File::Aware in their heritage

    Revision 1.6  2002/12/20 20:10:28  schmidt
    Now using URI module for uri. (Plus renamed parameter)

    Revision 1.5  2002/12/19 22:00:56  schmidt
    Now uses lazy registration in Registry::URI (tag() function)

    Revision 1.4  2002/12/18 21:59:19  schmidt
    Registry and ClassPool replaced by Registry::URI and Registry::Class
    Methods for storing kernel-properties added. These are used by
    ID_Mills, Workers, Class pools etc. in stead of opaque codes.
    uri method for the Registry::URI put in but needs much smarting
    Uses Tie::Foreign proxy for data owned by different instances of
    Kernel

    Revision 1.3  2002/10/25 14:25:35  schmidt
    Enabled use of specific DBM module (as in documentation)

    Revision 1.2  2002/10/25 14:04:09  schmidt
    Slight revision of untie and release management

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

