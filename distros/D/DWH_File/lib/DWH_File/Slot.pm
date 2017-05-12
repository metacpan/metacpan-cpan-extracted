package DWH_File::Slot;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

use UNIVERSAL;

@ISA = qw( );
$VERSION = 0.01;

sub set_value {
    my ( $self, $value ) = @_;
    $self->release;
    $self->{ value } = $value;
    $self->retain;
}

sub release {
    my ( $self ) = @_;
    if ( $self->{ value } and UNIVERSAL::isa( $self->{ value },
					      'DWH_File::Reference' ) ) {
	$self->{ value }->cut_refcount;
    }
}

sub retain {
    my ( $self ) = @_;
    if ( $self->{ value } and UNIVERSAL::isa( $self->{ value },
					      'DWH_File::Reference' ) ) {
	$self->{ value }->bump_refcount;
    }
}

1;

__END__

=head1 NAME

DWH_File::Slot - 

=head1 SYNOPSIS

DWH_File::Slot is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Slot.pm,v $
    Revision 1.2  2002/12/18 22:05:06  schmidt
    methods retain() and release() added for reference counting

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

