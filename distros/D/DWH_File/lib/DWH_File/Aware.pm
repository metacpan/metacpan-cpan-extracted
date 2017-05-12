package DWH_File::Aware;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

@ISA = qw( );

# "Declarations" of hooks for DWH_File::Kernel and DWH_File::Value::Factory
sub dwh_tier { return undef }
sub dwh_pre_sign_in { }
sub dwh_post_sign_in { }
sub dwh_activate { }

1;

__END__

=head1 NAME

DWH_File::Aware - 

=head1 SYNOPSIS

DWH_File::Aware is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2003

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Aware.pm,v $
    Revision 1.2  2003/01/21 19:39:59  schmidt
    Added hooks gone missing

    Revision 1.1  2003/01/16 21:37:39  schmidt
    Base class that defines the interface for classes that want control over the way they're stored in DWH_File structures

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

