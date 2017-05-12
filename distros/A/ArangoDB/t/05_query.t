use strict;
use Test::More;
use Test::Fatal qw(lives_ok dies_ok exception);
use Test::Mock::Guard;
use ArangoDB;
use JSON;

if ( !$ENV{TEST_ARANGODB_PORT} ) {
    plan skip_all => 'Can"t find port of arangod';
}

my $port   = $ENV{TEST_ARANGODB_PORT};
my $config = {
    host => 'localhost',
    port => $port,
};

init();

sub init {
    my $db = ArangoDB->new($config);
    map { $_->drop } @{ $db->collections };
    my $users = $db->collection('users');
    $users->save( { name => 'John Doe', age => 42 } );
    $users->save( { name => 'Foo',      age => 10 } );
    $users->save( { name => 'Bar',      age => 20 } );
    $users->save( { name => 'Baz',      age => 11 } );
}

subtest 'Normal statement' => sub {
    my $db  = ArangoDB->new($config);
    my $sth = $db->query('FOR u IN users SORT u.name ASC RETURN u');
    is "$sth", 'FOR u IN users SORT u.name ASC RETURN u';
    my $cur = $sth->execute();
    my @docs;
    while ( my $doc = $cur->next() ) {
        push @docs, $doc->content;
    }
    my $expects = [
        { name => 'Bar',      age => 20 },
        { name => 'Baz',      age => 11 },
        { name => 'Foo',      age => 10 },
        { name => 'John Doe', age => 42 },
    ];
    is_deeply( \@docs, $expects );

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_post => sub {die}
            }
        );
        $sth->execute();
    }, qr/^Failed to execute query/;

};

subtest 'Use bind var1' => sub {
    my $db  = ArangoDB->new($config);
    my $sth = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u');
    $sth->bind( age => 10 );
    is_deeply $sth->bind_vars, { age => 10 };
    is $sth->bind_vars('age'), 10;

    my $cur = $sth->execute();
    my @docs;
    while ( my $doc = $cur->next() ) {
        push @docs, $doc->content;
    }

    my $expects = [ { name => 'Bar', age => 20 }, { name => 'Baz', age => 11 }, { name => 'John Doe', age => 42 }, ];
    is_deeply \@docs, $expects;
    my $cur2 = $sth->bind( { age => 20 } )->execute();
    my @docs2;
    while ( my $doc = $cur2->next() ) {
        push @docs2, $doc->content;
    }
    is_deeply \@docs2, [ { name => 'John Doe', age => 42 }, ];

    my $docs3 = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u')->bind( age => 10 )
        ->execute->all;
    is_deeply [ map { $_->content } @$docs3 ], $expects;

    my $cur3 = $sth->bind( { age => [ 1 .. 10 ] } )->execute( { do_count => 1, batch_size => 0 } );
    is $cur3->length, 0;

    my $docs4
        = $db->query('FOR u IN users FILTER u.age == @age SORT u.name ASC RETURN u')->bind( age => 11 )->execute->all;
    is scalar @$docs4, 1;
    is_deeply $docs4->[0]->content, { name => 'Baz', age => 11 };

    like exception {
        $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u')->execute;
    }, qr/^Failed to execute query/;

    like exception {
        $sth->bind( age => {} );
    }, qr/^Invalid bind parameter value/;
};

subtest 'Use bind var2' => sub {
    my $db  = ArangoDB->new($config);
    my $sth = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u');
    lives_ok {
        $sth->bind( [] );
        $sth->bind( 10, 0 );
        $sth->bind( foo => undef );
        $sth->bind( bar => q{} );
    };
};

subtest 'batch query' => sub {
    my $db  = ArangoDB->new($config);
    my $sth = $db->query('FOR u IN users FILTER u.age > @age SORT u.age ASC RETURN u');
    $sth->bind( age => 10 );
    my $cur = $sth->execute( { batch_size => 1, do_count => 1 } );
    is $cur->count,  3;
    is $cur->length, 1;
    my @docs;
    while ( my $doc = $cur->next() ) {
        push @docs, $doc->content;
    }

    my $expects = [ { name => 'Baz', age => 11 }, { name => 'Bar', age => 20 }, { name => 'John Doe', age => 42 }, ];
    is_deeply \@docs, $expects;

    my $docs2
        = $db->query('FOR u IN users FILTER u.age > @age SORT u.age ASC RETURN u')->bind( age => 10 )->execute->all;
    is_deeply [ map { $_->content } @$docs2 ], $expects;
};

subtest 'delete cursor' => sub {
    my $db  = ArangoDB->new($config);
    my $sth = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u');
    $sth->bind( age => 10 );
    my $cur = $sth->execute( { batch_size => 2, } );
    $cur->delete;
    like exception {
        while ( my $doc = $cur->next() ) {
        }
    }, qr/^Failed to get next batch cursor/;

    like exception {
        $cur->delete;
    }, qr/^Failed to delete cursor/;

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_delete => sub {die}
            }
        );
        $cur->delete;
    }, qr/^Failed to delete cursor/;

};

subtest 'parse query' => sub {
    my $db    = ArangoDB->new($config);
    my $binds = $db->query('FOR u IN users SORT u.name ASC RETURN u')->parse();
    is scalar @$binds, 0;

    $binds = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u')->parse();
    is_deeply $binds, [qw/age/];

    like exception {
        $binds = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETUR')->parse();
    }, qr/^Failed to parse query/;
};

subtest 'explain query' => sub {
    my $db   = ArangoDB->new($config);
    my $plan = $db->query('FOR u IN users SORT u.name ASC RETURN u')->explain();
    ok $plan && ref($plan) eq 'ARRAY';
    like exception { $db->query('FOR u IN users SORT u.name ASC RETURN ')->explain(); }, qr/^Failed to explain query/;
};

subtest 'cursor' => sub {
    my $db   = ArangoDB->new($config);
    my $conn = $db->{connection};
    my $cur  = ArangoDB::Cursor->new( $conn, {} );
    isa_ok $cur, 'ArangoDB::Cursor';

    $cur = ArangoDB::Cursor->new( $conn, { result => {} } );
    ok $cur;

    $cur = ArangoDB::Cursor->new(
        $conn,
        {   result => [
                {   _id    => '0/0',
                    '_rev' => 0,
                    foo    => [
                        { bar => 1 }, [1], 42, undef, \do { my $var = 1 }
                    ]
                },
                undef,
            ]
        }
    );
    my $doc = $cur->next;
    isa_ok $doc, 'ArangoDB::Document';
    
    like exception{ $cur->next }, qr/^Invalid argument for ArangoDB\:\:Document/;
    
    pass();
};

done_testing;

__END__
