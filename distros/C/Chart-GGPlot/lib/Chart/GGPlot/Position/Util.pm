package Chart::GGPlot::Position::Util;

# ABSTRACT: Utilities internally used by Chart::GGPlot::Position

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.002003'; # VERSION

use Data::Frame;
use List::AllUtils qw(reduce);
use PDL::Core;
use PDL::Primitive qw(which);

use Chart::GGPlot::Util qw(ifelse match pmax pmin);

use parent qw(Exporter::Tiny);

our @EXPORT_OK   = qw(collide collide2 pos_dodge pos_dodge2 pos_stack);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

fun collide_setup ($data, $width, $name, $strategy,
                   $check_width=true, $reverse=false) {
    # determine width
    if ( defined $width ) {
        unless ( List::AllUtils::all { $data->exists($_) } qw(xmin xmax) ) {
            $data->set( 'xmin', $data->at('x') - $width / 2 );
            $data->set( 'xmax', $data->at('x') + $width / 2 );
        }
    }
    else {
        unless ( List::AllUtils::all { $data->exists($_) } qw(xmin xmax) ) {
            $data->set( 'xmin', $data->at('x') );
            $data->set( 'xmax', $data->at('x') );
        }

        my $widths = ( $data->at('xmax') - $data->at('xmin') )->uniq;
        $widths = $widths->where( $widths->isgood ) if $widths->badflag;

        $width = $widths->at(0);
    }

    return { data => $data, width => $width };
}

fun collide ($data, $width, $name, $strategy,
             :$check_width=true, :$reverse=false, %rest) {
    my $dlist =
      collide_setup( $data, $width, $name, $strategy, $check_width, $reverse );
    $data  = $dlist->{data};
    $width = $dlist->{width};

    # Reorder by x position, then on group. The default stacking order
    # reverses the group in order to match the legend order.
    $data = $data->sort( [qw(xmin group)], $reverse ? true : [ true, false ] );

    # TODO: ddply to preserve the order.
    #  So firstly DF::split() shall preserve the order.
    state $ddply = sub {
        my ( $df, $vars, $func ) = @_;

        my $ids         = $df->select_columns($vars)->id;
        my $splitted    = $df->split($ids);
        my @transformed = map { $func->($_) } values %$splitted;
        return ( reduce { $a->append($b) } @transformed );
    };

    my $strategy_wrapped = sub { $strategy->( $_[0], $width, %rest ) };
    if ( $data->exists('ymax') ) {
        $data = $ddply->( $data, ['xmin'], $strategy_wrapped );
    }
    elsif ( $data->exists('y') ) {
        $data->set( 'ymax', $data->at('y') );
        $data = $ddply->( $data, ['xmin'], $strategy_wrapped );
        $data->set( 'y', $data->at('ymax') );
    }
    else {
        die "Neither y nor ymax defined";
    }

    # TODO: This is only to maintain some order to get some tests pass.
    # This should be not needed once we fix ddply.
    return $data->sort( [qw(xmin group)], $reverse ? true : [ true, false ] );
}

# Alternate version of collide() used by position_dodge2()
fun collide2 ($data, $width, $name, $strategy,
              :$check_width=true, :$reverse=false, %rest) {
    my $dlist =
      collide_setup( $data, $width, $name, $strategy, $check_width, $reverse );
    $data  = $dlist->{data};
    $width = $dlist->{width};

    # Reorder by x position, then on group. The default stacking order is
    # different than for collide() because of the order in which pos_dodge2
    # places elements
    $data = $data->sort( [qw(xmin group)], $reverse ? [ true, false ] : true );

   return $strategy->($data, $width, %rest); 
}

fun pos_dodge ($df, $width, :$n=undef) {
    $n //= $df->at('group')->uniq->length;
    if ( $n == 1 ) {
        return $df;
    }

    my $d_width = ( $df->at('xmax') - $df->at('xmin') )->max;

    my $group    = $df->at('group');
    my $groupidx = match( $group, $group->uniq->qsort );
    $df->set( 'x', $df->at('x') + $width * ( ( $groupidx + 0.5 ) / $n - 0.5 ) );

    my $half_width = $d_width / $n / 2;
    $df->set( 'xmin', $df->at('x') - $half_width );
    $df->set( 'xmax', $df->at('x') + $half_width );
    return $df;
}

