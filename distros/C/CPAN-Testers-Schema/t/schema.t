
=head1 DESCRIPTION

This tests the main L<CPAN::Testers::Schema> class which creates schema objects and can
populate data from the CPAN Testers API at L<http://api.cpantesters.org>.

=cut

use CPAN::Testers::Schema::Base 'Test';
use Mojolicious;

my %api_data;
my $mock_ua = Mojo::UserAgent->new;
my $app = Mojolicious->new;
$mock_ua->server->app( $app );
$app->routes->get( '/v3/upload/author/:author', sub( $c ) {
    $c->render( json => $api_data{upload_author} // [] );
} );
$app->routes->get( '/v3/upload/dist/:dist', sub( $c ) {
    $c->render( json => $api_data{upload_dist} // [] );
} );
$app->routes->get( '/v3/release', sub( $c ) {
    $c->render( json => $api_data{release} // [] );
} );
$app->routes->get( '/v3/release/dist/:dist', sub( $c ) {
    $c->render( json => $api_data{release_dist} // [] );
} );
$app->routes->get( '/v3/release/dist/:dist/#version', sub( $c ) {
    $c->render( json => $api_data{release_dist_version} // [] );
} );
$app->routes->get( '/v3/summary', sub( $c ) {
    $c->render( json => $api_data{summary} // [] );
} );
$app->routes->get( '/v3/summary/:dist', sub( $c ) {
    $c->render( json => $api_data{summary_dist} // [] );
} );
$app->routes->get( '/v3/summary/:dist/#version', sub( $c ) {
    $c->render( json => $api_data{summary_dist_version} // [] );
} );
$app->routes->get( '/v3/report/:id', sub( $c ) {
    my $id = $c->stash( 'id' );
    $c->render( json => $api_data{report}{ $id } // {} );
} );

subtest 'uploads for dist' => sub {
    local $api_data{ upload_dist } = [
        {
            dist => 'Yancy',
            author => 'PREACTION',
            version => '1.032',
            filename => 'Yancy-1.032.tar.gz',
            released => '2019-04-25T00:00:00Z',
        },
    ];

    my $schema = prepare_temp_schema();
    $schema->{_ua} = $mock_ua;
    $schema->{_url} = '/v3';
    $schema->populate_from_api( { dist => 'Yancy' }, qw( upload ) );

    my @got_rows = $schema->resultset( 'Upload' )->search->all;
    is scalar @got_rows, 1, 'got one row';
    is $got_rows[0]->dist, 'Yancy', 'dist is correct';
};

subtest 'uploads for author' => sub {
    local $api_data{ upload_author } = [
        {
            dist => 'Yancy',
            author => 'PREACTION',
            version => '1.032',
            filename => 'Yancy-1.032.tar.gz',
            released => '2019-04-25T00:00:00Z',
        },
    ];

    my $schema = prepare_temp_schema();
    $schema->{_ua} = $mock_ua;
    $schema->{_url} = '/v3';
    $schema->populate_from_api( { author => 'PREACTION' }, qw( upload ) );

    my @got_rows = $schema->resultset( 'Upload' )->search->all;
    is scalar @got_rows, 1, 'got one row';
    is $got_rows[0]->author, 'PREACTION', 'author is correct';
};

subtest 'summary for dist' => sub {
    local $api_data{ upload_dist } = [
        {
            dist => 'Yancy',
            author => 'PREACTION',
            version => '1.032',
            filename => 'Yancy-1.032.tar.gz',
            released => '2019-04-25T00:00:00Z',
        },
    ];

    local $api_data{ summary_dist } = [
        {
            date => "2019-04-25",
            dist => "Yancy",
            version => "1.032",
            grade => "pass",
            guid => "12345678-1234-1234-1234-123456789012",
            osname => "linux",
            osvers => "4.8.0-2-amd64",
            perl => "5.28.0",
            platform => "x86_64-linux",
            reporter => 'Doug Bell <doug@preaction.me>',
        },
    ];

    my $schema = prepare_temp_schema();
    $schema->{_ua} = $mock_ua;
    $schema->{_url} = '/v3';
    $schema->populate_from_api( { dist => 'Yancy' }, qw( summary ) );

    my @got_rows = $schema->resultset( 'Upload' )->search->all;
    is scalar @got_rows, 1, 'got one row of uploads';
    is $got_rows[0]->dist, 'Yancy', 'dist is correct';

    @got_rows = $schema->resultset( 'Stats' )->search->all;
    is scalar @got_rows, 1, 'got one row of summaries';
    is $got_rows[0]->dist, 'Yancy', 'dist is correct';
};

subtest 'summary for dist+version' => sub {
    local $api_data{ upload_dist } = [
        {
            dist => 'Yancy',
            author => 'PREACTION',
            version => '1.032',
            filename => 'Yancy-1.032.tar.gz',
            released => '2019-04-25T00:00:00Z',
        },
    ];

    local $api_data{ summary_dist_version } = [
        {
            date => "2019-04-25",
            dist => "Yancy",
            version => "1.032",
            grade => "pass",
            guid => "12345678-1234-1234-1234-123456789012",
            osname => "linux",
            osvers => "4.8.0-2-amd64",
            perl => "5.28.0",
            platform => "x86_64-linux",
            reporter => 'Doug Bell <doug@preaction.me>',
        },
    ];

    my $schema = prepare_temp_schema();
    $schema->{_ua} = $mock_ua;
    $schema->{_url} = '/v3';
    $schema->populate_from_api( { dist => 'Yancy', version => '1.032' }, qw( summary ) );

    my @got_rows = $schema->resultset( 'Upload' )->search->all;
    is scalar @got_rows, 1, 'got one row of uploads';
    is $got_rows[0]->dist, 'Yancy', 'dist is correct';

    @got_rows = $schema->resultset( 'Stats' )->search->all;
    is scalar @got_rows, 1, 'got one row of summaries';
    is $got_rows[0]->dist, 'Yancy', 'dist is correct';
};

subtest 'release for dist' => sub {
    local $api_data{ upload_dist } = [
        {
            dist => 'Yancy',
            author => 'PREACTION',
            version => '1.032',
            filename => 'Yancy-1.032.tar.gz',
            released => '2019-04-25T00:00:00Z',
        },
    ];

    local $api_data{ summary_dist } = [
        {
            date => "2019-04-25",
            dist => "Yancy",
            version => "1.032",
            grade => "pass",
            guid => "12345678-1234-1234-1234-123456789012",
            osname => "linux",
            osvers => "4.8.0-2-amd64",
            perl => "5.28.0",
            platform => "x86_64-linux",
            reporter => 'Doug Bell <doug@preaction.me>',
        },
    ];

    local $api_data{ release_dist } = [
        {
            author => "PREACTION",
            dist => "Yancy",
            fail => 1,
            na => 12,
            pass => 59,
            unknown => 3,
            version => "1.032"
        },
    ];

    my $schema = prepare_temp_schema();
    $schema->{_ua} = $mock_ua;
    $schema->{_url} = '/v3';
    $schema->populate_from_api( { dist => 'Yancy' }, qw( release ) );

    my @got_rows = $schema->resultset( 'Upload' )->search->all;
    is scalar @got_rows, 1, 'got one row of uploads';
    is $got_rows[0]->dist, 'Yancy', 'dist is correct';

    @got_rows = $schema->resultset( 'Stats' )->search->all;
    is scalar @got_rows, 1, 'got one row of summaries';
    is $got_rows[0]->dist, 'Yancy', 'dist is correct';

    @got_rows = $schema->resultset( 'Release' )->search->all;
    is scalar @got_rows, 1, 'got one row of releases';
    is $got_rows[0]->dist, 'Yancy', 'dist is correct';
};

subtest 'release for dist+version' => sub {
    local $api_data{ upload_dist } = [
        {
            dist => 'Yancy',
            author => 'PREACTION',
            version => '1.032',
            filename => 'Yancy-1.032.tar.gz',
            released => '2019-04-25T00:00:00Z',
        },
    ];

    local $api_data{ summary_dist_version } = [
        {
            date => "2019-04-25",
            dist => "Yancy",
            version => "1.032",
            grade => "pass",
            guid => "12345678-1234-1234-1234-123456789012",
            osname => "linux",
            osvers => "4.8.0-2-amd64",
            perl => "5.28.0",
            platform => "x86_64-linux",
            reporter => 'Doug Bell <doug@preaction.me>',
        },
    ];

    local $api_data{ release_dist_version } = [
        {
            author => "PREACTION",
            dist => "Yancy",
            fail => 1,
            na => 12,
            pass => 59,
            unknown => 3,
            version => "1.032"
        },
    ];

    my $schema = prepare_temp_schema();
    $schema->{_ua} = $mock_ua;
    $schema->{_url} = '/v3';
    $schema->populate_from_api( { dist => 'Yancy', version => '1.032' }, qw( release ) );

    my @got_rows = $schema->resultset( 'Upload' )->search->all;
    is scalar @got_rows, 1, 'got one row of uploads';
    is $got_rows[0]->dist, 'Yancy', 'dist is correct';

    @got_rows = $schema->resultset( 'Stats' )->search->all;
    is scalar @got_rows, 1, 'got one row of summaries';
    is $got_rows[0]->dist, 'Yancy', 'dist is correct';

    @got_rows = $schema->resultset( 'Release' )->search->all;
    is scalar @got_rows, 1, 'got one row of releases';
    is $got_rows[0]->dist, 'Yancy', 'dist is correct';
};

done_testing;
