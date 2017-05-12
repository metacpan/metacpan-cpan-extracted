package DWH_File::Work;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

use DWH_File::Kernel;
use DWH_File::Tie::Hash;

@ISA = qw( DWH_File::Tie::Hash );
$VERSION = 0.01;

sub TIEHASH {
    my $class = shift;
    my $kernel = DWH_File::Kernel->new( @_ );
    my $self = delete $kernel->{ work };
    $kernel->{ cache }->decache( $self );
    return $self;
}

sub tie_reference {
    my $this = shift;
    $_[ 5 ] = 'DWH_File::Tie::Hash';
    return $this->SUPER::tie_reference( @_ );
}

sub wipe {
    if ( $_[ 0 ]->{ kernel }{ alive } ) {
	$_[ 0 ]->{ kernel }->wipe;
    }
}

1;

__END__

=head1 NAME

DWH_File::Work - 

=head1 SYNOPSIS

DWH_File::Work is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Work.pm,v $
    Revision 1.3  2003/01/16 21:19:39  schmidt
    Overrides tie_reference to provide a special tie class parameter.
    This is due to redesign that doesn't hard-code the classes
    used to tie references i the DWH_File::Tie subclasses.

    Revision 1.2  2002/10/25 14:04:10  schmidt
    Slight revision of untie and release management

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

