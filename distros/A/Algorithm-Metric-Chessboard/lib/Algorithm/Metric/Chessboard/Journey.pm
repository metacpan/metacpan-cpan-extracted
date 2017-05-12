use strict;
package Algorithm::Metric::Chessboard::Journey;

=head1 NAME

Algorithm::Metric::Chessboard::Journey - Model a journey on an Algorithm::Metric::Chessboard grid.

=head1 DESCRIPTION

See L<Algorithm::Metric::Chessboard>.

=head1 METHODS

=over

=item B<new>

  my $wormhole_a =
    Algorithm::Metric::Chessboard::Wormhole->new( x => 3, y => 9 );
  my $wormhole_b =
    Algorithm::Metric::Chessboard::Wormhole->new( x => 40, y => 70 );

  my $journey =
    Algorithm::Metric::Chessboard::Journey->new(
        start    => [ 3, 10 ],
        end      => [ 45, 78 ],
        via      => [ $wormhole_a, $wormhole_b ],
        distance => 10,
                                                );

This is purely a data object.  You don't want to call this directly;
it's used internally by L<Algorithm::Metric::Chessboard>.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;
    $self->start( $args{start} );
    $self->end( $args{end} );
    $self->via( $args{via} );
    $self->distance( $args{distance} );
    return $self;
}

sub start {
    my ($self, $value) = @_;
    $self->{start} = $value if $value;
    return $self->{start};
}

sub end {
    my ($self, $value) = @_;
    $self->{end} = $value if $value;
    return $self->{end};
}

sub via {
    my ($self, $value) = @_;
    $self->{via} = $value if $value;
    my $via = $self->{via} || [];
    return wantarray ? @$via : $via;
}

sub distance {
    my ($self, $value) = @_;
    $self->{distance} = $value if $value;
    return $self->{distance};
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
