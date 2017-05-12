package DWH_File::Registry;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

@ISA = qw(  );
$VERSION = 0.01;

sub new {
    my ( $this, $kernel, $property ) = @_;
    my $class = ref $this || $this;
    my $id = $kernel->fetch_property( $property . ':id' );
    unless ( defined $id ) {
        $id = $kernel->next_id;
        $kernel->store_property( $property . ':id', $id );
    }
    my $self = { id => $id,
                 id_mill => DWH_File::ID_Mill->new( $kernel,
						    $property . ':id_mill' ),
                 kernel => $kernel,
                };
    $self->{ id_mill }{ current } ||= 0;
    bless $self, $class;
    return $self;
}

sub save {
    $_[ 0 ]->{ id_mill }->save;
}

sub fetch {
    $_[ 0 ]->{ kernel }->fetch( pack "LaS", $_[ 0 ]->{ id }, '>', $_[ 1 ] );
}

sub fetch_key_pack {
    $_[ 0 ]->{ kernel }->fetch( pack "Laa*", $_[ 0 ]->{ id }, '<', $_[ 1 ] );
}

sub store {
    my ( $self, $subscript, $value ) = @_;
    my $id_p = pack "L", $self->{ id };
    $self->{ kernel }->store( "$id_p>$subscript", $value );
    $self->{ kernel }->store( "$id_p<$value", $subscript );
}

sub get_key {
    my ( $self, $value ) = @_;
    my $key_p = $self->fetch_key_pack( $value );
    my $key;
    if ( defined $key_p ) { $key = unpack "S", $key_p }
    else {
        $key = $self->{ id_mill }->next;
        $key_p = pack "S", $key;
	$self->store( $key_p, $value );
    }
    return $key;
}

1;

__END__

=head1 NAME

DWH_File::Registry - 

=head1 SYNOPSIS

DWH_File::ClassPool is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Registry.pm,v $
    Revision 1.3  2002/12/18 22:02:30  schmidt
    The Registry class is now an abstract superclass for the -::URI (which
    replaces the old Registry class) and -::Class (which repaces the old
    ClassPool class). A registry is a persistent two-way dictionary
    within a given kernels data.

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

