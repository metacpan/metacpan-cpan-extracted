
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::API::Controller::Summary> controller.

=cut

use CPAN::Testers::API::Base 'Test';

my $t = prepare_test_app();

my %stats_default = (
    tester => 'doug@example.com (Doug Bell)',
    platform => 'darwin-2level',
    perl => '5.22.0',
    osname => 'darwin',
    osvers => '10.8.0',
    type => 2,
);

my %data = (

    Upload => [
        {
            uploadid => 1,
            type => 'cpan',
            author => 'PREACTION',
            dist => 'My-Dist',
            version => '1.001',
            filename => 'My-Dist-1.001.tar.gz',
            released => 1479524600,
        },
        {
            uploadid => 2,
            type => 'cpan',
            author => 'POSTACTION',
            dist => 'My-Dist',
            version => '1.002',
            filename => 'My-Dist-1.002.tar.gz',
            released => 1479524700,
        },
        {
            uploadid => 3,
            type => 'cpan',
            author => 'PREACTION',
            dist => 'My-Other',
            version => '1.000',
            filename => 'My-Other-1.000.tar.gz',
            released => 1479524800,
        },
    ],

    Stats => [
        {
            %stats_default,
            # Upload info
            dist => 'My-Dist',
            version => '1.001',
            uploadid => 1,
            # Stats info
            id => 1,
            guid => '00000000-0000-0000-0000-000000000001',
            state => 'pass',
            postdate => '201608',
            fulldate => '201608120401',
        },
        {
            %stats_default,
            # Upload info
            dist => 'My-Dist',
            version => '1.001',
            uploadid => 1,
            # Stats info
            id => 2,
            guid => '00000000-0000-0000-0000-000000000002',
            state => 'fail',
            postdate => '201608',
            fulldate => '201608120000',
            perl => '5.20.0',
        },
        {
            %stats_default,
            # Upload info
            dist => 'My-Dist',
            version => '1.002',
            uploadid => 2,
            # Stats info
            id => 3,
            guid => '00000000-0000-0000-0000-000000000003',
            state => 'fail',
            postdate => '201608',
            fulldate => '201608200000',
            osname => 'linux',
        },
        {
            %stats_default,
            # Upload info
            dist => 'My-Other',
            version => '1.000',
            uploadid => 3,
            # Stats info
            id => 4,
            guid => '00000000-0000-0000-0000-000000000004',
            state => 'pass',
            postdate => '201609',
            fulldate => '201609180000',
        },
    ],

);

subtest 'sanity check that items were inserted' => sub {
    my $schema = $t->app->schema;
    $schema->populate( $_, $data{ $_ } ) for keys %data;
    my $rs = $schema->resultset( 'Stats' );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], $data{Stats}, 'sanity check that items were inserted'
        or diag explain [ $rs->all ];
};

subtest '/v3/summary/{dist}/{version}' => \&_test_api, '/v3';