fun pos_dodge2 ($df, $width, :$n=undef, :$padding=0.1) {
    unless ( List::AllUtils::all { $df->exists($_) } qw(xmin xmax) ) {
        $df->set( 'xmin', $df->at('x') );
        $df->set( 'xmax', $df->at('x') );
    }

    # xid represents groups of boxes that share the same position
    my $xid = find_x_overlaps($df);

    # based on xid find newx, i.e. the center of each group of overlapping
    # elements. for boxes, bars, etc. this should be the same as original
    # x, but for arbitrary rects it may not be
    state $tapply = sub {
        my ( $p, $factor, $func ) = @_;

        my $rslt = PDL::Core::zeros( $p->length );
        for my $factor_enum ( $factor->uniq->flatten ) {
            my $indices = which( $factor == $factor_enum );
            my $group   = $p->slice($indices);
            $rslt->slice($indices) .= $func->($group);
        }
        $rslt->setbadif( $p->isbad ) if $p->badflag;
        return $rslt;
    };

    my $newx = ( $tapply->( $df->at('xmin'), $xid, sub { $_[0]->min } ) +
          $tapply->( $df->at('xmax'), $xid, sub { $_[0]->max } ) ) / 2;

    my $new_width;
    if ( defined $n ) {
        $new_width = ( $df->at('xmax') - $df->at('xmin') ) / $n;
    }
    else {

        # If n is null, preserve total widths of each group
        my @xid = $xid->flatten;
        my %n   = List::AllUtils::count_by { $_ } @xid;
        $new_width = ( $df->at('xmax') - $df->at('xmin') ) /
          pdl( [ map { $n{$_} } @xid ] );
    }

    # Find the total width of each group of elements
    my $group_sizes = Data::Frame->new(
        columns => [
            size => $tapply->( $new_width, $xid, sub { $_[0]->sum } ),
            newx => $newx
        ]
    )->uniq;

    # starting xmin for each group of elements
    my $starts = $group_sizes->at('newx') - $group_sizes->at('size') / 2;

    # set the elements in place
    for my $i ( 0 .. $starts->length - 1 ) {
        my $indices = which( $xid == $i );
        my $divisions =
          $starts->slice( pdl($i) )->glue( 0, $new_width->slice($indices) )
          ->cumusumover();
        $df->slice( $indices, ['xmin'] ) .=
          $divisions->slice( pdl( [ 0 .. $divisions->length - 2 ] ) );
        $df->slice( $indices, ['xmax'] ) .=
          $divisions->slice( pdl( [ 1 .. $divisions->length - 1 ] ) );
    }

    # x values get moved to between xmin and xmax
    $df->set( 'x', ( $df->at('xmin') + $df->at('xmax') ) / 2 );

    # If no elements occupy the same position, there is no need to add padding
    if ( $xid->uniq->length == $xid->length ) {
        return $df;
    }

    # shrink elements to add space between them
    my $half_pad_width = $new_width * ( 1 - $padding ) / 2;
    $df->set( 'xmin', $df->at('x') - $half_pad_width );
    $df->set( 'xmax', $df->at('x') + $half_pad_width );

    return $df;
}

fun pos_stack ($df, $width, :$vjust=1, :$fill=false) {
    my $n       = $df->nrow + 1;
    my $y       = ifelse( $df->at('y')->isbad, 0, $df->at('y') );
    my $heights = pdl( [0] )->glue( 0, $y->cumusumover() );

    if ($fill) {
        $heights = $heights / abs($heights->at(-1));
    }

    my $heights1 = $heights->slice( pdl( [ 0 .. $heights->length - 2 ] ) );
    my $heights2 = $heights->slice( pdl( [ 1 .. $heights->length - 1 ] ) );
    $df->set( 'ymin', pmin( $heights1, $heights2 ) );
    $df->set( 'ymax', pmax( $heights1, $heights2 ) );
    $df->set( 'y',
        ( 1 - $vjust ) * $df->at('ymin') + $vjust * $df->at('ymax') );
    return $df;
}

# find groups of overlapping elements that need to be dodged from one another
fun find_x_overlaps ($df) {
    my @overlaps = (0);
    my $counter = 0;
    my ($xmin, $xmax) = map { $df->at($_) } qw(xmin xmax);
    for my $i (1 .. $df->nrow - 1) {
        if ($xmin->at($i) >= $xmax->at($i-1)) {
            $counter += 1;
        }
        push @overlaps, $counter;
    }
    return pdl(\@overlaps);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Position::Util - Utilities internally used by Chart::GGPlot::Position

=head1 VERSION

version 0.002003

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
