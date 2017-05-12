use strict;
use warnings;
use lib '../lib';
use AnyEvent::Groonga;
use Test::More;
use FindBin;
use File::Spec;

_cleanup();

my $g = AnyEvent::Groonga->new( debug => 0 );
my $groonga_path = $g->groonga_path;
my $test_database_path
    = File::Spec->catfile( $FindBin::RealBin, "data", "test.db" );

unless ( $groonga_path and -e $groonga_path ) {
    plan skip_all => "groonga is not installed.";
}
else {
    plan tests => 21;
}

`$groonga_path -n $test_database_path quit`;

$g->protocol("local_db");
$g->database_path(
    File::Spec->catfile( $FindBin::RealBin, "data", "test.db" ) );

# status
my $result = $g->call("status")->recv;
is( $result->body->{uptime},         0 );
is( $result->body->{cache_hit_rate}, 0 );

# table_careate
$result = $g->call(
    table_create => {
        name     => "Site",
        flags    => "TABLE_HASH_KEY",
        key_type => "ShortText",
    }
)->recv;

is( $result->body, "true" );

# select
$result = $g->call( select => { table => "Site" } )->recv;

is( $result->hit_num, 0 );
is_deeply( $result->columns, [ '_id', '_key' ] );

# column_create
$result = $g->call(
    column_create => {
        table => "Site",
        name  => "title",
        flags => "COLUMN_SCALAR",
        type  => "ShortText",
    }
)->recv;

is( $result->body, "true" );

# table_create Terms
$result = $g->call(
    table_create => {
        name              => "Terms",
        flags             => "TABLE_PAT_KEY|KEY_NORMALIZE",
        key_type          => "ShortText",
        default_tokenizer => "TokenBigram",
    }
)->recv;

is( $result->body, "true" );

# column_create Terms
$result = $g->call(
    column_create => {
        table  => "Terms",
        name   => "blog_title",
        flags  => "COLUMN_INDEX|WITH_POSITION",
        type   => "Site",
        source => "title",
    }
)->recv;

is( $result->body, "true" );

# load
my $data = [
    {   _key  => "http://example.org/",
        title => "This is test record 1!",
    },
    {   _key  => "http://example.net/",
        title => "test record 2.",
    },
    {   _key  => "http://example.com/",
        title => "test test record three.",
    },
    {   _key  => "http://example.net/afr",
        title => "test record four.",
    },
    {   _key  => "http://example.org/aba",
        title => "test test test record five.",
    },
    {   _key  => "http://example.com/rab",
        title => "test test test test record six.",
    },
    {   _key  => "http://example.net/atv",
        title => "test test test record seven.",
    },
    {   _key  => "http://example.org/gat",
        title => "test test record eight.",
    },
    {   _key  => "http://example.com/vdw",
        title => "test test record nine.",
    },
];
$result = $g->call(
    load => {
        table  => "Site",
        values => $data,
    }
)->recv;

is( $result->body, 9 );

# select by _id
$result = $g->call(
    select => {
        table => "Site",
        query => "_id:1",
    }
)->recv;

is_deeply(
    $result->items->[0],
    {   '_id'   => 1,
        '_key'  => 'http://example.org/',
        'title' => 'This is test record 1!'
    }
);

# select by _key
$result = $g->call(
    select => {
        table => "Site",
        query => '_key:\"http://example.org/\"',
    }
)->recv;

is_deeply(
    $result->items->[0],
    {   '_id'   => 1,
        '_key'  => 'http://example.org/',
        'title' => 'This is test record 1!'
    }
);

# full text search
$result = $g->call(
    select => {
        table => "Site",
        query => 'title:@this',
    }
)->recv;

is_deeply(
    $result->items->[0],
    {   '_id'   => 1,
        '_key'  => 'http://example.org/',
        'title' => 'This is test record 1!'
    }
);

$result = $g->call(
    select => {
        table         => "Site",
        match_columns => "title",
        query         => "this",
    }
)->recv;

is_deeply(
    $result->items->[0],
    {   '_id'   => 1,
        '_key'  => 'http://example.org/',
        'title' => 'This is test record 1!'
    }
);

# output_columns

$result = $g->call(
    select => {
        table          => "Site",
        output_columns => [qw(_key title _score )],
        query          => 'title:@test',
    }
)->recv;

is( $result->hit_num, 9 );

# offset and limit

$result = $g->call(
    select => {
        table  => "Site",
        offset => 0,
        limit  => 3,
    }
)->recv;

is_deeply(
    $result->items,
    [   {   '_id'   => 1,
            '_key'  => 'http://example.org/',
            'title' => 'This is test record 1!'
        },
        {   '_id'   => 2,
            '_key'  => 'http://example.net/',
            'title' => 'test record 2.'
        },
        {   '_id'   => 3,
            '_key'  => 'http://example.com/',
            'title' => 'test test record three.'
        }
    ]
);

$result = $g->call(
    select => {
        table  => "Site",
        offset => 3,
        limit  => 3,
    }
)->recv;

