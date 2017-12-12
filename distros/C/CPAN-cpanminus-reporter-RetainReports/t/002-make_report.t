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

{
    my $reporter = CPAN::cpanminus::reporter::RetainReports->new(verbose => 1);
    ok(defined $reporter, "Inherited constructor returned defined object");
    isa_ok($reporter, 'CPAN::cpanminus::reporter::RetainReports');
    can_ok('CPAN::cpanminus::reporter::RetainReports', qw|
        run
        make_report
    | );
}

test_one_log_file( {
    build_logfile   => 'build.single.log',
    json_title      => 'BINGOS.Module-CoreList-3.07',
    expected        =>  {
        author        => 'BINGOS',
        distname      => 'Module-CoreList-3.07',
        dist          => 'Module-CoreList',
        distversion   => '3.07',
        grade         => 'PASS',
        test_output   => qr/Building and testing Module-CoreList-3\.07/s,
    },
} );

test_one_log_file( {
    build_logfile   => 'build.single_extended.log',
    json_title      => 'JJNAPIORK.Catalyst-Runtime-5.90061',
    expected        =>  {
          author        => 'JJNAPIORK',
          distname      => 'Catalyst-Runtime-5.90061',
          dist          => 'Catalyst-Runtime',
          distversion   => '5.90061',
          grade         => 'PASS',
          test_output   => qr/Building and testing Catalyst-Runtime-5\.90061/s,
    },
} );

test_one_log_file( {
    build_logfile   => 'build.configure_failed.log',
    json_title      => 'BOBW.X86-Udis86-1.7.2.3',
    expected        =>  {
          author        => 'BOBW',
          distname      => 'X86-Udis86-1.7.2.3',
          dist          => 'X86-Udis86',
          distversion   => '1.7.2.3',
          # App::cpanminus::reporter::run sets grade to NA when failure is in
          # configure stage
          grade         => 'NA',
          test_output   => qr/FAIL Configure failed for X86-Udis86-v1\.7\.2\.3/s,
    },
} );

test_one_log_file( {
    build_logfile   => 'build.version_strings.log',
    json_title      => 'BOBW.X86-Udis86-1.7.2.3',
    expected        =>  {
          author        => 'BOBW',
          distname      => 'X86-Udis86-1.7.2.3',
          dist          => 'X86-Udis86',
          distversion   => '1.7.2.3',
          grade         => 'FAIL',
          test_output   => qr/Building and testing X86-Udis86-v1\.7\.2\.3/s,
    },
} );

test_one_log_file( {
    build_logfile   => 'build.module_dir.log',
    # Note the 'v' in 4 values
    json_title      => 'AMBS.Lingua-NATools-v0.7.8',
    expected        =>  {
          author        => 'AMBS',
          distname      => 'Lingua-NATools-v0.7.8',
          dist          => 'Lingua-NATools',
          distversion   => 'v0.7.8',
          grade         => 'PASS',
          test_output   => qr/Building and testing Lingua-NATools-v0\.7\.8/s,
    },
} );

test_no_test_output( {
    build_logfile   => 'build.verbose_cpanm.log',
    json_title      => 'SRI.Mojolicious-4.89',
    expected        =>  {
          author        => 'SRI',
          distname      => 'Mojolicious-4.89',
          dist          => 'Mojolicious',
          distversion   => '4.89',
          grade         => '',
          test_output   => '',
    },
} );

test_one_log_file( {
    build_logfile   => 'build.dist_subdir.log',
    json_title      => 'ILYAZ.Term-ReadLine-Perl-1.0303',
    expected        =>  {
          author        => 'ILYAZ',
          distname      => 'Term-ReadLine-Perl-1.0303',
          dist          => 'Term-ReadLine-Perl',
          distversion   => '1.0303',
          grade         => 'PASS',
          test_output   => qr/Building and testing Term-ReadLine-Perl-1\.0303/s,
    },
} );

