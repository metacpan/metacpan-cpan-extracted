package DWH_File::Registry::Class;

use warnings;
use strict;
use vars qw( @ISA $VERSION );
use DWH_File::Registry;

@ISA = qw( DWH_File::Registry );
$VERSION = 0.01;

sub class_id {
    my ( $self, $that ) = @_;
    my $the_class = ref $that || $that;
    return $self->get_key( $the_class );
}

1;

__END__

=head1 NAME

DWH_File::Registry::Class - 

=head1 SYNOPSIS

DWH_File::Registry::Class is part of the DWH_File distribution.
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

    $Log: Class.pm,v $
    Revision 1.1  2002/12/19 21:58:43  schmidt
    This module repaces ClassPool.pm



