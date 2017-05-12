use Test::More;
use warnings;
use strict;

use Try::Tiny;
use Data::Morph;
use Data::Morph::Backend::DBIC;
use Data::Morph::Backend::Object;
use Data::Morph::Backend::Raw;
use Moose::Util::TypeConstraints qw/class_type/;
use DBD::SQLite;

{
    package Foo;
    use Moose;
    use namespace::autoclean;

    has foo => ( is => 'ro', isa => 'Int', default => 1, writer => 'set_foo' );
    has bar => ( is => 'rw', isa => 'Str', default => '123ABC');
    has flarg => ( is => 'rw', isa => 'Str', default => 'boo');
    has zarp => ( is => 'rw', isa => 'Str', default =>  'zoop');
    1;
}

{
    package Blah;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('blah');
    __PACKAGE__->add_columns(qw/some_foo bar_zoop ker_flarg_fluffle/);
    __PACKAGE__->set_primary_key('some_foo');
    1;
}

{
    package Bar;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->register_class('Blah', 'Blah');
    1;
}

my $schema = Bar->connect('dbi:SQLite:dbname=','','');
$schema->deploy({ add_drop_table => 1 });
$schema->resultset('Blah')->all();

my $map1 =
[
    {
        recto =>
        {
            read => 'foo',
            write => 'set_foo',
        },
        verso => '/FOO',
    },
    {
        recto =>
        {
            read => ['bar', sub { my ($f) = @_; $f =~ s/\d+//; $f } ], # post read
            write => [ 'bar', sub { "123".shift(@_) } ], # pre write
        },
        verso =>
        {
            read => '/BAR|/bar',
            write => '/BAR',
        }
    },
    {
        recto => 'flarg',
        verso => '/some/path/goes/here/flarg'
    },
    {
        recto =>
        {
            read => [ undef, sub { 'NOTZOOP' } ],
        },
        verso =>
        {
            read => [ '/ZOOP', sub { 'BIGZOOP' } ],
            write => '/ZOOP',
        },
    },
];

my $map2 =
[
    {
        recto => $map1->[0]->{recto},
        verso => 'some_foo',
    },
    {
        recto => $map1->[1]->{recto},
        verso => 'bar_zoop',
    },
    {
        recto => $map1->[2]->{recto},
        verso => 'ker_flarg_fluffle',
    },
];

my $map3 =
[
    {
        recto => $map2->[0]->{verso},
        verso => $map1->[0]->{verso},
    },
    {
        recto => $map2->[1]->{verso},
        verso => $map1->[1]->{verso},
    },
    {
        recto => $map2->[2]->{verso},
        verso => $map1->[2]->{verso},
    },
];

my $map4 =
[
    {
        recto => $map2->[0]->{verso},
        verso => '/A/*[0]/xxx',
    },
    {
        recto => $map2->[1]->{verso},
        verso => '/A/*[0]/yyy',
    },
    {
        recto => $map2->[2]->{verso},
        verso => '/A/*[1]/zzz',
    },

    {
        recto => $map2->[2]->{verso},
        verso => '/B/*[1]',
    },

    {
        recto => $map2->[0]->{verso},
        verso => '/C/*[4]/xxx',
    },
    {
        recto => $map2->[2]->{verso},
        verso => '/D/*[3]',
    },

    {
        recto => $map2->[0]->{verso},
        verso => '/E/*[0]/xxx/F/*[0]/aaa',
    },
    {
        recto => $map2->[1]->{verso},
        verso => '/E/*[0]/xxx/F/*[1]/aaa',
    },
    {
        recto => $map2->[1]->{verso},
        verso => '/G/*[0]/*[1]/xxx/H/*[1]/aaa',
    }
];

my $map5 = [ { recto => { read => 'foo', write => 'set_foo' }, verso => '/Bar|/bar' } ];

my $obj_backend = Data::Morph::Backend::Object->new(input_type => class_type('Foo'),  new_instance => sub { Foo->new() });
my $raw_backend = Data::Morph::Backend::Raw->new();
my $dbc_backend = Data::Morph::Backend::DBIC->new(result_set => $schema->resultset('Blah'));

try
{
    my $morpher = Data::Morph->new(
        recto => $obj_backend,
        verso => $raw_backend,
        map => $map1
    );

    my $foo1 = Foo->new();
    my $hash = $morpher->morph($foo1);

    is_deeply
    (
        $hash,
        {
            FOO => 1,
            BAR => 'ABC',
            some =>
            {
                path =>
                {
                    goes =>
                    {
                        here =>
                        {
                            flarg => 'boo'
                        }
                    }
                }
            },
            ZOOP => 'NOTZOOP',
        },
        'Output hash matches what is expected'
    );

    my $foo2 = $morpher->morph($hash);
    $hash->{bar} = delete $hash->{BAR};
    my $foo3 = $morpher->morph($hash);

    is($foo2->foo, $foo1->foo, 'foo matches on object');
    is($foo2->bar, $foo1->bar, 'bar matches on object');
    is($foo3->bar, $foo1->bar, 'bar matches with alternation');
    is($foo2->flarg, $foo1->flarg, 'flarg matches on object');
    is($foo2->zarp, $foo1->zarp, 'zarp matches on object');
}
catch
{
    fail($_);
};

my $fail = 0;
try
{
    my $morpher = Data::Morph->new(
        recto => $obj_backend,
        verso => $raw_backend,
        map => $map5
    );

    my $foo1 = Foo->new();
    my $hash = $morpher->morph($foo1);
    
    $fail = 1;
}
catch
{
    if($_ =~ m/Alternations/)
    {
        pass('Got the correct error when attempting to use an alternation for writing');
    }
    else
    {
        fail($_);
    }
};

if($fail)
{
    fail('Alternations should not be allowed for writes');
}

try
{
    my $morpher = Data::Morph->new(
        recto => $obj_backend,
        verso => $dbc_backend,
        map => $map2
    );

    my $foo1 = Foo->new();
    my $row = $morpher->morph($foo1);

    is($row->some_foo, '1', 'row data matches foo');
    is($row->bar_zoop, 'ABC', 'row data matches bar');
    is($row->ker_flarg_fluffle, 'boo', 'row data matches flarg');

    $row->insert();

    my $foo2 = $morpher->morph($row);
    is($foo2->foo, $foo1->foo, 'foo matches on object');
    is($foo2->bar, $foo1->bar, 'bar matches on object');
    is($foo2->flarg, $foo1->flarg, 'bar matches on object');

}
catch
{
    fail($_);
};

try
{
    my $morpher = Data::Morph->new(
        recto => $dbc_backend,
        verso => $raw_backend,
        map => $map3,
    );

    my $row = $schema->resultset('Blah')->first();

    my $hash = $morpher->morph($row);

    is_deeply
    (
        $hash,
        {
            FOO => 1,
            BAR => 'ABC',
            some =>
            {
                path =>
                {
                    goes =>
                    {
                        here =>
                        {
                            flarg => 'boo'
                        }
                    }
                }
            }
        },
        'Output hash matches what is expected'
    );

    my $row2 = $morpher->morph($hash);

    is($row2->some_foo, $row->some_foo, 'row data matches foo');
    is($row2->bar_zoop, $row->bar_zoop, 'row data matches bar');
    is($row2->ker_flarg_fluffle, $row->ker_flarg_fluffle, 'row data matches flarg');
}
catch
{
    fail($_);
};

try
{
    delete $map1->[1]->{verso}->{write};
    delete $map1->[0]->{recto}->{write};

    my $morpher = Data::Morph->new(
        recto => $obj_backend,
        verso => $raw_backend,
        map => $map1
    );

    my $foo1 = Foo->new();
    my $hash = $morpher->morph($foo1);

    is_deeply
    (
        $hash,
        {
            FOO => 1,
            some =>
            {
                path =>
                {
                    goes =>
                    {
                        here =>
                        {
                            flarg => 'boo'
                        }
                    }
                }
            },
            ZOOP => 'NOTZOOP',
        },
        'Output hash matches what is expected when missing writer'
    );

    $hash->{FOO} = 9000;
    $hash->{BAR} = 'ABC';
    my $foo2 = $morpher->morph($hash);

    isnt($foo2->foo, 9000, 'foo does not match on object');
    is($foo2->bar, $foo1->bar, 'bar matches on object');
    is($foo2->flarg, $foo1->flarg, 'flarg matches on object');
}
catch
{
    fail($_);
};

try
{
    my $morpher = Data::Morph->new(
        recto => $dbc_backend,
        verso => $raw_backend,
        map => $map4,
    );

    my $row = $schema->resultset('Blah')->first();

    my $hash = $morpher->morph($row);
    
    is_deeply
    (
        $hash,
        {
            'A' => [
                {
                    'xxx' => '1',
                    'yyy' => 'ABC'
                },
                {
                    'zzz' => 'boo'
                }
            ],
            'D' => [
                undef,
                undef,
                undef,
                'boo'
            ],
            'C' => [
                undef,
                undef,
                undef,
                undef,
                {
                    'xxx' => '1'
                }
            ],
            'E' => [
                {
                    'xxx' => {
                        'F' => [
                            {
                                'aaa' => '1'
                            },
                            {
                                'aaa' => 'ABC'
                            }
                        ]
                    }
                }
            ],
            'B' => [
                undef,
                'boo'
            ],
            'G' => [
                [
                    undef,
                    {
                        'xxx' => {
                            'H' => [
                                undef,
                                {
                                    'aaa' => 'ABC'
                                }
                            ]
                        }
                    }
                ]
             ],
        },
        'Output hash matches what is expected'
    );
}
catch
{
    fail($_);
};

done_testing();