test_multiple_log_files( {
    build_logfile   => 'build.cloudweights.log',
    logs            => [
        {
            json_title      => 'RGARCIA.Sub-Identify-0.04',
            expected        =>  {
                  author        => 'RGARCIA',
                  distname      => 'Sub-Identify-0.04',
                  dist          => 'Sub-Identify',
                  distversion   => '0.04',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Sub-Identify-0\.04/s,
            },
        },
        {
            json_title      => 'FRIEDO.namespace-sweep-0.006',
            expected        =>  {
                  author        => 'FRIEDO',
                  distname      => 'namespace-sweep-0.006',
                  dist          => 'namespace-sweep',
                  distversion   => '0.006',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing namespace-sweep-0\.006/s,
            },
        },
        {
            json_title      => 'TOBYINK.Exporter-Tiny-0.036',
            expected        =>  {
                  author        => 'TOBYINK',
                  distname      => 'Exporter-Tiny-0.036',
                  dist          => 'Exporter-Tiny',
                  distversion   => '0.036',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Exporter-Tiny-0\.036/s,
            },
        },
        {
            json_title      => 'PJFL.Data-CloudWeights-0.12.1',
            expected        =>  {
                  author        => 'PJFL',
                  distname      => 'Data-CloudWeights-0.12.1',
                  dist          => 'Data-CloudWeights',
                  distversion   => '0.12.1',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Data-CloudWeights-0\.12\.1/s,
            },
        },
    ],
} );

test_multiple_log_files( {
    build_logfile   => 'build.moose.log',
    logs            => [
        {
            json_title      => 'LEONT.ExtUtils-HasCompiler-0.013',
            expected        =>  {
                  author        => 'LEONT',
                  distname      => 'ExtUtils-HasCompiler-0.013',
                  dist          => 'ExtUtils-HasCompiler',
                  distversion   => '0.013',
                  grade         => 'UNKNOWN',
                  test_output   => qr/Building ExtUtils-HasCompiler-0\.013/s,
            },
        },
        {
            json_title      => 'PEVANS.Scalar-List-Utils-1.45',
            expected        =>  {
                  author        => 'PEVANS',
                  distname      => 'Scalar-List-Utils-1.45',
                  dist          => 'Scalar-List-Utils',
                  distversion   => '1.45',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Scalar-List-Utils-1\.45/s,
            },
        },
        {
            json_title      => 'ETHER.Moose-2.1705',
            expected        =>  {
                  author        => 'ETHER',
                  distname      => 'Moose-2.1705',
                  dist          => 'Moose',
                  distversion   => '2.1705-TRIAL',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Moose-2\.1705/s,
            },
        },
        {
            json_title      => 'RJBS.App-Cmd-0.330',
            expected        =>  {
                  author        => 'RJBS',
                  distname      => 'App-Cmd-0.330',
                  dist          => 'App-Cmd',
                  distversion   => '0.330',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing App-Cmd-0\.330/s,
            },
        },
        {
            json_title      => 'RJBS.Dist-Zilla-5.044',
            expected        =>  {
                  author        => 'RJBS',
                  distname      => 'Dist-Zilla-5.044',
                  dist          => 'Dist-Zilla',
                  distversion   => '5.044',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Dist-Zilla-5\.044/s,
            },
        },
    ],
} );

