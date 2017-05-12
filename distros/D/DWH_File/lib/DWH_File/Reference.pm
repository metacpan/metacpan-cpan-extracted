package DWH_File::Reference;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

@ISA = qw( );

sub bump_refcount { die "Abstract method called" }

sub cut_refcount { die "Abstract method called" }

sub vanish { die "Abstract method called" }

1;

__END__

=head1 NAME

DWH_File::Reference - 

=head1 SYNOPSIS

DWH_File::Reference is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Reference.pm,v $
    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

