package Algorithm::RectanglesContainingDot;

use strict;
use warnings;

our $VERSION = '0.02';

package
     Algorithm::RectanglesContainingDot::Perl;

our $MIN_DIV = 8;

sub new {
    my $class = shift;
    my $self = { rects => [],
                 names => [] };
    bless $self, $class;
}

sub _reset { delete shift->{div} }

sub add_rectangle {
    my ($self, $name, $x0, $y0, $x1, $y1) = @_;

    ($x0, $x1) = ($x1, $x0) if $x0 > $x1;
    ($y0, $y1) = ($y1, $y0) if $y0 > $y1;

    push @{$self->{rects}}, ($x0, $y0, $x1, $y1);
    push @{$self->{names}}, $name;
    delete $self->{div};
}

sub rectangles_containing_dot {
    my $self = shift;
    my $div = $self->{div} || $self->_init_div;
    @{$self->{names}}[_rectangles_containing_dot($div, $self->{rects}, @_)];
}

sub _rectangles_containing_dot_ref {
    my ($self, $x, $y) = @_;
    my $names = $self->{names};
    my $rects = $self->{rects};
    my @ret;
    for (0..$#$names) {
        my $i0 = $_ * 4;
        if ($rects->[$i0] <= $x and
            $rects->[$i0+1] <= $y and
            $rects->[$i0+2] >= $x and
            $rects->[$i0+3] >= $y) {
            push @ret, $names->[$_];
        }
    }
    @ret;
}

# div is:
# x/y, right_div, left_div, point, all

sub _init_div {
    my $self = shift;
    $self->{div} = [undef, undef, undef, undef, [0..$#{$self->{names}}]]
}

sub _rectangles_containing_dot {
    my ($div, $rects, $x, $y) = @_;
    # print ".";
    while (1) {
        my $dir = $div->[0] || _divide_rects($div, $rects);

        if ($dir eq 'n') {
            my @ret;
            for (@{$div->[4]}) {
                my ($x0, $y0, $x1, $y1) = @{$rects}[4*$_ .. 4*$_+3];
                push @ret, $_
                    if ($x >= $x0 and $x <= $x1 and $y >= $y0 && $y <= $y1);
            }
            return @ret;
        }

        $div = $div->[(($dir eq 'x') ? ($x <= $div->[3]) : ($y <= $div->[3])) ? 1 : 2];
    }
}

sub _find_best_div {
    my ($dr, $rects, $off) = @_;

    my @v0 = map { @{$rects}[$_*4+$off] } @$dr;
    my @v1 = map { @{$rects}[$_*4+2+$off] } @$dr;
    @v0 = sort { $a <=> $b } @v0;
    @v1 = sort { $a <=> $b } @v1;

    my $med = 0.5 * @$dr;
    my $op = 0;
    my $cl = 0;
    my $best = @$dr * @$dr;
    my $bestv;
    # my ($bestop, $bestcl);
    while (@v0 and @v1) {
        my $v = ($v0[0] <= $v1[0]) ? $v0[0] : $v1[0];
        while (@v0 and $v0[0] == $v) {
            $op++;
            shift @v0;
        }
        while (@v1 and $v1[0] == $v) {
            $cl++;
            shift @v1;
        }

        my $l = $op - $med;
        my $r = @$dr - $cl - $med;
        my $good = $l * $l + $r * $r;

            #{ no warnings; print STDERR "med: $med, op: $op, cl: $cl, good: $good, best: $best, bestv: $bestv\n"; }

        if ($good < $best) {
            $best = $good;
            $bestv = $v;
            # $bestop = $op;
            # $bestcl = $cl;
        }
    }
    # print "off: $off, best: $best, bestv: $bestv, bestop: $bestop, bestcl: $bestcl, size-bestcl: ".(@$dr-$bestcl)."\n";
    return ($best, $bestv);
}

sub _divide_rects {
    my ($div, $rects) = @_;
    my $dr = $div->[4];
    return $div->[0] = 'n' if (@$dr <= $MIN_DIV);
    my $bestreq = 0.24 * @$dr * @$dr;
    my ($bestx, $bestxx) = _find_best_div($dr, $rects, 0);
    my ($besty, $bestyy) = ($bestx == 0) ? 1 : _find_best_div($dr, $rects, 1);
    # print "bestx: $bestx, bestxx: $bestxx, besty: $besty, bestyy: $bestyy, bestreq: $bestreq\n";
    if ($bestx < $besty) {
        if ($bestx < $bestreq) {
            @{$div}[1,2] = _part_rects($dr, $rects, $bestxx, 0);
            $div->[3] = $bestxx;
            pop @$div;
            return $div->[0] = 'x';
        }
    }
    else {
        if ($besty < $bestreq) {
            @{$div}[1,2] = _part_rects($dr, $rects, $bestyy, 1);
            $div->[3] = $bestyy;
            pop @$div;
            return $div->[0] = 'y';
        }
    }
    return $div->[0] = 'n';
}

sub _part_rects {
    my ($dr, $rects, $bestv, $off) = @_;
    my (@l, @r);
    for (@$dr) {
        push @l, $_ if ($bestv >= $rects->[$_ * 4 + $off]);
        push @r, $_ if ($bestv < $rects->[$_ * 4 + $off + 2]);
    }
    # print "off: $off, left: ".scalar(@l).", right: ".scalar(@r)."\n";
    return ([undef, undef, undef, undef, \@l],
            [undef, undef, undef, undef, \@r])
}

package Algorithm::RectanglesContainingDot;

our @ISA;
if (eval "require Algorithm::RectanglesContainingDot_XS") {
    @ISA = qw(Algorithm::RectanglesContainingDot_XS);
}
else {
    @ISA = qw(Algorithm::RectanglesContainingDot::Perl);
}

1;
__END__

=head1 NAME

Algorithm::RectanglesContainingDot - find rectangles containing a given dot

=head1 SYNOPSIS

  use Algorithm::RectanglesContainingDot;

  my $alg = Algorithm::RectanglesContainingDot->new;

  for my $i (0 .. $num_rects) {
    $alg->add_rectangle($rname[$i], $rx0[$i], $ry0[$i], $rx1[$i], $ry1[$i]);
  }

  for my $j (0 .. $num_points) {
    my @rects_containing_dot_names = $alg->rectangles_containing_dot($px[$j], $py[$j]);
    ...
  }


=head1 DESCRIPTION

Given a set of rectangles and a set of dots, the algorithm implemented
in this modules finds for every dot, which rectangles contain it.

The algorithm complexity is O(R * log(R) * log(R) + D * log(R)) being
R the number of rectangles and D the number of dots.

Its usage is very simple:

=over 4

=item 1) create and algorithm object:

    $a = Algorithm::RectanglesContainingDot->new;

=item 2) add the rectangles:

    $a->add_rectangle($name, $x0, $y0, $x1, $y1);

Rectangles are identified by a name that can be any perl scalar
(typically an integer or a string).

($x0, $y0) and ($x1, $y1) correspond to the coordinates of the
left-botton and right-top vertices respectively.

=item 3) call the search method for every dot:

    @rects = $a->rectangles_containing_dot($x, $y)

Returns the names of the rectangles containing the dot ($x, $y).

=back

=head1 SEE ALSO

L<Algorithm::RectanglesContainingDot_XS> implements the same algorithm
as this module in C/XS and so it is much faster. When available, this
module will automatically load and use it.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 by Salvador Fandino.

Copyright (c) 2007 by Qindel Formacion y Servicios SL.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
