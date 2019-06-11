package Chart::GGPlot::Position::Stack;

# ABSTRACT: Position for "stack"

use Chart::GGPlot::Class;
use namespace::autoclean;

our $VERSION = '0.0005'; # VERSION

use PDL::Primitive qw(which);

use Chart::GGPlot::Position::Util qw(collide pos_stack);


has var     => ( is => 'ro' );
has vjust   => ( is => 'ro', default => 1 );
has reverse => ( is => 'ro', default => sub { false } );

with qw(Chart::GGPlot::Position);

sub fill { false }

method setup_params ($data) {
    return {
        var     => ( $self->var // $self->stack_var($data) ),
        vjust   => $self->vjust,
        fill    => $self->fill,
        reverse => $self->reverse
    };
}

method setup_data ($data, $params) {
    my $var = $params->at('var');
    if ( defined $var and length($var) ) {
        return $data;
    }

    my $ymax;
    if ( $var eq 'y' ) {
        $ymax = $data->at('y');
    }
    elsif ( $var eq 'ymax' and ( $data->at('ymax') == 0 )->all ) {
        $ymax = $data->at('ymin');
    }
    $data->set( 'ymax', $ymax ) if defined $ymax;

    remove_missing(
        $data,
        vars => [qw(x xmin xmax y)],
        name => 'position_stack'
    );
}

method compute_panel ($data, $params, $scales) {
    my $var = $params->at('var');
    unless ($var) {
        return $data;
    }

    my $negative = $data->at($var) < 0;
    my $neg      = $data->select_rows( which($negative) );
    my $pos      = $data->select_rows( which( !$negative ) );

    if ( $neg->nrow ) {
        $neg = collide( $neg, undef, 'position_stack', \&pos_stack,
            map { $_ => $params->at($_) } qw(vjust fill reverse) );
    }
    if ( $pos->nrow ) {
        $pos = collide( $pos, undef, 'position_stack', \&pos_stack,
            map { $_ => $params->at($_) } qw(vjust fill reverse) );
    }

    return $neg->rbind($pos);
}

classmethod stack_var ($data) {
    if ( $data->exists('ymax') ) {
        return 'ymax';
    }
    elsif ( $data->exists('y') ) {
        return 'y';
    }

    warn "Stacking requires either ymin & ymax or y aesthetics";
    return undef;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Position::Stack - Position for "stack"

=head1 VERSION

version 0.0005

=head1 DESCRIPTION

This stacks bars on top of each other.

=head1 ATTRIBUTES

=head2 reverse

If true, will reverse the default stacking order.
This is useful if you're rotating both the plot and legend.
Default is false.

=head1 SEE ALSO

L<Chart::GGPlot::Position>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
