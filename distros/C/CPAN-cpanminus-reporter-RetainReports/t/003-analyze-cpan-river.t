# -*- perl -*-
use strict;
use warnings;
use Test::More;
use Carp;
use lib ('./t/lib');
use Testing ( qw|
    test_one_log_file
    test_no_test_output
    test_multiple_log_files
| );
BEGIN { use_ok( 'CPAN::cpanminus::reporter::RetainReports' ); }

test_multiple_log_files( {
    build_logfile   => 'cpanriver.01.build.log',
    logs            => [
        {
            json_title      => 'ILMARI.DBIx-Class-Schema-Loader-0.07047',
            expected        =>  {
                  author        => 'ILMARI',
                  distname      => 'DBIx-Class-Schema-Loader-0.07047',
                  dist          => 'DBIx-Class-Schema-Loader',
                  distversion   => '0.07047',
                  grade         => 'FAIL',
                  test_output   => qr/Building and testing DBIx-Class-Schema-Loader-0\.07047/s,
            },
        },
        {
            json_title      => 'GUGOD.App-perlbrew-0.80',
            expected        =>  {
                  author        => 'GUGOD',
                  distname      => 'App-perlbrew-0.80',
                  dist          => 'App-perlbrew',
                  distversion   => '0.80',
                  grade         => 'FAIL',
                  test_output   => qr/Building and testing App-perlbrew-0\.80/s,
            },
        },
        {
            json_title      => 'JSWARTZ.Mason-Tidy-2.57',
            expected        =>  {
                  author        => 'JSWARTZ',
                  distname      => 'Mason-Tidy-2.57',
                  dist          => 'Mason-Tidy',
                  distversion   => '2.57',
                  grade         => 'FAIL',
                  test_output   => qr/Building and testing Mason-Tidy-2\.57/s,
            },
        },
        {
            json_title      => 'THOR.Net-LibIDN-0.12',
            expected        =>  {
                  author        => 'THOR',
                  distname      => 'Net-LibIDN-0.12',
                  dist          => 'Net-LibIDN',
                  distversion   => '0.12',
                  grade         => 'NA',
                  test_output   => qr/FAIL Configure failed for Net-LibIDN-0\.12/s,
            },
        },
        {
            json_title      => 'RJBS.Test-Deep-1.127',
            expected        =>  {
                  author        => 'RJBS',
                  distname      => 'Test-Deep-1.127',
                  dist          => 'Test-Deep',
                  distversion   => '1.127',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Test-Deep-1\.127/s,
            },
        },
        {
            json_title      => 'AKZHAN.Test-Spec-0.54',
            expected        =>  {
                  author        => 'AKZHAN',
                  distname      => 'Test-Spec-0.54',
                  dist          => 'Test-Spec',
                  distversion   => '0.54',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Test-Spec-0\.54/s,
            },
        },
        {
            json_title      => 'ISHIGAKI.DBD-SQLite-1.54',
            expected        =>  {
                  author        => 'ISHIGAKI',
                  distname      => 'DBD-SQLite-1.54',
                  dist          => 'DBD-SQLite',
                  distversion   => '1.54',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing DBD-SQLite-1\.54/s,
            },
        },
        {
            json_title      => 'TIMB.DBI-1.637',
            expected        =>  {
                  author        => 'TIMB',
                  distname      => 'DBI-1.637',
                  dist          => 'DBI',
                  distversion   => '1.637',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing DBI-1\.637/s,
            },
        },
    ],
} );

test_multiple_log_files( {
    build_logfile   => 'cpanriver.02.build.log',
    logs            => [
        {
            json_title      => 'CHM.PDL-2.018',
            expected        =>  {
                  author        => 'CHM',
                  distname      => 'PDL-2.018',
                  dist          => 'PDL',
                  distversion   => '2.018',
                  grade         => 'FAIL',
                  test_output   => qr/Building and testing PDL-2\.018/s,
            },
        },
        {
            json_title      => 'INGY.Module-Compile-0.35',
            expected        =>  {
                  author        => 'INGY',
                  distname      => 'Module-Compile-0.35',
                  dist          => 'Module-Compile',
                  distversion   => '0.35',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Module-Compile-0\.35/s,
            },
        },
    ],
} );

done_testing();
