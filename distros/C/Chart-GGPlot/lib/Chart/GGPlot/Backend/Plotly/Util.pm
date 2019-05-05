package Chart::GGPlot::Backend::Plotly::Util;

# ABSTRACT: Utilities used by Chart::GGPlot::Backend::Plotly

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.0003'; # VERSION

use Data::Munge qw(elem);
use Graphics::Color::RGB;
use List::AllUtils qw(all min max pairmap pairwise reduce);
use Memoize;
use PDL::Primitive qw(which);
use Types::PDL qw(Piddle);
use Types::Standard qw(Str);

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(
  pt_to_px
  cex_to_px
  br
  to_rgb
  group_to_NA
  pdl_to_plotly
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my $dpi = 96;

fun pt_to_px ($x) { $x / 72 * $dpi }

# This is approximately similar to the size in ggplot2.
# Default R fontsize is 12pt. And R scales many symbols by 0.75.
# 0.3 is a magic number from my guess.
fun cex_to_px ($x) { pt_to_px( 12 * $x * 0.75 * 0.3 ) }

sub br { '<br />' }

# plotly does not understands some non-rgb colors like "grey35"
fun to_rgb ($color, $alpha=pdl(1)) {
    state $check = Type::Params::compile((Piddle | Str), Piddle);
    ($color, $alpha) = $check->($color, $alpha);

    my $rgb = sub {
        my ($c, $a) = @_;
        unless ( $c =~ /^\#/ ) {
             $c = _color_name_to_rgb($c);
        }
        return $c if $a == 1;

        if ( my @rgb = ( $c =~ /^#(..)(..)(..)/ ) ) {
            $a = max( min( $a, 1 ), 0 );
            return sprintf(
                "rgba(%s,%s,%s,%s)",
                ( map { hex($_) } @rgb ),
                int( $a * 255 + 0.5 )
            );
        }
        return $c;
    };

    if ( !ref($color) ) {
        return $rgb->($color, 1);
    }
    else {
        if ($alpha->length != $color->length and $alpha->length != 1) {
            die "alpha must be of length 1 or the same length as x";
        }
        $alpha = $alpha->setbadtoval(1);
        
        my @color = $color->flatten;
        my @rgba;
        if ($alpha->uniq->length == 1 and $alpha->at(0) == 1) {
            @rgba = map { $rgb->($_, 1) } @color;
        } else {
            my @alpha = $alpha->flatten;
            @rgba = pairwise { $rgb->($a, $b) } @color, @alpha;
        }

        my $p = PDL::SV->new(\@rgba);
        $p = $p->setbadif( $color->isbad ) if $color->badflag;
        return $p;
    }
}

sub _color_name_to_rgb {
    my ($color) = @_;

    try {
        return Graphics::Color::RGB->from_color_library($color)->as_css_hex;
    }
    catch {
        return $color;
    }
}
memoize('_color_name_to_rgb');


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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Util - Utilities used by Chart::GGPlot::Backend::Plotly

=head1 VERSION

version 0.0003

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

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
