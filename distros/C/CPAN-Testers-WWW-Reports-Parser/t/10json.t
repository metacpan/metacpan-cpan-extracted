#!/usr/bin/perl -w
use strict;

use CPAN::Testers::WWW::Reports::Parser;
#use Data::Dumper;
use Test::More;

eval "use JSON::XS";
plan skip_all => "JSON::XS required for testing JSON parser" if $@;
plan tests => 57;

my $count           = 537;
my $report_original = {
    'ostext'        => 'Linux',
    'version'       => '0.13',
    'status'        => 'PASS',
    'dist'          => 'App-Maisha',
    'osvers'        => '2.6.26-2-686',
    'csspatch'      => 'unp',
    'state'         => 'pass',
    'distribution'  => 'App-Maisha',
    'perl'          => '5.11.5',
    'distversion'   => 'App-Maisha-0.13',
    'cssperl'       => 'dev',
    'osname'        => 'linux',
    'platform'      => 'i686-linux',
    'id'            => 7046516,
    'guid'          => '07046529-b19f-3f77-b713-d32bba55d77f'
};
my $report_filtered = {
    'version'       => '0.13',
    'grade'         => 'PASS',
    'distname'      => 'App-Maisha',
    'url'           => 'http://www.cpantesters.org/cpan/report/07046529-b19f-3f77-b713-d32bba55d77f'
};
my $report_extended = {
    'ostext'        => 'Linux',
    'version'       => '0.13',
    'status'        => 'PASS',
    'grade'         => 'PASS',
    'dist'          => 'App-Maisha',
    'osvers'        => '2.6.26-2-686',
    'csspatch'      => 'unp',
    'state'         => 'pass',
    'distribution'  => 'App-Maisha',
    'perl'          => '5.11.5',
    'distversion'   => 'App-Maisha-0.13',
    'cssperl'       => 'dev',
    'osname'        => 'linux',
    'platform'      => 'i686-linux',
    'id'            => 7046516,
    'distname'      => 'App-Maisha',
    'dist'          => 'App-Maisha',
    'guid'          => '07046529-b19f-3f77-b713-d32bba55d77f',
    'url'           => 'http://www.cpantesters.org/cpan/report/07046529-b19f-3f77-b713-d32bba55d77f'
};
my @fields = qw(distname version grade url);
my @all_fields = qw(
    id distribution dist distname version distversion perl
    state status grade action osname ostext osvers platform
    archname url csspatch cssperl);

# failure tests
{
    my $obj;
    eval {
        $obj = CPAN::Testers::WWW::Reports::Parser->new();
    };
    like($@,qr/No data format specified/);
    is( $obj, undef );

    eval {
        $obj = CPAN::Testers::WWW::Reports::Parser->new(
            'format' => 'CSV'
        );
    };
    like($@,qr/Unknown data format specified/);
    is( $obj, undef );

    eval {
        $obj = CPAN::Testers::WWW::Reports::Parser->new(
            'format' => 'JSON'
        );
    };
    like($@,qr/Must specify a file or data block to parse/);
    is( $obj, undef );

    eval {
        $obj = CPAN::Testers::WWW::Reports::Parser->new(
            'format' => 'JSON',
            'file'   => 'missing-file.json'
        );
    };
    like($@,qr/Cannot access file/);
    is( $obj, undef );
}