is_deeply(
    $result->items,
    [   {   '_id'   => 4,
            '_key'  => 'http://example.net/afr',
            'title' => 'test record four.'
        },
        {   '_id'   => 5,
            '_key'  => 'http://example.org/aba',
            'title' => 'test test test record five.'
        },
        {   '_id'   => 6,
            '_key'  => 'http://example.com/rab',
            'title' => 'test test test test record six.'
        }
    ]
);

$result = $g->call(
    select => {
        table  => "Site",
        offset => 7,
        limit  => 3,
    }
)->recv;

is_deeply(
    $result->items,
    [   {   '_id'   => 8,
            '_key'  => 'http://example.org/gat',
            'title' => 'test test record eight.'
        },
        {   '_id'   => 9,
            '_key'  => 'http://example.com/vdw',
            'title' => 'test test record nine.'
        }
    ]
);

# sortby

$result = $g->call(
    select => {
        table  => "Site",
        sortby => "-_id",
    }
)->recv;

is_deeply(
    $result->items,
    [   {   '_id'   => 9,
            '_key'  => 'http://example.com/vdw',
            'title' => 'test test record nine.'
        },
        {   '_id'   => 8,
            '_key'  => 'http://example.org/gat',
            'title' => 'test test record eight.'
        },
        {   '_id'   => 7,
            '_key'  => 'http://example.net/atv',
            'title' => 'test test test record seven.'
        },
        {   '_id'   => 6,
            '_key'  => 'http://example.com/rab',
            'title' => 'test test test test record six.'
        },
        {   '_id'   => 5,
            '_key'  => 'http://example.org/aba',
            'title' => 'test test test record five.'
        },
        {   '_id'   => 4,
            '_key'  => 'http://example.net/afr',
            'title' => 'test record four.'
        },
        {   '_id'   => 3,
            '_key'  => 'http://example.com/',
            'title' => 'test test record three.'
        },
        {   '_id'   => 2,
            '_key'  => 'http://example.net/',
            'title' => 'test record 2.'
        },
        {   '_id'   => 1,
            '_key'  => 'http://example.org/',
            'title' => 'This is test record 1!'
        }
    ]
);

$result = $g->call(
    select => {
        table          => "Site",
        query          => 'title:@test',
        output_columns => [qw(_id _score title)],
        sortby         => '_score',
    }
)->recv;

is_deeply(
    $result->items,
    [   {   '_score' => 1,
            '_id'    => 1,
            'title'  => 'This is test record 1!'
        },
        {   '_score' => 1,
            '_id'    => 2,
            'title'  => 'test record 2.'
        },
        {   '_score' => 1,
            '_id'    => 4,
            'title'  => 'test record four.'
        },
        {   '_score' => 2,
            '_id'    => 3,
            'title'  => 'test test record three.'
        },
        {   '_score' => 2,
            '_id'    => 9,
            'title'  => 'test test record nine.'
        },
        {   '_score' => 2,
            '_id'    => 8,
            'title'  => 'test test record eight.'
        },
        {   '_score' => 3,
            '_id'    => 7,
            'title'  => 'test test test record seven.'
        },
        {   '_score' => 3,
            '_id'    => 5,
            'title'  => 'test test test record five.'
        },
        {   '_score' => 4,
            '_id'    => 6,
            'title'  => 'test test test test record six.'
        }
    ]
);

$result = $g->call(
    select => {
        table          => "Site",
        query          => 'title:@test',
        output_columns => [qw(_id _score title)],
        sortby         => [qw(_score _id)],
    }
)->recv;

is_deeply(
    $result->items,
    [   {   '_score' => 1,
            '_id'    => 1,
            'title'  => 'This is test record 1!'
        },
        {   '_score' => 1,
            '_id'    => 2,
            'title'  => 'test record 2.'
        },
        {   '_score' => 1,
            '_id'    => 4,
            'title'  => 'test record four.'
        },
        {   '_score' => 2,
            '_id'    => 3,
            'title'  => 'test test record three.'
        },
        {   '_score' => 2,
            '_id'    => 8,
            'title'  => 'test test record eight.'
        },
        {   '_score' => 2,
            '_id'    => 9,
            'title'  => 'test test record nine.'
        },
        {   '_score' => 3,
            '_id'    => 5,
            'title'  => 'test test test record five.'
        },
        {   '_score' => 3,
            '_id'    => 7,
            'title'  => 'test test test record seven.'
        },
        {   '_score' => 4,
            '_id'    => 6,
            'title'  => 'test test test test record six.'
        }
    ]
);

# filter test.
$result = $g->call(
    select => {
        table          => "Site",
        query          => 'title:@test',
        filter         => '_id > 1 && _id < 5',
        output_columns => [qw(_id _score title)],
        sortby         => [qw(_score _id)],
    }
)->recv;

is_deeply(
    $result->items,
    [   {   '_score' => 3,
            '_id'    => 2,
            'title'  => 'test record 2.'
        },
        {   '_score' => 3,
            '_id'    => 4,
            'title'  => 'test record four.'
        },
        {   '_score' => 4,
            '_id'    => 3,
            'title'  => 'test test record three.'
        }
    ]
);

sub _cleanup {
    my @files = glob( File::Spec->catfile( $FindBin::RealBin, "data", "*" ) );
    if ( @files > 0 ) {
        for (@files) {
            unlink $_;
        }
    }
}
