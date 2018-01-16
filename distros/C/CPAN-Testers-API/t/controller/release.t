
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::API::Controller::Release> controller.

=cut

use CPAN::Testers::API::Base 'Test';

my $t = prepare_test_app();

my @API_FIELDS = qw(
    dist version pass fail na unknown
);

my %data = %{ load_data() };

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
          ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0..8] ] );

        subtest 'since (disabled until optimized)' => sub {
            $t->get_ok( $base . '/release?since=2016-08-20T00:00:00' )
              ->status_is( 400 )
              ->json_has( '/errors' )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'limit' => sub {
            $t->get_ok( $base . '/release?limit=3' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0..2] ] )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'maturity' => sub {
            subtest 'stable' => sub {
                $t->get_ok( $base . '/release?maturity=stable' )
                  ->status_is( 200 )
                  ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0,2,4,6,8] ] )
                  ->or( sub { diag explain shift->tx->res->json } );
            };

            subtest 'dev' => sub {
                $t->get_ok( $base . '/release?maturity=dev' )
                  ->status_is( 200 )
                  ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[1,3,5,7] ] )
                  ->or( sub { diag explain shift->tx->res->json } );
            };
        };
    };

    subtest 'by dist' => sub {
        $t->get_ok( $base . '/release/dist/My-Dist' )
          ->status_is( 200 )
          ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0..4] ] );

        subtest 'since' => sub {
            $t->get_ok( $base . '/release/dist/My-Dist?since=2016-08-20T00:00:00' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[1..4] ] )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'limit' => sub {
            $t->get_ok( $base . '/release/dist/My-Dist?limit=2' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0,1] ] )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'maturity' => sub {
            subtest 'stable' => sub {
                $t->get_ok( $base . '/release/dist/My-Dist?maturity=stable' )
                  ->status_is( 200 )
                  ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0,2,4] ] )
                  ->or( sub { diag explain shift->tx->res->json } );
            };
            subtest 'dev' => sub {
                $t->get_ok( $base . '/release/dist/My-Dist?maturity=dev' )
                  ->status_is( 200 )
                  ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[1,3] ] )
                  ->or( sub { diag explain shift->tx->res->json } );
            };
        };

        subtest 'since and limit' => sub {
            $t->get_ok( $base . '/release/dist/My-Dist?since=2016-08-20T00:00:00&limit=2' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[1,2] ] )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'since and maturity' => sub {
            $t->get_ok( $base . '/release/dist/My-Dist?since=2016-08-20T00:00:00&maturity=stable' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[2,4] ] )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'limit and maturity' => sub {
            $t->get_ok( $base . '/release/dist/My-Dist?maturity=stable&limit=2' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0,2] ] )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'limit and since and maturity' => sub {
            $t->get_ok( $base . '/release/dist/My-Dist?since=2016-08-20T00:00:00&maturity=stable&limit=1' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}[2] ] )
              ->or( sub { diag explain shift->tx->res->json } );
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
          ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0,2,5..8] ] );

        subtest 'since' => sub {
            $t->get_ok( $base . '/release/author/PREACTION?since=2016-08-20T00:00:00' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[2,5..8] ] )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'limit' => sub {
            $t->get_ok( $base . '/release/author/PREACTION?limit=3' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0,2,5] ] )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'maturity' => sub {
            subtest 'stable' => sub {
                $t->get_ok( $base . '/release/author/PREACTION?maturity=stable' )
                  ->status_is( 200 )
                  ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0,2,6,8] ] )
                  ->or( sub { diag explain shift->tx->res->json } );
            };
            subtest 'dev' => sub {
                $t->get_ok( $base . '/release/author/PREACTION?maturity=dev' )
                  ->status_is( 200 )
                  ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[5,7] ] )
                  ->or( sub { diag explain shift->tx->res->json } );
            };
        };

        subtest 'since and limit' => sub {
            $t->get_ok( $base . '/release/author/PREACTION?since=2016-08-20T00:00:00&limit=2' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[2,5] ] )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'since and maturity' => sub {
            $t->get_ok( $base . '/release/author/PREACTION?since=2016-08-20T00:00:00&maturity=stable' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[2,6,8] ] )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'limit and maturity' => sub {
            $t->get_ok( $base . '/release/author/PREACTION?maturity=stable&limit=2' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}->@[0,2] ] )
              ->or( sub { diag explain shift->tx->res->json } );
        };

        subtest 'limit and since and maturity' => sub {
            $t->get_ok( $base . '/release/author/POSTACTION?since=2016-08-20T00:10:00&maturity=dev&limit=1' )
              ->status_is( 200 )
              ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Release}[3] ] )
              ->or( sub { diag explain shift->tx->res->json } );
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

        subtest '"limit" must be an integer' => sub {
            for ( 'two', 3.14, -42 ) {
                $t->get_ok( $base . "/release/dist/My-Dist?limit=$_" )
                  ->status_is( 400 )
                  ->json_has( '/errors' )
                  ->or( sub { diag explain shift->tx->res->json } );
            }
        };

        subtest '"maturity" must be one of "stable", "dev"' => sub {
            for ( 'foo', 'unstable', 'devo' ) {
                $t->get_ok( $base . "/release/dist/My-Dist?maturity=$_" )
                  ->status_is( 400 )
                  ->json_has( '/errors' )
                  ->or( sub { diag explain shift->tx->res->json } );
            }
        };
    };
}

