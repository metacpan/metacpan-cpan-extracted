package DWH_File::Value::Undef;

use warnings;
use strict;
use vars qw( @ISA $VERSION );
use overload
    '""' => \&store_string,
    fallback => 1;

@ISA = qw( DWH_File::Value );
$VERSION = 0.01;

sub new {
    my ( $this ) = @_;
    my $class = ref $this || $this;
    my $none = '';
    my $self = \$none;
    bless $self, $class;
    return $self;
}

sub from_input {
    my ( $this ) = @_;
    return $this->new;
}

sub from_stored {
    my ( $this ) = @_;
    return $this->new;
}

sub store_string { '%' }

sub actual_value { undef }

1;

__END__

=head1 NAME

DWH_File::Value::Undef - 

=head1 SYNOPSIS

DWH_File::Value::Undef is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Undef.pm,v $
    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

