# -*- mode: Perl; -*-

use Test::More tests=>21;
use Test::Deep;

BEGIN { use_ok( 'Bio::IlluminaSAV' ); }

my ($ms_run, $ga_run) = map { Bio::IlluminaSAV->new($_); } qw(sample-miseq-run sample-gaii-run);

ok($ms_run, "sample MS run initialized");
ok($ga_run, "sample GAII run initialized");

## RunInfo stuff

ok(($ms_run->max_cycles()) == 57, "sample MS run max cycles");
ok(($ga_run->max_cycles()) == 226, "sample GAII run max cycles");

ok(($ms_run->num_lanes()) == 1, "sample MS num_lanes");
ok(($ga_run->num_lanes()) == 8, "sample GAII num_lanes");

ok(($ms_run->num_reads()) == 2, "sample MS num_reads");
ok(($ga_run->num_reads()) == 3, "sample GAII num_reads");

## SAV file parsing

my @SAV_TESTS = (
    # filename, record number, truth pattern

    # GA-II
    ['sample-gaii-run/InterOp/ExtractionMetricsOut.bin', 42,
     { 'cif_datestamp' => num(4082880554),
       'cif_timestamp' => num(2295308424),
       'intensities'   => [num(2236), num(1547), num(3201), num(1635)],
       'fwhm'          => [num(74.1, 0.1), num(69.9, 0.1), num(84.4, 0.1), num(80.3, 0.1)],
       'tile'          => num(9),
       'cycle'         => num(6),
       'lane'          => num(1) } ],

    ['sample-gaii-run/InterOp/ControlMetricsOut.bin', 42,
     { 'index_name'       => 'ACTTGA',
       'control_name'     => 'CTA_450bp',
       'tile'             => num(1),
       'control_clusters' => num(0),
       'lane'             => num(1),
       'read'             => num(1) } ],

    ['sample-gaii-run/InterOp/CorrectedIntMetricsOut.bin', 42,
     { 'snr'               => num(9.9, 0.1),
       'avg_called_int'    => [num(1911), num(1914), num(1918), num(1913)],
       'num_basecalls'     => [num(0), num(1.79e-40, 0.01), num(1.31e-40, 0.01), num(1.10e-40, 0.01), num(1.49e-40, 0.01)],
       'avg_corrected_int' => [num(622), num(457), num(377), num(515)],
       'avg_intensity'     => num(493),
       'tile'              => num(3),
       'cycle'             => num(7),
       'lane'              => num(2) } ],

    ['sample-gaii-run/InterOp/ErrorMetricsOut.bin', 42,
     { 'err_rate'  => num(0.15, 0.01),
       'err_reads' => [num(615), num(30), num(0), num(0), num(0)],
       'tile'      => num(2),
       'cycle'     => num(18),
       'lane'      => num(2) } ],

    ['sample-gaii-run/InterOp/QMetricsOut.bin', 42,
     { 'qscores'       => array_each(code(sub { my $x = shift; return ($x >= 0) })),
       'tile'          => num(2),
       'cycle'         => num(15),
       'lane'          => num(2) } ],

    ['sample-gaii-run/InterOp/TileMetricsOut.bin', 42,
     { 'metric_val' => num(826971.81, 0.01),
       'metric'     => num(100),
       'tile'       => num(20),
       'lane'       => num(1) } ],

    # MiSeq
    ['sample-miseq-run/InterOp/ExtractionMetricsOut.bin', 42,
     { 'cif_datestamp' => num(193958702),
       'cif_timestamp' => num(2295319684),
       'intensities'   => [num(263), num(442), num(300), num(283)],
       'fwhm'          => [num(2.3, 0.1), num(2.6, 0.1), num(2.1, 0.1), num(2.4, 0.1)],
       'tile'          => num(1108),
       'cycle'         => num(1),
       'lane'          => num(1) } ],

    ['sample-miseq-run/InterOp/ControlMetricsOut.bin', 42,
     { 'index_name'       => 'ATCACG',
       'control_name'     => 'CTA_850bp',
       'tile'             => num(1101),
       'control_clusters' => num(0),
       'lane'             => num(1),
       'read'             => num(1) } ],

    ['sample-miseq-run/InterOp/CorrectedIntMetricsOut.bin', 42,
     { 'snr'               => num(9.7, 0.1),
       'avg_called_int'    => [num(300), num(296), num(300), num(292)],
       'num_basecalls'     => [num(0), num(1.99e-40, 0.01), num(2.72e-40, 0.01), num(2.83e-40, 0.01), num(2.37e-40, 0.01)],
       'avg_corrected_int' => [num(62), num(86), num(88), num(72)],
       'avg_intensity'     => num(77),
       'tile'              => num(1102),
       'cycle'             => num(17),
       'lane'              => num(1) } ],

    ['sample-miseq-run/InterOp/ErrorMetricsOut.bin', 42,
     { 'err_rate'  => num(0.07, 0.01),
       'err_reads' => [num(60674), num(897), num(0), num(0), num(0)],
       'tile'      => num(1102),
       'cycle'     => num(18),
       'lane'      => num(1) } ],

    ['sample-miseq-run/InterOp/QMetricsOut.bin', 42,
     { 'qscores'       => array_each(code(sub { my $x = shift; return ($x >= 0) })),
       'tile'          => num(1101),
       'cycle'         => num(24),
       'lane'          => num(1) } ],

    ['sample-miseq-run/InterOp/TileMetricsOut.bin', 42,
     { 'metric_val' => num(1199152.75, 0.1),
       'metric'     => num(100),
       'tile'       => num(1107),
       'lane'       => num(1) } ],

    );

foreach my $sav_test (@SAV_TESTS)
{
    my ($file, $rec, $truth) = @$sav_test;

    eval {
        cmp_deeply(Bio::IlluminaSAV::parse_sav_file($file)->[$rec], $truth, $file);
    };
    if ($@) {
        diag("Test error: $@");
    }
}

