#! perl

use Test2::V0;

use Config::XrmDatabase;

use experimental 'signatures';

sub create_db ( %args ) {
    my $db = Config::XrmDatabase->new( %args );
    $db->insert( 'xmh*Paned*activeForeground',       'red' );
    $db->insert( '*incorporate.Foreground',          'blue' );
    $db->insert( 'xmh.toc*Command*activeForeground', 'green' );
    $db->insert( 'xmh.toc*?.Foreground',             'white' );
    $db->insert( 'xmh.toc*Command.activeForeground', 'black' );

    $db;
}

sub query ( $which = 'query', %args ) {

    my $fail = delete $args{fail};

    my ( %new_args, %query_args );

    if ( $which eq 'new' ) {
        %new_args = map {; "query_${_}" => $args{$_} } keys %args;
    }
    elsif ( $which eq 'query' ) {
        %query_args = %args;
    }

    else {
        die "unexpected which: $which";
    }

    my $db = create_db( %new_args );

    my $name = $fail ? 'What.Me.Worry.About.Anything' : 'Xmh.Paned.Box.Command.Foreground';

    $db->query( $name,
        'xmh.toc.messagefunctions.incorporate.activeForeground', %query_args );
}

sub return_value ( $which ) {

    subtest 'default' => sub {
        is( query( $which ), 'black', 'value' );
    };

    subtest 'value' => sub {
        is( query( $which, return_value => 'value' ), 'black', 'value' );
    };

    subtest 'reference' => sub {
        is( query( $which, return_value => 'reference' )->$*, 'black', 'value' );
    };

    subtest 'all' => sub {
        is(
            query( $which, return_value => 'all' ),
            hash {
                field value => 'black';
                field key =>
                  [ 'xmh', 'toc', '*', 'Command', 'activeForeground' ];
                field match_count => 1;
                end;
            },
            'value'
        );
    };
}

sub failure ( $which ) {

    subtest 'default' => sub {
        is( query( $which, fail => 1 ), U(), 'value' );
    };

    subtest 'undef' => sub {
        is( query( $which, fail => 1, on_failure => 'undef' ), U(), 'value' );
    };

    subtest 'throw' => sub {
        my $res = dies {
            query( $which, fail => 1, on_failure => 'throw' );
        };

        isa_ok( $res, ['Config::XrmDatabase::Failure::query'], 'exception' );
        like( "$res",
              qr/ \Qxmh.toc.messagefunctions.incorporate.activeForeground\E
                  .*
                 \QWhat.Me.Worry.About.Anything\E
                /x
            );
    };

    subtest 'code' => sub {
        my $failed;
        is(
            query( $which, fail => 1, on_failure => sub { $failed = 7; 42; } ),
            42,
            "return value"
        );
        is( $failed, 7, "code ran" );
    };

}

subtest 'return value' => sub {

    subtest 'constructor args', \&return_value, 'new';
    subtest 'query args', \&return_value, 'query';

};

subtest failure => sub {

    subtest 'constructor args', \&failure, 'new';
    subtest 'query args', \&failure, 'query';

};

done_testing;
