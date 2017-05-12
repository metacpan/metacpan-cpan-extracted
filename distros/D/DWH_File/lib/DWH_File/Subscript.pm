package DWH_File::Subscript;

use warnings;
use strict;
use vars qw( @ISA $VERSION );
use overload
    '""' => \&to_string,
    fallback => 1;

@ISA = qw(  );
$VERSION = 0.01;

sub new {
    my ( $this, $string ) = @_;
    my $class = ref $this || $this;
    my $self = \$string;
    bless $self, $class;
    return $self;
}

sub from_input {
    my ( $this, $owner, $actual ) = @_;
    defined $actual or $actual = '';
    return $this->new( pack( 'L', $owner->{ id } ) . $actual );
}

sub to_string {
    return ${ $_[ 0 ] };
}

sub actual {
    my ( $ignore, $actual ) = unpack "La*", ${ $_[ 0 ] };
    return $actual;
}

1;

__END__

=head1 NAME

DWH_File::Subscript - 

=head1 SYNOPSIS

DWH_File::Subscript is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Subscript.pm,v $
    Revision 1.2  2002/10/25 14:04:09  schmidt
    Slight revision of untie and release management

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

