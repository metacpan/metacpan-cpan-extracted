package DWH_File::Value::Factory;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

use UNIVERSAL;

use DWH_File::Value::Plain;
use DWH_File::Value::Undef;
use DWH_File::Tie::Scalar;
use DWH_File::Tie::Array;
use DWH_File::Tie::Hash;
use DWH_File::Tie::Foreign;

@ISA = qw(  );
$VERSION = 0.01;

sub from_input {
    my ( $this, $kernel, $actual, $tier ) = @_;
    unless ( defined $actual ) { return DWH_File::Value::Undef->new }
    elsif ( ref $actual ) {
        my $ty;
	if ( UNIVERSAL::isa( $actual, 'DWH_File::Aware' ) ) {
            $tier ||= $actual->dwh_tier;
        }	
	if ( UNIVERSAL::isa( $actual, 'SCALAR' ) ) {
            $ty = tied $$actual or $tier ||= 'DWH_File::Tie::Scalar';
        }
        elsif ( UNIVERSAL::isa( $actual, 'ARRAY' ) ) {
            $ty = tied @$actual or $tier ||= 'DWH_File::Tie::Array';
        }
        elsif ( UNIVERSAL::isa( $actual, 'HASH' ) ) {
            $ty = tied %$actual or $tier ||= 'DWH_File::Tie::Hash'
        }
        else { die "Unable to tie $actual" }
        if ( $ty ) {
            if ( $ty->isa( 'DWH_File::Tie' ) ) {
		if ( $ty->{ kernel } == $kernel ) { return $ty }
		else { return DWH_File::Tie::Foreign->new( $kernel, $ty ) }
	    }
            else { die "Can't handle tied data" }
        }
	else {
	    if ( UNIVERSAL::isa( $actual, 'DWH_File::Aware' ) ) {
		$actual->dwh_pre_sign_in;
	    }
	    $ty = $tier->tie_reference( $kernel, $actual );
	    if ( UNIVERSAL::isa( $actual, 'DWH_File::Aware' ) ) {
		$actual->dwh_post_sign_in( $ty );
	    }
	    $kernel->ground_reference( $ty );
	    return $ty;
	}
    }
    else { return DWH_File::Value::Plain->from_input( $actual ) }
}

sub from_stored {
    my ( $this, $kernel, $stored ) = @_;
    unless ( defined $stored ) { return DWH_File::Value::Undef->new }
    elsif ( $stored eq '%' ) { return DWH_File::Value::Undef->new }
    elsif ( my $val = $kernel->activate_reference( $stored ) ) {
        return $val;
    }
    else { return DWH_File::Value::Plain->from_stored( $stored ) }
}

1;

__END__

=head1 NAME

DWH_File::Value::Factory - 

=head1 SYNOPSIS

DWH_File::Value::Factory is part of the DWH_File distribution. For
user-oriented documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Factory.pm,v $
    Revision 1.3  2003/01/16 21:22:52  schmidt
    Call hooks in objects having DWH_File::Aware in their heritage,
    allowing them to specify the class used to tie them and to
    be informed that they're being tied into a DWH-structure

    Revision 1.2  2002/12/18 22:24:55  schmidt
    Uses Tie::Foreign proxy when kernels differ

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

