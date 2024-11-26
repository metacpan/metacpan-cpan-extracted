# -*- Perl -*-
#
# Algorithm::Gutter - cellular automata to simulate rain in a gutter

package Algorithm::Gutter;
use 5.26.0;
use Object::Pad 0.66;
our $VERSION = '0.01';

class Algorithm::Gutter::Cell {
    field $amount :mutator :param = 0;
    field $context :mutator;
    field $enabled :mutator :param   = 0;
    field $threshold :mutator :param = ~0;
    field $update :writer :param     = undef;

    method drain ( $index, $all = 1, $stash = undef ) {
        if ( $enabled and $amount >= $threshold ) {
            my $drained;
            if ($all) {
                $drained = $amount;
                $amount  = 0;
            } else {
                $drained = $threshold;
                $amount -= $threshold;
            }
            die "no update callback" unless defined $update;
            return $update->( $self, $index, $drained, $stash );
        }
        return;
    }
}

class Algorithm::Gutter {
    field $gutter :reader :param = [];
    field $rain :writer :param   = undef;

    # Try to drain cells, possibly triggering cell update functions.
    method drain ( $all = 1, $stash = undef ) {
        my $index = 0;
        map { $_->drain( $index++, $all, $stash ) } @$gutter;
    }

    # Adding water to the cells left as an exercise to the caller.
    method rain ( $stash = undef ) {
        die "no rain callback supplied" unless defined $rain;
        $rain->( $gutter, $stash );
    }

    # Redistribute imbalances in the water level between adjacent cells.
    # There are doubtless more complicated or more efficient ways to do
    # this, but those would take time to figure out.
    method slosh ( $max = ~0, $dmax = 1 ) {
        return if @$gutter < 2;
        my $iterations = 0;
        my $end        = @$gutter - 1;
        while ( $max-- > 0 ) {
            $iterations++;
            my $done = 1;
            for my $i ( 0 .. $end - 1 ) {
                my $delta = $gutter->[$i]->amount - $gutter->[ $i + 1 ]->amount;
                if ( $delta > $dmax ) {
                    $gutter->[$i]->amount--;
                    $gutter->[ $i + 1 ]->amount++;
                    $done = 0;
                }
            }
            for my $i ( reverse 1 .. $end ) {
                my $delta = $gutter->[$i]->amount - $gutter->[ $i - 1 ]->amount;
                if ( $delta > $dmax ) {
                    $gutter->[$i]->amount--;
                    $gutter->[ $i - 1 ]->amount++;
                    $done = 0;
                }
            }
            last if $done;
        }
        return $iterations;
    }
}

1;
__END__
=head1 NAME

Algorithm::Gutter - cellular automata to simulate rain in a gutter

=head1 SYNOPSIS

    use Algorithm::Gutter;
    my $g = Algorithm::Gutter->new(
        gutter => [ map Algorithm::Gutter::Cell->new, 1 .. 4 ],
        rain   => sub {
            my ($gutter) = @_;
            $gutter->[ rand @$gutter ]->amount += 1 + int( rand 4 );
        },
    );
    $g->gutter->[1]->enabled = 1;
    $g->gutter->[1]->set_update(
        sub {
            my ( $cell, $index, $amount, $stash ) = @_;
            return [ $index, $amount ];    
        }
    );
    $g->gutter->[1]->threshold = 4;

    for my $turn ( 1 .. 20 ) {
        $g->rain;
        my @out = $g->drain;
        if (@out) {
            warn "$turn drains $out[0][0] amount $out[0][1]\n";
        }
        $g->slosh;
    }

See also the C<eg> directory of this module's distribution for
example scripts.

=head1 DESCRIPTION

This module models a rain gutter, composed of discrete cells, where some
cells have holes in them, of some threshold value, that when the
threshold is reached the fluid will drain from that cell, triggering a
piece of code supplied by the caller. Other methods are provided to
simulate rain (up to the caller) and to redistribute the fluid between
adjacent cells (with a slow and simple algorithm).

Productive uses (dubious--discuss) include procedural generation, in
particular music composition where one may want rhythmic effects similar
to water accumulating and then dripping out of a rain gutter.

The cells are held in an array reference (the B<gutter>); the caller may
need to fiddle around with the cells directly simulate various effects.

=head1 FIELDS

=over 4

=item B<gutter>

An optional array reference of objects that conform to the
L<Algorithm::Gutter::Cell> model. The caller should supply (or populate)
this list, as this module will not do much without a list of cells to
iterate over.

=item B<rain>

An optional code reference that the B<rain> convenience method calls to
simulate rain falling into the cells of the gutter.

=back

=head1 METHODS

=over 4

=item B<drain> [ I<drain-all?> [ I<stash> ] ]

Drains any enabled cells with holes in them, triggering a B<drain>
method call on any relevant cells. The I<drain-all?> boolean controls
whether all of the fluid drains, or only a value equal to the threshold
involved. The user may pass an optional I<stash> that is supplied to
sub-B<drain> calls.

The return value is whatever the sub-B<drain> calls return.

=item B<new> [ I<fields ...> ]

Constructor.

=item B<rain> [ I<stash> ]

A convenience method to call the user-supplied rain callback that
presumably adds some amount of fluid to some number of cells.

=item B<set_rain> [ I<code-reference> ]

Writer method for the B<rain> field.

=item B<slosh> [ I<max-iterations> [ I<delta> ] ]

Redistributes imbalances in fluid levels between adjacent cells.
I<max-iterations> is by default a very large number, though could be set
to a much lower strictly positive integer value to make the fluid act in
a more viscous manner, or less prone to slosh into adjacent cells during
a single call to this method. I<delta> (by default C<1>) controls when a
slosh is triggered, and could be set to higher values to make the fluid
behave more like a solid faulting into adjacent cells?

The return value is the number of loops the B<slosh> method took to
level out the fluid.

=back

=head1 BUGS

These probably should be called errors, not bugs.

=head1 SEE ALSO

L<Object::Pad>

=head1 AUTHOR

Jeremy Mates

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Jeremy Mates

This module is distributed under the (Revised) BSD License.

=cut
