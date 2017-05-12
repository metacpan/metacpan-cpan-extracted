package DWH_File::Tie::Scalar;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

use DWH_File::Slot;

@ISA = qw( DWH_File::Tie DWH_File::Slot );
$VERSION = 0.01;

sub TIESCALAR {
    my $this = shift;
    my $self = $this->perform_tie( @_ );
}

sub STORE {
    my ( $self, $value_in ) = @_;
    $self->set_value( DWH_File::Value::Factory->from_input( $self->{ kernel },
                                                   $value_in ) );
    # make lazy
    $self->{ kernel }->save_custom_grounding( $self );
}

sub FETCH { $_[ 0 ]->{ value }->actual_value }

sub tie_reference {
    my $text;
    $_[ 2 ] ||= \$text;
    my ( $this, $kernel, $ref, $blessing, $id, $tail ) = @_;
    my $class = ref $this || $this;
    $blessing ||= ref $ref;
    my $instance = tie $$ref, $class, $kernel,
                       $ref, $id, $tail;
    if ( $blessing ne 'SCALAR' ) { bless $ref, $blessing }
    return $instance;
}

sub wake_up_call {
    my ( $self, $tail ) = @_;
    unless ( defined $tail ) { die "Tail anomaly" }
    $self->{ value } = DWH_File::Value::Factory->from_stored(
							 $self->{ kernel },
							 $tail );
}

sub sign_in_first_time {
    my ( $self ) = @_;
    $self->set_value( DWH_File::Value::Factory->
                      from_input( $self->{ kernel },
                                  ${ $self->{ content } } ) );
}

sub custom_grounding { $_[ 0 ]->{ value } }

sub vanish {
    my ( $self ) = @_;
    $self->release;
    $self->{ kernel }->unground( $self );
}

1;

__END__

=head1 NAME

DWH_File::Tie::Scalar - 

=head1 SYNOPSIS

DWH_File::Tie::Scalar is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Scalar.pm,v $
    Revision 1.3  2003/01/16 21:30:02  schmidt
    Dynamic binding of tie class in tie_reference()

    Revision 1.2  2002/12/18 22:21:21  schmidt
    Uses new Slot method for frecounting

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

