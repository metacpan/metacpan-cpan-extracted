use strict;
use warnings;
use Test::More;
use Test::Exception;
use Capture::Tiny;

use DBIx::ObjectMapper::Utils;
use DateTime;
use URI;

# load_class
{
    is DBIx::ObjectMapper::Utils::load_class('Getopt::Long'), 'Getopt::Long';
    {
        local $@;
        eval{ DBIx::ObjectMapper::Utils::load_class('NOEXSITSCLASS') };
        ok $@, $@;
    };
};

# loaded
{
    ok DBIx::ObjectMapper::Utils::loaded('Getopt::Long');
    ok not DBIx::ObjectMapper::Utils::loaded('NOEXSITSCLASS');
};

# normalized_hash_to_array
# normalized_array_to_hash
{
    my $base = [
        { title => 'title1', artist => 'artist1' },
        { title => 'title2', artist => 'artist2' },
        { title => 'title3', artist => 'artist3' },
        { title => 'title4', artist => 'artist4' },
    ];

    ok my ($header, $normalized) = DBIx::ObjectMapper::Utils::normalized_hash_to_array($base);

    dies_ok{
        DBIx::ObjectMapper::Utils::normalized_hash_to_array([
            [qw(a b)],
            [qw(c d)],
            [qw(e f)],
            [qw(g h)],
        ]);
    };

    is_deeply $header, [ 'artist', 'title' ];
    is_deeply $normalized, [
        [ qw(artist1 title1) ],
        [ qw(artist2 title2) ],
        [ qw(artist3 title3) ],
        [ qw(artist4 title4) ],
    ];

    my @rray;
    push @rray, $header, @$normalized;

    my $array_to_hash = DBIx::ObjectMapper::Utils::normalized_array_to_hash(\@rray);
    is_deeply $base, $array_to_hash;

    dies_ok {
        DBIx::ObjectMapper::Utils::normalized_array_to_hash([
            { a => 1, b => 2},
            { c => 3, d => 4},
        ]);
    };

    dies_ok{ DBIx::ObjectMapper::Utils::normalized_array_to_hash('a') };
}

{ # is_deeply

    my @sample = (
        # X Y result
        [ undef, undef, 1],
        [ undef, 'hoge', undef ],
        [ 'hoge', undef, undef ],
        [ 100, undef, undef ],
        [ 'b', 1, undef],
        [qw( a a ), 1 ],
        [ 'a', 10.2093827629, undef ],
        [
            { a => 1, b => 2 },
            { b => 2, a => 1 },
            1
        ],
        [
            { a => 1, b => 2 },
            { a => 1, b => 2, c => 3},
            undef
        ],
        [
            { a => 1, b => 2 } ,
            { a => 1, b => 1 },
            undef
        ],
        [
            [qw(a b c d e)],
            [qw(a b c d e)],
            1
        ],
        [
            [qw(a b c d e)],
            [qw(a b c d)],
            undef
        ],
        [
            [qw(a b c d e)],
            [qw(a b c e d)],
            undef
        ],
        [
            [qw(a b c d e)],
            { a => 1, b => 2, c => 3},
        ],
        [
            { a => 1, b => 2 },
            [qw(a b c d e)],
        ],
        [
            {
                a => 1,
                b => [ qw( a b c d )],
                c => { x => 100, y => 10.9872637 },
            },
            {
                b => [ qw( a b c d )],
                a => 1,
                c => { y => 10.9872637, x => 100 },
            },
            1,
        ],
        [ \'a', \'a', 1 ],
        [ \'a', \'b', undef ],
        [ +{}, +[], undef ],
        [ +{}, +{}, 1 ],
        [ +[], +[], 1 ],
    );

    is DBIx::ObjectMapper::Utils::is_deeply($_->[0], $_->[1]), $_->[2] for @sample;

    my ($stdout, $stderr) = Capture::Tiny::capture {
        DBIx::ObjectMapper::Utils::is_deeply(sub{}, sub{});
    };
    ok $stderr =~ /CODE is not supported/;

    # DateTime
    my $now = DateTime->now();
    is DBIx::ObjectMapper::Utils::is_deeply($now, $now), 1;
    my $now2 = DateTime->new( year => 2001 );
    is DBIx::ObjectMapper::Utils::is_deeply($now, $now2), undef;

    # URI
    my $uri = URI->new( 'http://www.yahoo.co.jp/' );
    is DBIx::ObjectMapper::Utils::is_deeply($uri, $uri), 1;
    my $uri2 = URI->new( 'http://www.google.co.jp/' );
    is DBIx::ObjectMapper::Utils::is_deeply($uri, $uri2), undef;

};

{ # merge_hashref

    my @input = (
        [
            { a => 1, b => 2 },
            { a => 1 }, { b => 2 },
        ],
        [
            { a => 1, b => 2 },
            { a => 1, b => 1 }, { b => 2 },
        ],
        [
            { a => 1, b => 2, c => 3 },
            { a => 1, b => 1, c => 3 }, { b => 2 },
        ],
        [
            { a => 1, b => 1, c => 3 },
            { b => 2 },{ a => 1, b => 1, c => 3 }
        ],

    );
    for( @input ) {
        is_deeply $_->[0],
            DBIx::ObjectMapper::Utils::merge_hashref( $_->[1], $_->[2] );
    }

};

done_testing();