test_multiple_log_files( {
    build_logfile   => 'build.fresh.log',
    logs            => [
        {
            json_title      => 'GARU.App-cpanminus-reporter-0.13',
            expected        =>  {
                  author        => 'GARU',
                  distname      => 'App-cpanminus-reporter-0.13',
                  dist          => 'App-cpanminus-reporter',
                  distversion   => '0.13',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing App-cpanminus-reporter-0\.13/s,
            },
        },
        {
            json_title      => 'ETHER.URI-1.67',
            expected        =>  {
                  author        => 'ETHER',
                  distname      => 'URI-1.67',
                  dist          => 'URI',
                  distversion   => '1.67',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing URI-1\.67/s,
            },
        },
        {
            json_title      => 'RSAVAGE.Config-Tiny-2.22',
            expected        =>  {
                  author        => 'RSAVAGE',
                  distname      => 'Config-Tiny-2.22',
                  dist          => 'Config-Tiny',
                  distversion   => '2.22',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Config-Tiny-2\.22/s,
            },
        },
        {
            json_title      => 'GARU.CPAN-Testers-Common-Client-0.10',
            expected        =>  {
                  author        => 'GARU',
                  distname      => 'CPAN-Testers-Common-Client-0.10',
                  dist          => 'CPAN-Testers-Common-Client',
                  distversion   => '0.10',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing CPAN-Testers-Common-Client-0\.10/s,
            },
        },
        {
            json_title      => 'BARBIE.Devel-Platform-Info-0.15',
            expected        =>  {
                  author        => 'BARBIE',
                  distname      => 'Devel-Platform-Info-0.15',
                  dist          => 'Devel-Platform-Info',
                  distversion   => '0.15',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Devel-Platform-Info-0\.15/s,
            },
        },
        {
            json_title      => 'DAGOLDEN.Capture-Tiny-0.28',
            expected        =>  {
                  author        => 'DAGOLDEN',
                  distname      => 'Capture-Tiny-0.28',
                  dist          => 'Capture-Tiny',
                  distversion   => '0.28',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Capture-Tiny-0\.28/s,
            },
        },
        {
            json_title      => 'KWILLIAMS.Probe-Perl-0.03',
            expected        =>  {
                  author        => 'KWILLIAMS',
                  distname      => 'Probe-Perl-0.03',
                  dist          => 'Probe-Perl',
                  distversion   => '0.03',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Probe-Perl-0\.03/s,
            },
        },
        {
            json_title      => 'ADAMK.File-HomeDir-1.00',
            expected        =>  {
                  author        => 'ADAMK',
                  distname      => 'File-HomeDir-1.00',
                  dist          => 'File-HomeDir',
                  distversion   => '1.00',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing File-HomeDir-1\.00/s,
            },
        },
        {
            json_title      => 'PLICEASE.File-Which-1.16',
            expected        =>  {
                  author        => 'PLICEASE',
                  distname      => 'File-Which-1.16',
                  dist          => 'File-Which',
                  distversion   => '1.16',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing File-Which-1\.16/s,
            },
        },
        {
            json_title      => 'CHANSEN.Mac-SystemDirectory-0.06',
            expected        =>  {
                  author        => 'CHANSEN',
                  distname      => 'Mac-SystemDirectory-0.06',
                  dist          => 'Mac-SystemDirectory',
                  distversion   => '0.06',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Mac-SystemDirectory-0\.06/s,
            },
        },
        {
            json_title      => 'DAGOLDEN.Metabase-Fact-0.024',
            expected        =>  {
                  author        => 'DAGOLDEN',
                  distname      => 'Metabase-Fact-0.024',
                  dist          => 'Metabase-Fact',
                  distversion   => '0.024',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Metabase-Fact-0\.024/s,
            },
        },
        {
            json_title      => 'MAKAMAKA.JSON-2.90',
            expected        =>  {
                  author        => 'MAKAMAKA',
                  distname      => 'JSON-2.90',
                  dist          => 'JSON',
                  distversion   => '2.90',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing JSON-2\.90/s,
            },
        },
        {
            json_title      => 'RJBS.Test-Fatal-0.014',
            expected        =>  {
                  author        => 'RJBS',
                  distname      => 'Test-Fatal-0.014',
                  dist          => 'Test-Fatal',
                  distversion   => '0.014',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Test-Fatal-0\.014/s,
            },
        },
        {
            json_title      => 'DOY.Try-Tiny-0.22',
            expected        =>  {
                  author        => 'DOY',
                  distname      => 'Try-Tiny-0.22',
                  dist          => 'Try-Tiny',
                  distversion   => '0.22',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Try-Tiny-0\.22/s,
            },
        },
        {
            json_title      => 'RJBS.Data-GUID-0.048',
            expected        =>  {
                  author        => 'RJBS',
                  distname      => 'Data-GUID-0.048',
                  dist          => 'Data-GUID',
                  distversion   => '0.048',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Data-GUID-0\.048/s,
            },
        },
        {
            json_title      => 'RJBS.Sub-Install-0.928',
            expected        =>  {
                  author        => 'RJBS',
                  distname      => 'Sub-Install-0.928',
                  dist          => 'Sub-Install',
                  distversion   => '0.928',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Sub-Install-0\.928/s,
            },
        },
        {
            json_title      => 'RJBS.Data-UUID-1.220',
            expected        =>  {
                  author        => 'RJBS',
                  distname      => 'Data-UUID-1.220',
                  dist          => 'Data-UUID',
                  distversion   => '1.220',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Data-UUID-1\.220/s,
            },
        },
        {
            json_title      => 'RJBS.Sub-Exporter-0.987',
            expected        =>  {
                  author        => 'RJBS',
                  distname      => 'Sub-Exporter-0.987',
                  dist          => 'Sub-Exporter',
                  distversion   => '0.987',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Sub-Exporter-0\.987/s,
            },
        },
        {
            json_title      => 'RJBS.Data-OptList-0.109',
            expected        =>  {
                  author        => 'RJBS',
                  distname      => 'Data-OptList-0.109',
                  dist          => 'Data-OptList',
                  distversion   => '0.109',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Data-OptList-0\.109/s,
            },
        },
        {
            json_title      => 'ADAMK.Params-Util-1.07',
            expected        =>  {
                  author        => 'ADAMK',
                  distname      => 'Params-Util-1.07',
                  dist          => 'Params-Util',
                  distversion   => '1.07',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Params-Util-1\.07/s,
            },
        },
        {
            json_title      => 'GBARR.CPAN-DistnameInfo-0.12',
            expected        =>  {
                  author        => 'GBARR',
                  distname      => 'CPAN-DistnameInfo-0.12',
                  dist          => 'CPAN-DistnameInfo',
                  distversion   => '0.12',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing CPAN-DistnameInfo-0\.12/s,
            },
        },
        {
            json_title      => 'DAGOLDEN.IO-Prompt-Tiny-0.003',
            expected        =>  {
                  author        => 'DAGOLDEN',
                  distname      => 'IO-Prompt-Tiny-0.003',
                  dist          => 'IO-Prompt-Tiny',
                  distversion   => '0.003',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing IO-Prompt-Tiny-0\.003/s,
            },
        },
        {
            json_title      => 'DAGOLDEN.Test-Reporter-1.62',
            expected        =>  {
                  author        => 'DAGOLDEN',
                  distname      => 'Test-Reporter-1.62',
                  dist          => 'Test-Reporter',
                  distversion   => '1.62',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Test-Reporter-1\.62/s,
            },
        },
        {
            json_title      => 'DAGOLDEN.Test-Reporter-Transport-Metabase-1.999009',
            expected        =>  {
                  author        => 'DAGOLDEN',
                  distname      => 'Test-Reporter-Transport-Metabase-1.999009',
                  dist          => 'Test-Reporter-Transport-Metabase',
                  distversion   => '1.999009',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Test-Reporter-Transport-Metabase-1\.999009/s,
            },
        },
        {
            json_title      => 'DAGOLDEN.CPAN-Testers-Report-1.999003',
            expected        =>  {
                  author        => 'DAGOLDEN',
                  distname      => 'CPAN-Testers-Report-1.999003',
                  dist          => 'CPAN-Testers-Report',
                  distversion   => '1.999003',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing CPAN-Testers-Report-1\.999003/s,
            },
        },
        {
            json_title      => 'DAGOLDEN.Metabase-Client-Simple-0.010',
            expected        =>  {
                  author        => 'DAGOLDEN',
                  distname      => 'Metabase-Client-Simple-0.010',
                  dist          => 'Metabase-Client-Simple',
                  distversion   => '0.010',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Metabase-Client-Simple-0\.010/s,
            },
        },
        {
            json_title      => 'GAAS.HTTP-Message-6.06',
            expected        =>  {
                  author        => 'GAAS',
                  distname      => 'HTTP-Message-6.06',
                  dist          => 'HTTP-Message',
                  distversion   => '6.06',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing HTTP-Message-6\.06/s,
            },
        },
        {
            json_title      => 'CJM.IO-HTML-1.001',
            expected        =>  {
                  author        => 'CJM',
                  distname      => 'IO-HTML-1.001',
                  dist          => 'IO-HTML',
                  distversion   => '1.001',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing IO-HTML-1\.001/s,
            },
        },
        {
            json_title      => 'GAAS.LWP-MediaTypes-6.02',
            expected        =>  {
                  author        => 'GAAS',
                  distname      => 'LWP-MediaTypes-6.02',
                  dist          => 'LWP-MediaTypes',
                  distversion   => '6.02',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing LWP-MediaTypes-6\.02/s,
            },
        },
        {
            json_title      => 'GAAS.Encode-Locale-1.04',
            expected        =>  {
                  author        => 'GAAS',
                  distname      => 'Encode-Locale-1.04',
                  dist          => 'Encode-Locale',
                  distversion   => '1.04',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Encode-Locale-1\.04/s,
            },
        },
        {
            json_title      => 'GAAS.HTTP-Date-6.02',
            expected        =>  {
                  author        => 'GAAS',
                  distname      => 'HTTP-Date-6.02',
                  dist          => 'HTTP-Date',
                  distversion   => '6.02',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing HTTP-Date-6\.02/s,
            },
        },
        {
            json_title      => 'ETHER.libwww-perl-6.13',
            expected        =>  {
                  author        => 'ETHER',
                  distname      => 'libwww-perl-6.13',
                  dist          => 'libwww-perl',
                  distversion   => '6.13',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing libwww-perl-6\.13/s,
            },
        },
        {
            json_title      => 'GAAS.WWW-RobotRules-6.02',
            expected        =>  {
                  author        => 'GAAS',
                  distname      => 'WWW-RobotRules-6.02',
                  dist          => 'WWW-RobotRules',
                  distversion   => '6.02',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing WWW-RobotRules-6\.02/s,
            },
        },
        {
            json_title      => 'GAAS.HTML-Parser-3.71',
            expected        =>  {
                  author        => 'GAAS',
                  distname      => 'HTML-Parser-3.71',
                  dist          => 'HTML-Parser',
                  distversion   => '3.71',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing HTML-Parser-3\.71/s,
            },
        },
        {
            json_title      => 'PETDANCE.HTML-Tagset-3.20',
            expected        =>  {
                  author        => 'PETDANCE',
                  distname      => 'HTML-Tagset-3.20',
                  dist          => 'HTML-Tagset',
                  distversion   => '3.20',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing HTML-Tagset-3\.20/s,
            },
        },
        {
            json_title      => 'GAAS.HTTP-Negotiate-6.01',
            expected        =>  {
                  author        => 'GAAS',
                  distname      => 'HTTP-Negotiate-6.01',
                  dist          => 'HTTP-Negotiate',
                  distversion   => '6.01',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing HTTP-Negotiate-6\.01/s,
            },
        },
        {
            json_title      => 'GAAS.File-Listing-6.04',
            expected        =>  {
                  author        => 'GAAS',
                  distname      => 'File-Listing-6.04',
                  dist          => 'File-Listing',
                  distversion   => '6.04',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing File-Listing-6\.04/s,
            },
        },
        {
            json_title      => 'GAAS.HTTP-Daemon-6.01',
            expected        =>  {
                  author        => 'GAAS',
                  distname      => 'HTTP-Daemon-6.01',
                  dist          => 'HTTP-Daemon',
                  distversion   => '6.01',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing HTTP-Daemon-6\.01/s,
            },
        },
        {
            json_title      => 'GAAS.HTTP-Cookies-6.01',
            expected        =>  {
                  author        => 'GAAS',
                  distname      => 'HTTP-Cookies-6.01',
                  dist          => 'HTTP-Cookies',
                  distversion   => '6.01',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing HTTP-Cookies-6\.01/s,
            },
        },
        {
            json_title      => 'MSCHILLI.Net-HTTP-6.07',
            expected        =>  {
                  author        => 'MSCHILLI',
                  distname      => 'Net-HTTP-6.07',
                  dist          => 'Net-HTTP',
                  distversion   => '6.07',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Net-HTTP-6\.07/s,
            },
        },
        {
            json_title      => 'MSCHILLI.LWP-Protocol-https-6.06',
            expected        =>  {
                  author        => 'MSCHILLI',
                  distname      => 'LWP-Protocol-https-6.06',
                  dist          => 'LWP-Protocol-https',
                  distversion   => '6.06',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing LWP-Protocol-https-6\.06/s,
            },
        },
        {
            json_title      => 'SULLR.IO-Socket-SSL-2.012',
            expected        =>  {
                  author        => 'SULLR',
                  distname      => 'IO-Socket-SSL-2.012',
                  dist          => 'IO-Socket-SSL',
                  distversion   => '2.012',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing IO-Socket-SSL-2\.012/s,
            },
        },
        {
            json_title      => 'MIKEM.Net-SSLeay-1.68',
            expected        =>  {
                  author        => 'MIKEM',
                  distname      => 'Net-SSLeay-1.68',
                  dist          => 'Net-SSLeay',
                  distversion   => '1.68',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Net-SSLeay-1\.68/s,
            },
        },
        {
            json_title      => 'ABH.Mozilla-CA-20141217',
            expected        =>  {
                  author        => 'ABH',
                  distname      => 'Mozilla-CA-20141217',
                  dist          => 'Mozilla-CA',
                  distversion   => '20141217',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Mozilla-CA-20141217/s,
            },
        },
    ],
} );

