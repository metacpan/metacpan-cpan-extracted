package DWH_File::Value::Plain;

use warnings;
use strict;
use vars qw( @ISA $VERSION );
use overload
    '""' => \&store_string,
    fallback => 1;

@ISA = qw( DWH_File::Value );
$VERSION = 0.01;

sub new {
    my ( $this, $data ) = @_;
    my $class = ref $this || $this;
    my $self = \$data;
    bless $self, $class;
    return $self;
}

sub from_input {
    my ( $this, $data ) = @_;
    my $first = substr $data, 0, 1;
    if ( $first eq '^' or $first eq '%' ) { substr( $data, 0, 0 ) = '%' }
    return $this->new( $data );
}

sub from_stored {
    my ( $this, $data ) = @_;
    return $this->new( $data );
}

sub store_string { ${ $_[ 0 ] } }

sub actual_value {
    my $data = ${ $_[ 0 ] };
    '%' eq substr $data, 0, 1 and substr( $data, 0, 1 ) = '';
    $data;
}

1;

__END__

=head1 NAME

DWH_File::Value::Plain - 

=head1 SYNOPSIS

DWH_File::Value::Plain is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Plain.pm,v $
    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