done_testing;

sub load_data {
    my %release_default = (
        oncpan  => 1,
        perlmat => 1,
        patched => 1,
    );

    my %stats_default = (
        tester   => 'doug@example.com (Doug Bell)',
        platform => 'darwin-2level',
        perl     => '5.22.0',
        osname   => 'darwin',
        osvers   => '10.8.0',
        type     => 2,
    );

    my %data = (
        Upload => [
            {
                uploadid => 1,
                type     => 'cpan',
                author   => 'PREACTION',
                dist     => 'My-Dist',
                version  => '1.000',
                filename => 'My-Dist-1.000.tar.gz',
                released => 1479524590,
            },
            {
                uploadid => 2,
                type     => 'cpan',
                author   => 'PREACTION',
                dist     => 'My-Dist',
                version  => '1.001',
                filename => 'My-Dist-1.001.tar.gz',
                released => 1479524600,
            },
            {
                uploadid => 3,
                type     => 'cpan',
                author   => 'POSTACTION',
                dist     => 'My-Dist',
                version  => '1.002',
                filename => 'My-Dist-1.002.tar.gz',
                released => 1479524700,
            },
            {
                uploadid => 4,
                type     => 'cpan',
                author   => 'PREACTION',
                dist     => 'My-Other',
                version  => '1.001',
                filename => 'My-Other-1.001.tar.gz',
                released => 1479524800,
            },
            {
                uploadid => 5,
                type     => 'cpan',
                author   => 'PREACTION',
                dist     => 'My-Dist',
                version  => '1.003',
                filename => 'My-Dist-1.003.tar.gz',
                released => 1479524900,
            },
            {
                uploadid => 6,
                type     => 'cpan',
                author   => 'PREACTION',
                dist     => 'My-Other',
                version  => '1.002',
                filename => 'My-Other-1.002.tar.gz',
                released => 1479525100,
            },
            {
                uploadid => 7,
                type     => 'cpan',
                author   => 'PREACTION',
                dist     => 'My-Other',
                version  => '1.003',
                filename => 'My-Other-1.003.tar.gz',
                released => 1479525200,
            },
            {
                uploadid => 8,
                type     => 'cpan',
                author   => 'POSTACTION',
                dist     => 'My-Dist',
                version  => '1.004',
                filename => 'My-Dist-1.004.tar.gz',
                released => 1479525300,
            },
            {
                uploadid => 9,
                type     => 'cpan',
                author   => 'PREACTION',
                dist     => 'My-Other',
                version  => '1.004',
                filename => 'My-Dist-1.004.tar.gz',
                released => 1479525400,
            },{
                uploadid => 10,
                type     => 'cpan',
                author   => 'POSTACTION',
                dist     => 'My-Dist',
                version  => '1.005',
                filename => 'My-Dist-1.005.tar.gz',
                released => 1479525500,
            },
        ],

        Stats => [
            {
                %stats_default,
                # Upload info
                dist     => 'My-Dist',
                version  => '1.001',
                uploadid => 2,
                # Stats info
                id       => 1,
                guid     => '00000000-0000-0000-0000-000000000001',
                state    => 'pass',
                postdate => '201608',
                fulldate => '201608120401',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Dist',
                version  => '1.001',
                uploadid => 2,
                # Stats info
                id       => 2,
                guid     => '00000000-0000-0000-0000-000000000002',
                state    => 'fail',
                postdate => '201608',
                fulldate => '201608120000',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Dist',
                version  => '1.002',
                uploadid => 3,
                # Stats info
                id       => 3,
                guid     => '00000000-0000-0000-0000-000000000003',
                state    => 'fail',
                postdate => '201608',
                fulldate => '201608200000',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Dist',
                version  => '1.003',
                uploadid => 5,
                # Stats info
                id       => 4,
                guid     => '00000000-0000-0000-0000-000000000004',
                state    => 'pass',
                postdate => '201608',
                fulldate => '201608200030',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Dist',
                version  => '1.003',
                uploadid => 5,
                # Stats info
                id       => 5,
                guid     => '00000000-0000-0000-0000-000000000005',
                state    => 'pass',
                postdate => '201608',
                fulldate => '201608200100',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Dist',
                version  => '1.004',
                uploadid => 8,
                # Stats info
                id       => 6,
                guid     => '00000000-0000-0000-0000-000000000006',
                state    => 'pass',
                postdate => '201608',
                fulldate => '201608200115',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Dist',
                version  => '1.004',
                uploadid => 8,
                # Stats info
                id       => 7,
                guid     => '00000000-0000-0000-0000-000000000007',
                state    => 'pass',
                postdate => '201608',
                fulldate => '201608200130',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Other',
                version  => '1.001',
                uploadid => 4,
                # Stats info
                id       => 8,
                guid     => '00000000-0000-0000-0000-000000000008',
                state    => 'fail',
                postdate => '201608',
                fulldate => '201608200130',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Other',
                version  => '1.002',
                uploadid => 6,
                # Stats info
                id       => 9,
                guid     => '00000000-0000-0000-0000-000000000009',
                state    => 'fail',
                postdate => '201609',
                fulldate => '201609180200',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Other',
                version  => '1.003',
                uploadid => 7,
                # Stats info
                id       => 10,
                guid     => '00000000-0000-0000-0000-000000000010',
                state    => 'fail',
                postdate => '201609',
                fulldate => '201609180230',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Other',
                version  => '1.003',
                uploadid => 7,
                # Stats info
                id       => 11,
                guid     => '00000000-0000-0000-0000-000000000011',
                state    => 'pass',
                postdate => '201609',
                fulldate => '201609180300',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Dist',
                version  => '1.005',
                uploadid => 10,
                # Stats info
                id       => 12,
                guid     => '00000000-0000-0000-0000-000000000012',
                state    => 'pass',
                postdate => '201609',
                fulldate => '201609180400',
            },
            {
                %stats_default,
                # Upload info
                dist     => 'My-Other',
                version  => '1.004',
                uploadid => 9,
                # Stats info
                id       => 13,
                guid     => '00000000-0000-0000-0000-000000000013',
                state    => 'pass',
                postdate => '201609',
                fulldate => '201609180500',
            },
        ],

        Release => [
            {
                %release_default,
                distmat  => 1, # stable
                # Upload info
                dist     => 'My-Dist',
                version  => '1.001',
                uploadid => 2, # author: PRE
                # Stats
                id       => 2,
                guid     => '00000000-0000-0000-0000-000000000002',
                # Release summary
                pass     => 1,
                fail     => 1,
                na       => 0,
                unknown  => 0,
            },
            {
                %release_default,
                distmat  => 2, # dev
                # Upload info
                dist     => 'My-Dist',
                version  => '1.002',
                uploadid => 3, # author: POST
                # Stats
                id       => 3,
                guid     => '00000000-0000-0000-0000-000000000003',
                # Release summary
                pass     => 0,
                fail     => 1,
                na       => 0,
                unknown  => 0,
            },
            {
                %release_default,
                distmat  => 1,
                # Upload info
                dist     => 'My-Dist',
                version  => '1.003',
                uploadid => 5, # author: PRE
                # Stats
                id       => 5,
                guid     => '00000000-0000-0000-0000-000000000005',
                # Release summary
                pass     => 1,
                fail     => 1,
                na       => 0,
                unknown  => 0,
            },
            {
                %release_default,
                distmat  => 2,
                # Upload info
                dist     => 'My-Dist',
                version  => '1.004',
                uploadid => 8, # author: POST
                # Stats
                id       => 7,
                guid     => '00000000-0000-0000-0000-000000000007',
                # Release summary
                pass     => 2,
                fail     => 0,
                na       => 0,
                unknown  => 0,
            },
            {
                %release_default,
                distmat  => 1,
                # Upload info
                dist     => 'My-Dist',
                version  => '1.005',
                uploadid => 10, # author: POST
                # Stats
                id       => 12,
                guid     => '00000000-0000-0000-0000-000000000012',
                # Release summary
                pass     => 1,
                fail     => 0,
                na       => 0,
                unknown  => 0,
            },
            {
                %release_default,
                distmat  => 2,
                # Upload info
                dist     => 'My-Other',
                version  => '1.001',
                uploadid => 4, # author: PRE
                # Stats
                id       => 8,
                guid     => '00000000-0000-0000-0000-000000000008',
                # Release summary
                pass     => 0,
                fail     => 1,
                na       => 0,
                unknown  => 0,
            },
            {
                %release_default,
                distmat  => 1,
                # Upload info
                dist     => 'My-Other',
                version  => '1.002',
                uploadid => 6, # author: PRE
                # Stats
                id       => 9,
                guid     => '00000000-0000-0000-0000-000000000009',
                # Release summary
                pass     => 0,
                fail     => 1,
                na       => 0,
                unknown  => 0,
            },
            {
                %release_default,
                distmat  => 2,
                # Upload info
                dist     => 'My-Other',
                version  => '1.003',
                uploadid => 7, # author: PRE
                # Stats
                id       => 11,
                guid     => '00000000-0000-0000-0000-000000000011',
                # Release summary
                pass     => 1,
                fail     => 1,
                na       => 0,
                unknown  => 0,
            },
            {
                %release_default,
                distmat  => 1,
                # Upload info
                dist     => 'My-Other',
                version  => '1.004',
                uploadid => 9, # author: PRE
                # Stats
                id       => 13,
                guid     => '00000000-0000-0000-0000-000000000013',
                # Release summary
                pass     => 1,
                fail     => 0,
                na       => 0,
                unknown  => 0,
            },


            {   # Reports from development perls (odd releases) should not be shown
                %release_default,
                distmat  => 2,
                perlmat  => 2, # unstable perl
                # Upload info
                dist     => 'My-Dist',
                version  => '1.000',
                uploadid => 1,
                # Stats
                id       => 42,
                guid     => '00000000-0000-0000-0000-000000000042',
                # Release summary
                pass     => 0,
                fail     => 0,
                na       => 1,
                unknown  => 0,
            },

            {   # Reports from patched perl should not be shown
                %release_default,
                distmat  => 1,
                patched  => 2, # patched perl
                # Upload info
                dist     => 'My-Dist',
                version  => '1.000',
                uploadid => 1,
                # Stats
                id       => 42,
                guid     => '00000000-0000-0000-0000-000000000002',
                # Release summary
                pass     => 0,
                fail     => 1,
                na       => 0,
                unknown  => 0,
            },
        ],
    );

    return \%data;
}

__END__
