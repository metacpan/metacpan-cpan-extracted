# -*- perl -*-
use strict;
use warnings;
use Test::More;
use Carp;
use Capture::Tiny qw( capture_stdout );
use lib ('./t/lib');
use Testing ( qw|
    test_one_log_file
    test_no_test_output
    test_multiple_log_files
    test_absence_of_stdout
| );
BEGIN { use_ok( 'CPAN::cpanminus::reporter::RetainReports' ); }

test_absence_of_stdout( {
    build_logfile   => 'mixed_scheme.build.log',
    json_title      => 'JKEENAN.Data-Presenter-1.03',
    expected        =>  {
        author        => 'JKEENAN',
        distname      => 'Data-Presenter-1.03',
        dist          => 'Data-Presenter',
        distversion   => '1.03',
        grade         => 'PASS',
        test_output   => qr/Building and testing Data-Presenter-1\.03/s,
        superseded    => qr/invalid scheme 'file' for resource.*Skipping/s,
    },
} );

test_multiple_log_files( {
    build_logfile   => 'mixed_scheme.build.log',
    logs            => [
        {
            #--> Working on /home/username/minicpan/authors/id/J/JK/JKEENAN/Data-Presenter-1.03.tar.gz
            json_title      => 'JKEENAN.Data-Presenter-1.03',
            expected        =>  {
                  author        => 'JKEENAN',
                  distname      => 'Data-Presenter-1.03',
                  dist          => 'Data-Presenter',
                  distversion   => '1.03',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing Data-Presenter-1\.03/s,
            },
            #Fetching http://www.cpan.org/authors/id/J/JK/JKEENAN/IO-Capture-Extended-0.13.tar.gz
            json_title      => 'JKEENAN.IO-Capture-Extended-0.13',
            expected        =>  {
                  author        => 'JKEENAN',
                  distname      => 'IO-Capture-Extended-0.13',
                  dist          => 'IO-Capture-Extended',
                  distversion   => '0.13',
                  grade         => 'PASS',
                  test_output   => qr/Building and testing IO-Capture-Extended-0\.13/s,
            },
        },
    ],
} );


done_testing();