test_one_log_file( {
    build_logfile   => 'build.na.log',
    json_title      => 'ETHER.Dist-Zilla-Plugin-MungeFile-WithDataSection-0.007',
    expected        =>  {
          author        => 'ETHER',
          distname      => 'Dist-Zilla-Plugin-MungeFile-WithDataSection-0.007',
          dist          => 'Dist-Zilla-Plugin-MungeFile-WithDataSection',
          distversion   => '0.007',
          # App::cpanminus::reporter::run sets grade to NA when failure is in
          # configure stage
          grade         => 'NA',
          test_output   => qr/FAIL Configure failed for Dist-Zilla-Plugin-MungeFile-WithDataSection-0\.007/s,
    },
} );

test_multiple_log_files( {
    build_logfile   => 'build.missing.log',
    logs            => [
        {
            json_title      => 'FDALY.Test-Tester-0.109',
            expected        =>  {
                  author        => 'FDALY',
                  distname      => 'Test-Tester-0.109',
                  dist          => 'Test-Tester',
                  distversion   => '0.109',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Test-Tester-0\.109/s,
            },
        },
        {
            json_title      => 'AUDREYT.Test-use-ok-0.11',
            expected        =>  {
                  author        => 'AUDREYT',
                  distname      => 'Test-use-ok-0.11',
                  dist          => 'Test-use-ok',
                  distversion   => '0.11',
                  grade         => 'PASS',
                  # Note difference in version numbers
                  test_output   => qr/Building and testing Test-use-ok-0\.10/s,
            },
        },
    ],
} );

