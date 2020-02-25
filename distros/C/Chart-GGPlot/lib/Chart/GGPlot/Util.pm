package Chart::GGPlot::Util;

# ABSTRACT: Utility functions

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.0009'; # VERSION

use Data::Dumper::Concise ();

use Data::Frame;

#TODO: Watch https://github.com/kmx/pdl-datetime/issues/1
# PDL::Constants uses PDL::Complex which has conflict with PDL::DateTime
#use PDL::Constants qw(PI);
use Math::Trig ();
use constant PI => Math::Trig::pi;

use List::AllUtils qw(min);
use Module::Load;
use PDL::Primitive qw(which);
use Package::Stash;
use Types::PDL qw(Piddle1D PiddleFromAny);
use Types::Standard qw(ArrayRef);

use Chart::GGPlot::Util::_Base qw(:all);
use Chart::GGPlot::Util::Scales qw(:all);

use parent qw(Exporter::Tiny);

my @export_ggplot = qw(
  expand_range4 remove_missing
  resolution
  stat
);

my @export_all = (
    @export_ggplot,
    qw(
      PI
      pt stroke
      isnt_null_or
      clist
      call_if_coderef
      alias_color_functions
      dist_euclidean dist_polar
      find_line_formula spiral_arc_length
      has_groups
      collect_functions_from_package
      ),
);

our @EXPORT_OK = (
    @Chart::GGPlot::Util::_Base::EXPORT_OK,
    @Chart::GGPlot::Util::Scales::EXPORT_OK, @export_all,
);
our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    base   => \@Chart::GGPlot::Util::_Base::EXPORT_OK,
    scales => \@Chart::GGPlot::Util::Scales::EXPORT_OK,
    ggplot => \@export_ggplot,
);

use constant pt     => 72.27 / 25.4;
use constant stroke => 96 / 25.4;

fun expand_range4 ( $limits, $expand ) {
    return $limits if ($limits->length) == 0;

    die unless ( $expand->length == 2 or $expand->length == 4 );

    if ( $expand->length == 2 ) {
        $expand = pdl([(@{ $expand->unpdl })x2]);
    }

    my $lower =
      expand_range( $limits, $expand->at(0), $expand->at(1) )->at(0);
    my $upper =
      expand_range( $limits, $expand->at(2), $expand->at(3) )->at(1);
    return pdl( [ $lower, $upper ] );
}


fun remove_missing ($df,
                    :$vars = $df->names, :$na_rm = false,
                    :$name = '', :$finite = false) {
    $vars = $vars->intersect( $df->names );

    my $missing = PDL::Core::zeros( $df->nrow );

    for my $var (@$vars) {
        my $col = $df->at($var);
        my $bad = $col->isbad;
        if ($finite and !is_discrete($col)) {
            $bad = ( $bad | !( $col->isfinite ) );
        }
        $missing->where( $bad ) .= 1;
    }

    if ( $missing->any ) {
        if ( !$na_rm ) {
            carp(
                sprintf(
                    "Removed %s rows containing %s values%s.",
                    which($missing)->length,
                    ( $finite       ? 'non-finite' : 'missing' ),
                    ( length($name) ? " ($name)"   : $name )
                )
            );
        }
        return $df->select_rows( which( !$missing ) );
    }
    else {
        return $df;
    }
}


fun call_if_coderef ($x, @args) {
    return ( Ref::Util::is_coderef($x) ? $x->(@args) : $x );
}

fun clist ($hash_like) {
    unless ( Ref::Util::is_plain_hashref($hash_like) ) {
        $hash_like = { map { $_ => $hash_like->at($_) } @{ $hash_like->keys } };
    }
    return Data::Dumper::Concise::Dumper($hash_like);
}


fun alias_color_functions ($package, @function_names) {
    return map {
        if ( $_ =~ /color/ ) {
            my $alias_name = $_ =~ s/color/colour/gr;
            {
                no strict 'refs';
                *{"${package}::${alias_name}"} = \&{"${package}::$_"};
            }
            ( $_, $alias_name );
        }
        else {
            $_;
        }
    } @function_names;
}

fun find_global ($name) {
    my $trace = Devel::StackTrace->new;

    my $frame = $trace->prev_frame;
    while ( $frame = $trace->prev_frame ) {
        my $stash = Package::Stash->new( $frame->package );
        if ( $stash->has_symbol($name) ) {
            return $stash->get_symbol($name);
        }
    }
    return;
}

fun isnt_null_or ( $a, $b ) { !is_null($a) ? $a : $b; }

# Euclidean distance between points.
fun dist_euclidean ($x, $y) {
    my $n   = $x->length;
    my $idx = sequence( $n - 1 );
    return ( ( $x->slice($idx) - $x->slice( $idx + 1 ) )**2 +
          ( $y->slice($idx) - $y->slice( $idx + 1 ) )**2 )->sqrt;
}