sub _test_api( $base ) {

    subtest 'by dist' => sub {
        $t->get_ok( $base . '/summary/My-Dist' )
          ->status_is( 200 )
          ->json_is( '/0/guid' => $data{Stats}[0]{guid} )
          ->json_is( '/1/guid' => $data{Stats}[1]{guid} )
          ->json_is( '/2/guid' => $data{Stats}[2]{guid} )
          ->json_is( '/0/date' => '2016-08-12T04:01:00Z' )
          ->json_is( '/1/date' => '2016-08-12T00:00:00Z' )
          ->json_is( '/2/date' => '2016-08-20T00:00:00Z' )
          ->json_hasnt( '/0/fulldate' )
          ->json_hasnt( '/1/fulldate' )
          ->json_hasnt( '/2/fulldate' )
          ->json_is( '/0/grade' => 'pass' )
          ->json_is( '/1/grade' => 'fail' )
          ->json_is( '/2/grade' => 'fail' )
          ->json_hasnt( '/0/state' )
          ->json_hasnt( '/1/state' )
          ->json_hasnt( '/2/state' )
          ->json_is( '/0/reporter' => $data{Stats}[0]{tester} )
          ->json_is( '/1/reporter' => $data{Stats}[1]{tester} )
          ->json_is( '/2/reporter' => $data{Stats}[2]{tester} )
          ;
    };

    subtest 'by dist/version' => sub {
        $t->get_ok( $base . '/summary/My-Dist/1.001' )
          ->status_is( 200 )
          ->json_is( '/0/guid' => $data{Stats}[0]{guid} )
          ->json_is( '/1/guid' => $data{Stats}[1]{guid} )
          ->json_is( '/0/date' => '2016-08-12T04:01:00Z' )
          ->json_is( '/1/date' => '2016-08-12T00:00:00Z' )
          ->json_hasnt( '/0/fulldate' )
          ->json_hasnt( '/1/fulldate' )
          ->json_is( '/0/grade' => 'pass' )
          ->json_is( '/1/grade' => 'fail' )
          ->json_hasnt( '/0/state' )
          ->json_hasnt( '/1/state' )
          ->json_is( '/0/reporter' => $data{Stats}[0]{tester} )
          ->json_is( '/1/reporter' => $data{Stats}[1]{tester} )
          ;
    };

    subtest 'by grade' => sub {
        $t->get_ok( $base . '/summary/My-Dist/1.001?grade=pass' )
          ->status_is( 200 )
          ->json_is( '/0/guid' => $data{Stats}[0]{guid} )
          ->json_hasnt( '/1' )
          ;
    };

    subtest 'by dist/perl' => sub {
        $t->get_ok( $base . '/summary/My-Dist?perl=5.20.0' )
          ->status_is( 200 )
          ->json_is( '/0/guid' => $data{Stats}[1]{guid} )
          ->json_is( '/0/date' => '2016-08-12T00:00:00Z' )
          ->json_is( '/0/grade' => 'fail' )
          ->json_hasnt( '/0/state' )
          ->json_is( '/0/reporter' => $data{Stats}[1]{tester} )
          ->json_hasnt( '/1' )
          ;
    };

    subtest 'by dist/osname' => sub {
        $t->get_ok( $base . '/summary/My-Dist?osname=linux' )
          ->status_is( 200 )
          ->json_is( '/0/guid' => $data{Stats}[2]{guid} )
          ->json_is( '/0/date' => '2016-08-20T00:00:00Z' )
          ->json_is( '/0/grade' => 'fail' )
          ->json_hasnt( '/0/state' )
          ->json_is( '/0/reporter' => $data{Stats}[2]{tester} )
          ->json_hasnt( '/1' )
          ;
    };

    subtest 'by perl' => sub {
        $t->get_ok( $base . '/summary?perl=5.20.0' )
          ->status_is( 200 )
          ->json_is( '/0/guid' => $data{Stats}[1]{guid} )
          ->json_is( '/0/date' => '2016-08-12T00:00:00Z' )
          ->json_is( '/0/grade' => 'fail' )
          ->json_hasnt( '/0/state' )
          ->json_is( '/0/reporter' => $data{Stats}[1]{tester} )
          ->json_hasnt( '/1' )
          ;
    };

    subtest 'by osname' => sub {
        $t->get_ok( $base . '/summary?osname=linux' )
          ->status_is( 200 )
          ->json_is( '/0/guid' => $data{Stats}[2]{guid} )
          ->json_is( '/0/date' => '2016-08-20T00:00:00Z' )
          ->json_is( '/0/grade' => 'fail' )
          ->json_hasnt( '/0/state' )
          ->json_is( '/0/reporter' => $data{Stats}[2]{tester} )
          ->json_hasnt( '/1' )
          ;
    };

    subtest 'since' => sub {
        $t->get_ok( $base . '/summary/My-Dist?since=2016-08-20T00:00:00Z' )
          ->status_is( 200 )
          ->json_is( '/0/guid' => $data{Stats}[2]{guid} )
          ->json_is( '/0/date' => '2016-08-20T00:00:00Z' )
          ->json_hasnt( '/0/fulldate' )
          ->json_is( '/0/grade' => 'fail' )
          ->json_hasnt( '/0/state' )
          ->json_is( '/0/reporter' => $data{Stats}[2]{tester} )
          ;
    };

    subtest 'dist not found' => sub {
        $t->get_ok( $base . '/summary/Not-Found/1.001' )
          ->status_is( 404 )
          ->json_is( {
              errors => [ { message =>  'No results found', 'path' => '/' } ],
          } );
    };

    subtest 'perl/osname not provided' => sub {
        $t->get_ok( $base . '/summary' )
          ->status_is( 400 )
          ->json_is( {
              errors => [ { message =>  q{You must provide one of 'perl' or 'osname'}, 'path' => '/' } ],
          } );
    };

}

done_testing;

