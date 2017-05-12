package DWH_File::Tie::Hash::Node;

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
    my $self = { pred => undef,
                 succ => undef,
                };
    bless $self, $class;
    return $self;
}

sub from_stored {
    my ( $this, $kernel, $data, $subscript ) = @_;
    my $self = $this->new;
    my ( $pred_len, $succ_len ) = unpack "ll", $data;
    my $pl = $pred_len > 0 ? $pred_len : 0;
    my $sl = $succ_len > 0 ? $succ_len : 0;
    my ( $ignore, $pred_string, $succ_string, $value_string ) =
        unpack "a8 a$pl a$sl a*", $data;
    $pred_len > 0 and $self->{ pred } = DWH_File::Value::Factory->
	                                from_stored( $kernel, $pred_string );
    $succ_len > 0 and $self->{ succ } = DWH_File::Value::Factory->
	                                from_stored( $kernel, $succ_string );
    $self->{ value } = DWH_File::Value::Factory->from_stored( $kernel,
							      $value_string );
    $self->{ subscript } = $subscript;
    return $self;
}

sub to_string {
    my ( $pred, $succ ) = @{ $_[ 0 ] }{ qw( pred succ) };
    my ( $pl, $sl );
    $pl = defined $pred ? length( "$pred" ) : -1;
    $sl = defined $succ ? length( "$succ" ) : -1;
    unless ( defined $pred ) { $pred = '' }
    unless ( defined $succ ) { $succ = '' }
    my $res = pack( "ll", $pl, $sl ) . "$pred$succ$_[ 0 ]->{ value }";
    return $res;
}

sub set_successor { $_[ 0 ]->{ succ } = $_[ 1 ] }

sub set_predecessor { $_[ 0 ]->{ pred } = $_[ 1 ] }

1;

__END__

=head1 NAME

DWH_File::Tie::Hash::Node - 

=head1 SYNOPSIS

DWH_File::Tie::Hash::Node is part of the DWH_File distribution.
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
    Revision 1.3  2003/03/30 22:18:17  schmidt
    Nodes remember their subscript while in main memory

    Revision 1.2  2002/12/18 22:15:55  schmidt
    Now supports references as keys

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

