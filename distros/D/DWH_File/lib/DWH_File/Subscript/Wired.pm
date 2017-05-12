package DWH_File::Subscript::Wired;

use warnings;
use strict;
use vars qw( @ISA $VERSION );
use overload
    '""' => \&to_string,
    fallback => 1;

use DWH_File::Subscript;
use DWH_File::Slot;

@ISA = qw( DWH_File::Subscript DWH_File::Slot );
$VERSION = 0.01;

sub new {
    my ( $this, $owner, $value ) = @_;
    my $class = ref $this || $this;
    my $self = { owner => $owner,
		 value => $value,
		 };
    bless $self, $class;
    return $self;
}

sub from_input {
    my ( $this, $owner, $actual ) = @_;
    defined $actual or $actual = '';
    return $this->new( $owner, DWH_File::Value::Factory->
		               from_input( $owner->{ kernel }, $actual ) );
}

sub to_string {
    return pack( "L", $_[ 0 ]->{ owner }{ id } ) . $_[ 0 ]->{ value };
}

sub actual {
    return $_[ 0 ]->{ value }->actual_value;
}

1;

__END__

=head1 NAME

DWH_File::Subscript::Wired - 

=head1 SYNOPSIS

DWH_File::Subscript::Wired is part of the DWH_File distribution. 
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

    $Log: Wired.pm,v $
    Revision 1.1  2002/12/19 22:02:32  schmidt
    Handles hash keys which are live references

