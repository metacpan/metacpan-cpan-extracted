package DWH_File::Cache;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

@ISA = qw(  );
$VERSION = 0.1;

sub new {
    my ( $this ) = @_;
    my $class = ref $this || $this;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub encache {
    # weaken if available
    $_[ 0 ]->{ $_[ 1 ]->cache_key } = $_[ 1 ];
    $_[ 1 ]->cache_up;
}

sub decache {
    delete $_[ 0 ]->{ $_[ 1 ]->cache_key };
    $_[ 1 ]->cache_down;
}

sub retrieve {
    if ( exists $_[ 0 ]->{ $_[ 1 ] } ) { return $_[ 0 ]->{ $_[ 1 ] } }
    else { return undef }
}


1;

__END__

=head1 NAME

DWH_File::Cache - 

=head1 SYNOPSIS

DWH_File::Cache is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Cache.pm,v $
    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

