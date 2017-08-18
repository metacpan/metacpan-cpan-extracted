package t::DateTime::Astro::Test;
use strict;
use Exporter 'import';
use DateTime;

our @EXPORT_OK = qw(datetime);

sub datetime {
    my ($y, $m, $d, $H, $M, $S) = @_;
    my $dt = DateTime->today(time_zone => 'UTC');
    $dt->set( year => $y ) if defined $y;
    $dt->set( day => $d ) if defined $d;
    $dt->set( month => $m ) if defined $m;
    $dt->set( hour => $H ) if defined $H;
    $dt->set( minute => $M ) if defined $M;
    $dt->set( second => $S ) if defined $S;
    return $dt;
}

1;