# file tests
{
    my $obj = CPAN::Testers::WWW::Reports::Parser->new(
        'format' => 'JSON',
        'file'   => './t/samples/App-Maisha.json'
    );
    isa_ok( $obj, 'CPAN::Testers::WWW::Reports::Parser' );

    my $data = $obj->reports();

    #diag(Dumper($data->[0]));
    is( scalar(@$data), $count, '.. report count correct' );
    is_deeply( $data->[0], $report_original, '.. matches original report' );

    $data = $obj->reports(@fields);

    #diag(Dumper($data->[0]));
    is( scalar(@$data), $count, '.. report count correct' );
    is_deeply( $data->[0], $report_filtered, '.. matches filtered report' );

    $data = $obj->reports( 'ALL', @fields );

    #diag(Dumper($data->[0]));
    is( scalar(@$data), $count, '.. report count correct' );
    is_deeply( $data->[0], $report_extended, '.. matches extended report' );

    $obj->filter();
    $data = $obj->report();
    is_deeply( $data, $report_original, '.. matches original report' );

    $obj->reload;
    $obj->filter(@fields);
    $data = $obj->report();

    #diag(Dumper($data));
    is_deeply( $data, $report_filtered, '.. matches filtered report' );

    $obj->reload;
    $obj->filter( 'ALL', @fields );
    $data = $obj->report();
    is_deeply( $data, $report_extended, '.. matches extended report' );

    $obj->reload;
    $obj->filter();
    my $reports = 0;
    while ( $data = $obj->report() ) { $reports++ }
    is( $reports, $count, '.. report count correct' );

    {
        $obj->reload;
        $obj->filter(@all_fields);
        $data = $obj->report();

        no strict 'refs';
        for (
            qw( id distribution dist distname version distversion perl
                state status grade action osname ostext osvers platform
                archname url csspatch cssperl )
            )
        {
            is( $obj->$_(), $data->{$_},
                ".. field '$_' matches direct and indirect access" );
        }
    }

    # Test object
    my $obj_tester = CPAN::Testers::WWW::Reports::Parser->new(
        'format'    => 'JSON',
        'file'      => './t/samples/App-Maisha.json',
        'objects'   => 1,
    );
    isa_ok( $obj_tester, 'CPAN::Testers::WWW::Reports::Parser' );

    my $report_obj = $obj_tester->report();
    isa_ok( $report_obj, 'CPAN::Testers::WWW::Reports::Report' );
    is($report_obj->version, '0.13', 'Got a version as expected');
}

# glob tests
{
    open FILE, '<', './t/samples/App-Maisha.json';

    # Test object
    my $obj = CPAN::Testers::WWW::Reports::Parser->new(
        'format'    => 'JSON',
        'file'      => \*FILE
    );
    isa_ok( $obj, 'CPAN::Testers::WWW::Reports::Parser' );

    my $data = $obj->reports();

    is( scalar(@$data), $count, '.. report count correct' );
    is_deeply( $data->[0], $report_original, '.. matches original report' );

    $data = $obj->reports(@fields);

    #diag(Dumper($data->[0]));
    is( scalar(@$data), $count, '.. report count correct' );
    is_deeply( $data->[0], $report_filtered, '.. matches filtered report' );

    $data = $obj->reports( 'ALL', @fields );
    is( scalar(@$data), $count, '.. report count correct' );
    is_deeply( $data->[0], $report_extended, '.. matches extended report' );

    $obj->filter();
    $data = $obj->report();
    is_deeply( $data, $report_original, '.. matches original report' );
}

# data tests
{
    open FILE, '<', './t/samples/App-Maisha.json';
    my $data = do { local $/; <FILE> };

    # Test object
    my $obj = CPAN::Testers::WWW::Reports::Parser->new(
        'format'    => 'JSON',
        'data'      => $data
    );
    isa_ok( $obj, 'CPAN::Testers::WWW::Reports::Parser' );

    $data = $obj->reports();

    is( scalar(@$data), $count, '.. report count correct' );
    is_deeply( $data->[0], $report_original, '.. matches original report' );

    $data = $obj->reports(@fields);

    #diag(Dumper($data->[0]));
    is( scalar(@$data), $count, '.. report count correct' );
    is_deeply( $data->[0], $report_filtered, '.. matches filtered report' );

    $data = $obj->reports( 'ALL', @fields );
    is( scalar(@$data), $count, '.. report count correct' );
    is_deeply( $data->[0], $report_extended, '.. matches extended report' );

    $obj->filter();
    $data = $obj->report();
    is_deeply( $data, $report_original, '.. matches original report' );
}
