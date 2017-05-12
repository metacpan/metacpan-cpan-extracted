package # hide from CPAN
    Data::Overlay::Test;

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Overlay qw(overlay overlay_all);
use Exporter 'import';
our @EXPORT = qw(olok olallok dt);

# name internal _dt as dt for use in testing (not part of the API)
*dt = \&Data::Overlay::_dt;

sub olok {
    my ($ds, $overlay, $expect) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    cmp_deeply( overlay( $ds,  $overlay) =>  $expect,
                     dt( $ds ).' ~ '.dt($overlay).' ~> '.dt($expect) )
        or diag "ds  = ", explain($ds),
                "ol  = ", explain($overlay),
                "exp = ", explain($expect),
                "got = ", explain(overlay( $ds,  $overlay)),
}

sub olallok {
    my ($ds) = shift;
    my ($expect) = pop;
    my @overlays = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    cmp_deeply( overlay_all( $ds,  @overlays) =>  $expect,
                     join(' ~ ', map { dt($_) } $ds, @overlays)
                        . ' ~> ' . dt($expect) )
        or diag "ds  = ", explain($ds),
                "ols = ", explain(\@overlays),
                "exp = ", explain($expect),
                "got = ", explain(overlay( $ds,  @overlays)),
}

1;