test_multiple_log_files( {
    build_logfile   => 'build.local.log',
    logs            => [
        # Fetching http://www.cpan.org/authors/id/I/IS/ISHIGAKI/Acme-CPANAuthors-0.26.tar.gz
        {
            json_title      => 'ISHIGAKI.Acme-CPANAuthors-0.26',
            expected        =>  {
                  author        => 'ISHIGAKI',
                  distname      => 'Acme-CPANAuthors-0.26',
                  dist          => 'Acme-CPANAuthors',
                  distversion   => '0.26',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Acme-CPANAuthors-0\.26/s,
            },
        },
        #Fetching http://www.cpan.org/authors/id/I/IS/ISHIGAKI/ExtUtils-MakeMaker-CPANfile-0.07.tar.gz
        {
            json_title      => 'ISHIGAKI.ExtUtils-MakeMaker-CPANfile-0.07',
            expected        =>  {
                  author        => 'ISHIGAKI',
                  distname      => 'ExtUtils-MakeMaker-CPANfile-0.07',
                  dist          => 'ExtUtils-MakeMaker-CPANfile',
                  distversion   => '0.07',
                  grade         => 'PASS',
                  # Note difference in version numbers
                  test_output   => qr/Building and testing ExtUtils-MakeMaker-CPANfile-0\.07/s,
            },
        },
    ],
} );


done_testing;