# Polar distance between points.
fun dist_polar ($r, $theta) {
    my $lf = find_line_formula( $theta, $r );

    # Rename x and y columns to r and t, since we're working in polar
    $lf = $lf->rename(
        {
            x1          => 't1',
            x2          => 't2',
            y1          => 'r1',
            y2          => 'r2',
            x_intercept => 't_int',
            yintercept  => 'r_int'
        }
    );

    $lf->set( 'tn1', $lf->at('t1') - $lf->at('t_int') );
    $lf->set( 'tn2', $lf->at('t2') - $lf->at('t_int') );

    my $dist  = pdl( [ ('nan') x $lf->nrow ] )->setnantobad;
    my $slope = $lf->at('slope');
    my $idx   = which( !$slope->isbad & ( $slope != 0 ) & $slope->isfinite );
    $dist->slice($idx) .= spiral_arc_length(
        $slope->slice($idx),
        $lf->at('tn1')->slice($idx),
        $lf->at('tn2')->slice($idx)
    );

    # Get circular arc length for segments that have zero slope (r1 == r2)
    $idx = which( !$slope->isbad & ( $slope == 0 ) );
    $dist->slice($idx) .= $lf->at('r1')->slice($idx) *
      ( $lf->at('t2')->slice($idx) - $lf->at('t1')->slice($idx) );

    # Get radial length for segments that have infinite slope (t1 == t2)
    $idx = which( !$slope->isbad & !$slope->isfinite );
    $dist->slice($idx) .=
      $lf->at('r1')->slice($idx) - $lf->at('r2')->slice($idx);

    # Find the maximum possible length, a spiral line from
    # (r=0, theta=0) to (r=1, theta=2*pi)
    my $max_dist = spiral_arc_length( 1 / ( 2 * PI ), 0, 2 * PI );

    # Final distance values, normalized
    return ( $dist / $max_dist );
}

# Given n points, find the slope, xintercept, and yintercept of
#  the lines connecting them.
# Returns a data frame with $x->length-1 rows.

fun find_line_formula ($x, $y) {
    state $check =
      Type::Params::compile( ( Piddle1D->plus_coercions(PiddleFromAny) ) x 2 );
    ( $x, $y ) = $check->( $x, $y );

    my $slope      = $y->diff / $x->diff;
    my $yintercept = $y->slice("1:") - $slope * $x->slice("1:");
    my $xintercept = $x->slice("1:") - $y->slice("1:") / $slope;
    return Data::Frame->new(
        columns => [
            x1 => $x->slice( "0:" . ( $x->length - 2 ) ),
            y1 => $y->slice( "0:" . ( $y->length - 2 ) ),
            x2 => $x->slice("1:"),
            y2 => $y->slice("1:"),
            slope      => $slope,
            yintercept => $yintercept,
            xintercept => $xintercept
        ]
    );
}

fun spiral_arc_length ($a, $theta1, $theta2) {
    state $check =
      Type::Params::compile( ( Piddle1D->plus_coercions(PiddleFromAny) ) x 3 );
    ( $a, $theta1, $theta2 ) = $check->( $a, $theta1, $theta2 );
    return $a * 0.5 *
      ( ( $theta1 * ( $theta1**2 + 1 )->sqrt + $theta1->asinh ) -
          ( $theta2 * ( $theta2**2 + 1 )->sqrt + $theta2->asinh ) );
}


fun resolution(Piddle1D $x, $zero=true) {
    if ($x->type < PDL::float or zero_range(range_($x, true))) {
        return 1;
    }
    if ($zero) {
        $x = $x->glue(0, pdl(0))->uniq;
    } else {
        $x = $x->uniq;
    }
    return $x->qsort->diff->min;
}


fun stat($x) { $x }

use constant NO_GROUP => -1;

fun has_groups ($df) {

    # If no group aesthetic is specified, all values of the group column
    # equal to NO_GROUP. On the other hand, if a group aesthetic is
    # specified, all values are different from NO_GROUP.
    # undef is returned for 0-row data frames.
    return undef if ( $df->nrow == 0 );
    return ( $df->at('group')->at(0) >= 0 );
}

sub collect_functions_from_package {
    my ($package) = @_; 

    load $package;

    my ($caller_package) = caller();
    my @func_names;
    my $funcs = $package->ggplot_functions();
    for (@$funcs) {
        my $name = $_->{name};

        no strict 'refs';
        if (defined &{$name}) {
            warn qq{Duplicate function definitions for "$name". } . 
                "Definition from package $package would mask earlier " .
                "definition loaded into " . __PACKAGE__ . ".";
        }

        *{"${caller_package}::${name}"} = $_->{code};
        push @func_names, $name;
    }   
    return @func_names;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Util - Utility functions

=head1 VERSION

version 0.0009

=head1 FUNCTIONS

=head2 remove_missing

    remove_missing($df,
                   :$na_rm=false, :$vars=$df->names,
                   :$name='', :$finite=false)

Remove all non-complete rows, with a warning if C<$na_rm> is false.
For those stats which require complete data, missing values will be
automatically removed with a warning. If C<$na_rm> is true, the warning
will be suppressed.

=over 4

=item *

$df

Data frame object.

=item *

$na_rm

If true, will suppres warning message.

=item *

$vars

An arrayref of variables to check for missings in.

=item *

$name

Optional function name to improve error message.

=item *

$finite

If true, will also remove non-finite values. 

=back

=head2 call_if_coderef($x, @args)

If C<$x> is a coderef, call it with C<@args>, otherwise returns C<$x>.

=head2 alias_color_functions($package, @function_names)

Given an array of functions, for those with "color" in names, create alias
function with "colour" in name, and return an array of all aliased and
non-aliased.

This can be used in a packge like

    our @EXPORT_OK = alias_color_functions(__PACKAGE__, @function_names);

=head2 resolution

    resolution(Piddle1D $x, $zero=true)

The resolution is the smallest non-zero distance between adjacent values.

If C<$x> has a single value, or an interger vector which can be assumed to
represent a discrete value, then the resolution is 1.
If C<$x> is a float vector, the resolution is the minimal distance between
ajacent values in sorted C<$x>.

If C<$zero> is true, 0 would be inserted into the vector, if it's does not
already in the vector, when computing the resolution.

=head2 stat

Can be used in C<aes()> quosure values as a flag to Chart::GGPlot to
indicate that you want to use calculated aesthetics produced by the
statistic.

Note that this function has same name as Perl's CORE C<stat> function.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
