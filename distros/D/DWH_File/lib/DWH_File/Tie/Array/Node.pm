package DWH_File::Tie::Array::Node;

use warnings;
use strict;
use vars qw( @ISA $VERSION );
use overload
    '""' => \&to_string,
    fallback => 1;

use DWH_File::Slot;

@ISA = qw( DWH_File::Slot );
$VERSION = 0.01;

sub new {
    my ( $this ) = @_;
    my $class = ref( $this ) || $this;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub from_stored {
    my ( $this, $kernel, $data, $subscript ) = @_;
    my $self = $this->new;
    $self->{ value } = DWH_File::Value::Factory->from_stored( $kernel, $data );
    $self->{ subscript } = $subscript;
    return $self;
}

sub to_string { "$_[ 0 ]->{ value }" }

1;

__END__

=head1 NAME

DWH_File::Tie::Array::Node - 

=head1 SYNOPSIS

DWH_File::Tie::Array::Node is part of the DWH_File distribution.
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

    $Log: Node.pm,v $
    Revision 1.2  2003/03/30 22:18:26  schmidt
    Nodes remember their subscript while in main memory

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

