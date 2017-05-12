use strict;
package Algorithm::Metric::Chessboard::Wormhole;

=head1 NAME

Algorithm::Metric::Chessboard::Wormhole - Model a wormhole for Algorithm::Metric::Chessboard.

=head1 DESCRIPTION

See L<Algorithm::Metric::Chessboard>.

=head1 METHODS

=over

=item B<new>

  my $wormhole =
    Algorithm::Metric::Chessboard::Wormhole->new(
                                                  x => 5,
                                                  y => 30,
                                                  id => "Warp Gate",
                                                );

C<x> and C<y> are mandatory.  C<id> is optional; it's not used
internally but is provided as a space for you to store any id you
like, in case your program is interested in which wormholes were used
in a journey.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;
    $self->x( $args{x} );
    $self->y( $args{y} );
    $self->id( $args{id} );
    return $self;
}

sub x {
    my ($self, $value) = @_;
    $self->{x} = $value if $value;
    return $self->{x};
}

sub y {
    my ($self, $value) = @_;
    $self->{y} = $value if $value;
    return $self->{y};
}

sub id {
    my ($self, $value) = @_;
    $self->{id} = $value if $value;
    return $self->{id};
}


=back

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2004 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
