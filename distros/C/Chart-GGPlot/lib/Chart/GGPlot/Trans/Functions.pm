package Chart::GGPlot::Trans::Functions;

# ABSTRACT: Function interface for Chart::GGPlot::Trans

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.0016'; # VERSION

use PDL::Math;
use PDL::Primitive qw(which);
use Role::Tiny ();

use Chart::GGPlot::Trans;
use Chart::GGPlot::Types;
use Chart::GGPlot::Util qw(:all);

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(
  is_trans as_trans trans_range
  asn_trans      atanh_trans
  identity_trans log_trans
  log10_trans    log2_trans
  log1p_trans    reciprocal_trans
  reverse_trans  sqrt_trans
  time_trans
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub is_trans { $_[0]->$_isa('Chart::GGPlot::Trans'); }


my %trans_registry = ();

fun _register_trans($trans) {
    $trans_registry{ $trans->name } = $trans;
}

fun as_trans($x) {
    return $x if ( is_trans($x) );

    my $trans = $trans_registry{$x};
    unless ($trans) {
        die "'$x' is not a transformation";
    }
    return $trans;
}

# Compute range of transformed values.
fun trans_range( $trans, $p ) {
    $trans = as_trans($trans);
    return range(
        $trans->transform->(
            range_( squish( $p, $trans->domain ), true )
        )
    );
}

fun _trans_new( $name, $trans, $inv, %rest ) {
    return Chart::GGPlot::Trans->new(
        name      => $name,
        transform => $trans,
        inverse   => $inv,
        %rest
    );
}

# Identity transformation (do nothing).
fun identity_trans() {
    my $id = fun($p) { $p->copy };
    _trans_new( 'identity', $id, $id);
}

# Arc-sin square root transformation.
fun asn_trans() {
    _trans_new(
        'asn',
        fun($p) { $p->sqrt->asin * 2; },
        fun($p) { ( $p/2 )->sin ** 2; },
    );
}

# Arc-tangent transformation.
fun atanh_trans() {
    my $atanh = fun($p) { $p->atanh };
    _trans_new( 'atanh', $atanh, $atanh );
}

# Box-Cox power transformation.
fun boxcox_trans($x) {
    if ( abs($x) < 1e-07 ) { return ( log_trans() ); }
    _trans_new(
        'pow-' . $x,
        fun($p) { ($p ** $x - 1) / $x * sign( $p -1) },
        fun($p) { ($p->abs * $x + 1 * sign($p)) ** (1/$x) },
    );
}

# Exponential transformation (inverse of log transformation).
fun exp_trans( $base = exp(1) ) {
    _trans_new(
        'power-' . $base,
        fun($p) { pdl($base) ** $p },
        fun($p) { $p->log / log($base) },
    );
}

# Log transformation.
fun log_trans( $base = undef ) {
    my $name = defined $base ? "log$base" : 'log';
    $base //= exp(1);
    _trans_new( $name,
        fun($p) { $p->log / log($base) },
        fun($p) { pdl($base) ** $p },
        breaks => log_breaks($base),
    );
}

sub log10_trans { log_trans(10) }
sub log2_trans  { log_trans(2) }

fun log1p_trans() {
    _trans_new( 'log1p', 
        fun($p) { ($p + 1)->log() },
        fun($p) { $p->exp() - 1 },
    );
}

# Probability transformation.
fun probability_trans( $distribution, @rest ) {

    # TODO: we probably can use Math::CDF or Math::GSL::CDF
    ...
}

# TODO: revisit this once probability_trans is fixed
#sub logit_trans  { probability_trans("logis") }
#sub probit_trans { probability_trans("norm") }

# Reciprocal transformation.
fun reciprocal_trans() {
    my $reci = fun($p) { 1 / $p };
    _trans_new( 'reciprocal', $reci, $reci);
}

# Reverse transformation.
fun reverse_trans() {
    my $rev = fun($p) { -$p };
    _trans_new(
        'reverse', $rev, $rev,
        minor_breaks => regular_minor_breaks(true),
    );
}

# Square-root transformation.
fun sqrt_trans() {
    _trans_new(
        'sqrt',
        fun($p) { $p->sqrt },
        fun($p) { $p ** 2 },
        domain => pdl([ 0, 'inf' ])
    );
}

fun time_trans ($tz=undef) {
    state $fix = sub {
        my ($p, $r) = @_;
        if ( $p->$_DOES('PDL::Role::HasNames') ) {
            Role::Tiny->apply_roles_to_object( $r, 'PDL::Role::HasNames' );
            $r->names( $p->names );
        }
        if ($p->badflag) {
            $r->setbadif($p->isbad);
        }
        return $r;
    };

    # TODO: we don't yet support timezone
    my $from_time = fun($p) {
        my $rslt = pdl( $p->unpdl );
        return $fix->($p, $rslt);
    };
    my $to_time = fun($p) {
        #TODO: See if there is a better way to do it.
        my $rslt =
          PDL::DateTime->new( $p->unpdl->map( sub { $_ eq 'BAD' ? 0 : $_ } ) );
        return $fix->($p, $rslt);
    };
    _trans_new( 'time', $from_time, $to_time, breaks => pretty_breaks() );
}

for my $trans (
    asn_trans(),      atanh_trans(),
    identity_trans(), log_trans(),
    log10_trans(),    log2_trans(),
    log1p_trans(),    reciprocal_trans(),
    reverse_trans(),  sqrt_trans(),
    time_trans(),
  )
{
    _register_trans($trans);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Trans::Functions - Function interface for Chart::GGPlot::Trans

=head1 VERSION

version 0.0016

=head1 FUNCTIONS

=head2 as_trans($x)

=head1 SEE ALSO

L<Chart::GGPlot::Trans>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
