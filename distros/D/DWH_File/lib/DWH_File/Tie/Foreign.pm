package DWH_File::Tie::Foreign;

use warnings;
use strict;
use vars qw( @ISA $VERSION );
use overload
    '""' => \&to_string,
    fallback => 1;

use DWH_File::Value;
use DWH_File::Reference;

@ISA = qw( DWH_File::Value DWH_File::Reference );
$VERSION = 0.01;

sub new {
    my ( $this, $client, $value ) = @_;
    my $class = ref( $this ) || $this;
    my $self = { client => $client,
                 value => $value,
		 string_val => '',
                };
    bless $self, $class;
    return $self;
}

sub to_string {
    $_[ 0 ]->{ string_val } ||= $_[ 0 ]->{ client }->
                                reference_string( $_[ 0 ]->{ value } );
}

sub actual_value { $_[ 0 ]->{ value }->actual_value }

sub bump_refcount { $_[ 0 ]->{ value }->bump_refcount }

sub cut_refcount { $_[ 0 ]->{ value }->cut_refcount }

1;

__END__

=head1 NAME

DWH_File::Tie::Foreign - 

=head1 SYNOPSIS

DWH_File::Tie::Foreign is part of the DWH_File distribution.
For user-oriented documentation, see DWH_File documentation
(perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Foreign.pm,v $
    Revision 1.1  2002/12/18 22:23:30  schmidt
    New class working as a proxy for references to data in other kernels

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

