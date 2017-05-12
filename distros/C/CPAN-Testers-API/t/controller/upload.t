
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::API::Controller::Upload> controller.

=cut

use CPAN::Testers::API::Base 'Test';

my $t = prepare_test_app();

my @API_FIELDS = qw(
    dist version author filename released
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

);

subtest 'sanity check that items were inserted' => sub {
    my $schema = $t->app->schema;
    $schema->populate( $_, $data{ $_ } ) for keys %data;
    my $rs = $schema->resultset( 'Upload' );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], $data{Upload}, 'sanity check that items were inserted'
        or diag explain [ $rs->all ];
};

for \my %upload ( $data{ Upload }->@* ) {
    my $dt = DateTime->from_epoch( epoch => $upload{ released } );
    $upload{ released } = $dt->datetime . 'Z';
}

subtest 'all uploads' => sub {
    $t->get_ok( '/v1/upload' )
      ->status_is( 200 )
      ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Upload}->@[0..2] ] )
      ->or( sub { diag explain $_[0]->tx->res->json } );

    subtest 'since' => sub {
        $t->get_ok( '/v1/upload?since=2016-11-19T03:05:00Z' )
          ->status_is( 200 )
          ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Upload}->@[1..2] ] )
          ->or( sub { diag explain $_[0]->tx->res->json } );
    };
};

subtest 'by dist' => sub {
    $t->get_ok( '/v1/upload/dist/My-Dist' )
      ->status_is( 200 )
      ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Upload}->@[0,1] ] );

    subtest 'since' => sub {
        $t->get_ok( '/v1/upload/dist/My-Dist?since=2016-11-19T03:05:00Z' )
          ->status_is( 200 )
          ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Upload}[1] ] );
    };

    subtest 'dist not found' => sub {
        $t->get_ok( '/v1/upload/dist/NOT_FOUND' )
          ->status_is( 404 )
          ->json_is( {
              errors => [ { message =>  'Distribution "NOT_FOUND" not found', 'path' => '/' } ],
          } );
    };
};

subtest 'by author' => sub {
    $t->get_ok( '/v1/upload/author/PREACTION' )
      ->status_is( 200 )
      ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Upload}->@[0,2] ] );

    subtest 'since' => sub {
        $t->get_ok( '/v1/upload/author/PREACTION?since=2016-11-19T03:05:00Z' )
          ->status_is( 200 )
          ->json_is( [ map { +{ $_->%{ @API_FIELDS } } } $data{Upload}[2] ] );
    };

    subtest 'author not found' => sub {
        $t->get_ok( '/v1/upload/author/NOT_FOUND' )
          ->status_is( 404 )
          ->json_is( {
              errors => [ { message =>  'Author "NOT_FOUND" not found', path => '/' } ],
          } );
    };
};

subtest 'input validation' => sub {

    subtest '"since" must be an ISO8601 date/time' => sub {
        $t->get_ok( '/v1/upload/dist/My-Dist?since=Sat Nov 19 14:18:40 2016' )
          ->status_is( 400 )
          ->json_has( '/errors' )
          ->or( sub { diag explain shift->tx->res->json } );
    };
};

subtest 'websocket feeds' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub( @warns ) { push @warnings, @warns };

    my $broker = Mojolicious->new;
    $broker->routes->websocket( '/sub/*topic' )->to( cb => sub( $c ) {
        state $peers = [];
        push $peers->@*, $c;
        $t->app->log->info( "Added 1, Got " . ( scalar @$peers ) . " peers" );
        $_->send( 'Got topic: ' . $c->stash( 'topic' ) ) for $peers->@*;
        $c->on( finish => sub( $c, $tx ) {
            $peers = [ grep { $_ ne $c } $peers->@* ],
            $t->app->log->info( "Lost 1, Got " . ( scalar @$peers ) . " peers" );
        } );
        $c->finish if $c->stash( 'topic' ) =~ /STOP$/;
    } );
    my $broker_t = Test::Mojo->new( $broker );

    my $broker_url = $broker->ua->server->nb_url;
    $t->app->config->{broker} = 'ws://' . $broker_url->host_port;

    $t->websocket_ok( '/v1/upload' )
      ->message_ok
      ->message_is( 'Got topic: upload/dist', 'default to all uploaded dists' )
      ;

    my $peer = Test::Mojo->new( $t->app );
    $peer->websocket_ok( '/v1/upload/dist/Statocles' )
      ->message_ok
      ->message_is( 'Got topic: upload/dist/Statocles' )
      ->finish_ok;

    $t->message_ok
      ->message_is( 'Got topic: upload/dist/Statocles', 'got another message' )
      ->finish_ok
      ;

    $t->websocket_ok( '/v1/upload/author/STOP' )
      ->message_ok
      ->message_is( 'Got topic: upload/author/STOP' )
      ->finish_ok
      ;

    ok !@warnings, '... and we did it without warnings'
        or diag explain \@warnings;
};

done_testing;

