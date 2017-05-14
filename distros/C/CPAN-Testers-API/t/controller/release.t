
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::API::Controller::Release> controller.

=cut

use CPAN::Testers::API::Base 'Test';

my $t = prepare_test_app();

my @API_FIELDS = qw(
    dist version pass fail na unknown
);

my %release_default = (
    oncpan => 1,
    distmat => 1,
    perlmat => 1,
    patched => 1,
);

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

    Release => [
        {
            %release_default,
            # Upload info
            dist => 'My-Dist',
            version => '1.001',
            uploadid => 1,
            # Stats
            id => 2,
            guid => '00000000-0000-0000-0000-000000000002',
            # Release summary
            pass => 1,
            fail => 1,
            na => 0,
            unknown => 0,
        },
        {
            %release_default,
            # Upload info
            dist => 'My-Dist',
            version => '1.002',
            uploadid => 2,
            # Stats
            id => 3,
            guid => '00000000-0000-0000-0000-000000000003',
            # Release summary
            pass => 1,
            fail => 0,
            na => 0,
            unknown => 0,
        },
        {
            %release_default,
            # Upload info
            dist => 'My-Other',
            version => '1.000',
            uploadid => 3,
            # Stats
            id => 4,
            guid => '00000000-0000-0000-0000-000000000004',
            # Release summary
            pass => 1,
            fail => 0,
            na => 0,
            unknown => 0,
        },

        {   # Reports from development perls (odd releases) should not be shown
            %release_default,
            perlmat => 2, # unstable perl
            # Upload info
            dist => 'My-Dist',
            version => '1.000',
            uploadid => 3,
            # Stats
            id => 4,
            guid => '00000000-0000-0000-0000-000000000004',
            # Release summary
            pass => 0,
            fail => 0,
            na => 1,
            unknown => 0,
        },

        {   # Reports from patched perl should not be shown
            %release_default,
            patched => 2, # patched perl
            # Upload info
            dist => 'My-Dist',
            version => '1.000',
            uploadid => 3,
            # Stats
            id => 4,
            guid => '00000000-0000-0000-0000-000000000004',
            # Release summary
            pass => 0,
            fail => 1,
            na => 0,
            unknown => 0,
        },
    ],
);

subtest 'sanity check that items were inserted' => sub {
    my $schema = $t->app->schema;
    $schema->populate( $_, $data{ $_ } ) for keys %data;
    my $rs = $schema->resultset( 'Release' );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], $data{Release}, 'sanity check that items were inserted'
        or diag explain [ $rs->all ];
};

subtest '/v1/release' => \&_test_api, '/v1';
subtest '/v3/release' => \&_test_api, '/v3';

sub _test_api( $base ) {
    subtest 'all releases' => sub {
        $t->get_ok( $base . '/release' )
          ->status_is( 200 )
          ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0..2] ] );

        subtest 'since (disabled until optimized)' => sub {
            $t->get_ok( $base . '/release?since=2016-08-20T00:00:00Z' )
              ->status_is( 400 )
              ->json_has( '/errors' )
              ->or( sub { diag explain shift->tx->res->json } );
        };
    };

    subtest 'by dist' => sub {
        $t->get_ok( $base . '/release/dist/My-Dist' )
          ->status_is( 200 )
          ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0,1] ] );

        subtest 'since' => sub {
            $t->get_ok( $base . '/release/dist/My-Dist?since=2016-08-20T00:00:00Z' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}[1] ] );
        };

        subtest 'dist not found' => sub {
            $t->get_ok( $base . '/release/dist/NOT_FOUND' )
              ->status_is( 404 )
              ->json_is( {
                  errors => [ { message =>  'Distribution "NOT_FOUND" not found', 'path' => '/' } ],
              } );
        };
    };

    subtest 'by author' => sub {
        $t->get_ok( $base . '/release/author/PREACTION' )
          ->status_is( 200 )
          ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0,2] ] );

        subtest 'since' => sub {
            $t->get_ok( $base . '/release/author/PREACTION?since=2016-08-20T00:00:00Z' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}[2] ] );
        };

        subtest 'author not found' => sub {
            $t->get_ok( $base . '/release/author/NOT_FOUND' )
              ->status_is( 404 )
              ->json_is( {
                  errors => [ { message =>  'Author "NOT_FOUND" not found', path => '/' } ],
              } );
        };
    };

    subtest 'input validation' => sub {

        subtest '"since" must be an ISO8601 date/time' => sub {
            $t->get_ok( $base . '/release/dist/My-Dist?since=Sat Nov 19 14:18:40 2016' )
              ->status_is( 400 )
              ->json_has( '/errors' )
              ->or( sub { diag explain shift->tx->res->json } );
        };
    };
}

done_testing;

