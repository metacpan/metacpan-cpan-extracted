package Chart::GGPlot::Backend::Plotly::Util;

# ABSTRACT: Utilities used by Chart::GGPlot::Backend::Plotly

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.002000'; # VERSION

use Data::Frame;
use Data::Munge qw(elem);
use List::AllUtils qw(all min max pairmap pairwise reduce);
use PDL::Primitive qw(which);
use Types::PDL qw(Piddle);
use Types::Standard qw(Str);

use parent qw(Exporter::Tiny);

use Chart::GGPlot::Util::Scales qw(
  csshex_to_rgb255 colorname_to_csshex
);
use Chart::GGPlot::Util qw(mm_to_px);

use constant br => '<br />';

our @EXPORT_OK = qw(
  to_px
  br
  to_rgb
  group_to_NA
  pdl_to_plotly
  ribbon
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my $dpi = 96;

sub to_px { mm_to_px($_[0], $dpi) }

sub _rgb {
    my ($c) = @_;
    return 'transparent' if $c eq 'BAD';
    return $c =~ /^#/ ? $c : colorname_to_csshex($c);
}

sub _rgba {
    my ($c, $a) = @_;

    return 'transparent' if $c eq 'BAD';
    $c = $c =~ /^#/ ? $c : colorname_to_csshex($c);
    return $c if $a == 1;

    if ($c =~ /^#/) {
        return sprintf(
            "rgba(%s,%s,%s,%s)",
            csshex_to_rgb255($c),
            0+sprintf("%.2f", $a)   # 0+ for removing trailing zeros
        );
    }
    return $c;
}

# plotly does not understands some non-rgb colors like "grey35"
fun to_rgb ($color, $alpha=pdl(1)) {
    state $check = Type::Params::compile((Piddle | Str), Piddle);
    ($color, $alpha) = $check->($color, $alpha);

    if ( !ref($color) ) {
        return _rgba($color, $alpha->at(0));
    }
    else {
        if ($alpha->length != $color->length and $alpha->length != 1) {
            die "alpha must be of length 1 or the same length as x";
        }
        $alpha = $alpha->setbadtoval(1);
        $alpha->where($alpha > 1) .= 1;
        $alpha->where($alpha < 0) .= 0;
        
        my @color = $color->flatten;
        my @rgba;
        if ($alpha->uniq->length == 1 and $alpha->at(0) == 1) {
            @rgba = map { _rgb($_) } @color;
        } else {
            my @alpha = $alpha->flatten;
            @rgba = pairwise { _rgba($a, $b) } @color, @alpha;
        }

        return PDL::SV->new(\@rgba);
    }
}


fun group_to_NA ($df, :$group_vars=['group'],
                 :$nested=[], :$ordered=[], :$retrace_first=false) {
    return $df if ( $df->nrow == 0 );

    my $df_names = $df->names;
    $group_vars = $group_vars->intersect($df_names);
    $nested     = $nested->intersect($df_names);
    $ordered    = $ordered->intersect($df_names);

    # if group does not exist, just order the rows and exit
    unless ( $group_vars->length ) {
        my @key_vars = ( @$nested, @$ordered );
        return ( @key_vars ? $df->sort( \@key_vars ) : $df );
    }

    if ( $df->nrow == 1 ) {
        return ( $retrace_first ? $df->append( $df->select_rows(0) ) : $df );
    }

    # ordered the rows
    $df = $df->sort( [ @$nested, @$group_vars, @$ordered ] );

    #inserting NAs to ensure each "group"
    my $changes_group = ( $df->select_columns($group_vars)->id->diff != 0 );
    my $to_insert     = $changes_group;
    if ( $nested->length > 0 ) {
        my $changes_nested = ( $df->select_columns($nested)->id->diff == 0 );
        $to_insert = ( $to_insert & $changes_nested );
    }
    my $idx_to_insert = which($to_insert);    # insert after the indices

    # prepare row indices, each item has start row, stop row,
    #  and places to retrace.

    state $split_range = sub {
        my ( $upper, $after ) = @_;
        return (
            pairmap { [ $a .. $b ] }
            (
                0,
                ( map { ( $_, $_ + 1 ) } grep { $_ < $upper } $after->flatten ),
                $upper
            )
        );
    };

    my @group_rows = $split_range->( $df->nrow - 1, $idx_to_insert );
    my @splitted   = map { $df->select_rows($_) } @group_rows;
    if ($retrace_first) {
        my $to_retrace = $changes_group->glue( 0, pdl( [1] ) );
        my @retrace_at = map {
            my $rindices = pdl($_);
            which( $to_retrace->slice($rindices) )->unpdl;
        } @group_rows;

        @splitted = map {
            my $d            = $splitted[$_];
            my @retrace_rows = $split_range->( $d->nrow - 1, $retrace_at[$_] );
            my @splitted_for_retrace = map {
                my $x = $d->select_rows($_);
                $x->append( $x->select_rows( [0] ) )
            } @retrace_rows;
            reduce { $a->append($b); } ( shift @splitted_for_retrace ),
              @splitted_for_retrace;
        } ( 0 .. $#splitted );
    }

    my @key_vars   = ( @$nested, @$group_vars );
    my @vars_to_na = grep { !elem( $_, \@key_vars ) } $df->names->flatten;
    return (
        reduce {

            # copy last row and make it a NA row
            my $na = $a->select_rows( [ $a->nrow - 1 ] )->copy;
            for my $var (@vars_to_na) {
                $na->at($var)->setbadat(0);
            }
            $a->append($na)->append($b);
        }
        ( shift @splitted ),
        @splitted
    );
}

# prepare from piddle to aref or value, to be send to Chart::Plotly
fun pdl_to_plotly ($p, $allow_collapse=false) {
    return [] if $p->length == 0;

    if ( $p->badflag ) {
        return $p->unpdl;
    }

    if ($allow_collapse) {
        return $p->at(0) if $p->length == 1;

        if ( $p->$_DOES('PDL::SV') ) {
            my @lst  = $p->flatten;
            my $elem = shift @lst;
            if ( all { $_ eq $elem } @lst ) {
                return $elem;
            }
        }
        else {
            my $elem = $p->at(0);
            if ( ( $p == $elem )->all ) {
                return $elem;
            }
        }
    }

    return $p->unpdl;
}

# Transform geom_smooth prediction confidence intervals into format plotly
#  likes
fun ribbon ($data) {
    my $n        = $data->nrow;
    my $tmp      = $data->sort( ['x'] );
    my $tmp2     = $data->sort( ['x'], false );
    my $not_used = $data->names->setdiff( [qw(x ymin ymax y)] );

    # top-half of ribbon
    my @others = map { $_ => $tmp->at($_) } @$not_used;
    my $data1  = Data::Frame->new(
        columns => [
            x => $tmp->at('x'),
            y => $tmp->at('ymax'),
            @others,
        ]
    );

    # bottom-half of ribbon
    my @others2 = map { $_ => $tmp2->at($_) } @$not_used;
    my $data2   = Data::Frame->new(
        columns => [
            x => $tmp2->at('x'),
            y => $tmp2->at('ymin'),
            @others2,
        ]
    );

    return $data1->rbind($data2);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Util - Utilities used by Chart::GGPlot::Backend::Plotly

=head1 VERSION

version 0.002000

=head1 FUNCTIONS

=head2 group_to_NA

    group_to_NA($df, :$group_vars=['group'],
                :$nested=[], :$ordered=[], :$retrace_first=false)

If a group of scatter traces share the same non-positional characteristics
(i.e., color, fill, etc), it is more efficient to draw them as a single
trace with missing values that separate the groups (instead of multiple
traces) In this case, one should also take care to make sure
L<connectgaps|https://plot.ly/r/reference/#scatter-connectgaps>
is set to false.

Returns a data frame with rows ordered by C<$nested> then C<$group_vars>
then C<$ordered>. As long as C<$group_vars> contains valid variable names,
new rows will be inserted to separate the groups, at places where group
changes in each chunk of same C<$nested> values.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
