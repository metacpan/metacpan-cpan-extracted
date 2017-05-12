use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIx::ObjectMapper::Metadata;
use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper::Mapper;

use Scalar::Util;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{ CREATE TABLE artist (id integer primary key, firstname text not null, lastname text not null)}
    ]
});

my $meta = DBIx::ObjectMapper::Metadata->new( engine => $engine );
my $artist_table = $meta->table( artist => 'autoload' );

sub is_same_addr($$) {
    is Scalar::Util::refaddr($_[0]), Scalar::Util::refaddr($_[1]);
}

{ # map defined class
    my $mapped_class = 'MyTest::Basic::Artist';
    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $artist_table => $mapped_class
    );
    ok( DBIx::ObjectMapper::Mapper->is_initialized($mapped_class) );
    ok $mapped_class->can('__class_mapper__');
    is_same_addr $mapper, $mapped_class->__class_mapper__;

    for my $c ( @{$artist_table->columns} ) {
        is_deeply $mapper->attributes->property($c->name), $c;
    }

    my $input = { id => 1, firstname => 'f', lastname => 'l' };
    my $obj = $mapper->mapping($input);
    for( keys %$input ) {
        is $obj->__mapper__->get_val($_), $input->{$_};
    }
    $obj->__mapper__->set_val(id => 2);
    is $obj->id, 2;
    $obj->id(1);
    is_deeply $obj->__mapper__->reducing, $input;
};

{ # map auto generate class
    my $mapped_class = 'MyTest::Basic::ArtistAuto';
    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $meta->t('artist') => $mapped_class,
        accessors   => +{ auto => 1 },
        constructor => +{ auto => 1 },
    );

    ok( DBIx::ObjectMapper::Mapper->is_initialized($mapped_class) );
    ok $mapped_class->can('firstname');
    ok $mapped_class->can('lastname');
    ok $mapped_class->can('id');

    ok my $obj = $mapped_class->new(
        { id => 1, firstname => 'f', lastname => 'l' } );
    is $obj->firstname, 'f';
    is $obj->lastname, 'l';
    is $obj->id, 1;

    my $input = { id => 1, firstname => 'f', lastname => 'l' };
    my $obj2 = $mapper->mapping($input);
    for( keys %$input ) {
        is $obj2->__mapper__->get_val($_), $input->{$_};
    }
    $obj2->__mapper__->set_val(id => 2);
    is $obj2->id, 2;
    $obj2->id(1);
    is_deeply $obj2->__mapper__->reducing, $input;

};

{ # attribute prefix
    my $mapped_class = 'MyTest::Basic::ArtistAutoPrefix';
    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $meta->t('artist') => $mapped_class,
        accessors   => +{ auto => 1 },
        constructor => +{ auto => 1 },
        attributes  => +{ prefix => '_' },
    );

    ok (DBIx::ObjectMapper::Mapper->is_initialized($mapped_class));
    ok $mapped_class->can('_firstname');
    ok $mapped_class->can('_lastname');
    ok $mapped_class->can('_id');
    ok !$mapped_class->can('firstname');
    ok !$mapped_class->can('lastname');
    ok !$mapped_class->can('id');

    my %names = ( _id => 1, _firstname => 1, _lastname => 1 );
    ok( (grep { $names{$_} } $mapper->attributes->property_names) == 3 );

    is $mapper->attributes->property_info('_id')->name, 'id';
    is $mapper->attributes->property_info('_firstname')->name, 'firstname';
    is $mapper->attributes->property_info('_lastname')->name, 'lastname';

    ok my $obj = $mapped_class->new(
        { _id => 1, _firstname => 'f', _lastname => 'l' } );
    is $obj->_firstname, 'f';
    is $obj->_lastname, 'l';
    is $obj->_id, 1;

    my $input = { id => 1, firstname => 'f', lastname => 'l' };
    my $obj2 = $mapper->mapping($input);
    for( keys %$input ) {
        is $obj2->__mapper__->get_val('_' . $_), $input->{$_};
    }
    $obj2->__mapper__->set_val(_id => 2);
    is $obj2->_id, 2;
    $obj2->_id(1);
    is_deeply $obj2->__mapper__->reducing, $input;


#    dies_ok {
#        $mapped_class->new({ id => 1, firstname => 'f', lastname => 'l' } );
#    };

};

{ # attribute include option
    my $mapped_class = 'MyTest::Basic::ArtistAutoInclude';
    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $meta->t('artist') => $mapped_class,
        accessors   => +{ auto => 1 },
        constructor => +{ auto => 1 },
        attributes  => +{
            include => +[qw(id lastname)],
        }
    );

    ok $mapped_class->can('id');
    ok $mapped_class->can('lastname');
    ok !$mapped_class->can('firstname');

    ok my $obj = $mapped_class->new({ id => 1, lastname => 'l' } );
    is $obj->lastname, 'l';
    is $obj->id, 1;

    my $input = { id => 1, lastname => 'l' };
    my $obj2 = $mapper->mapping($input);
    for( keys %$input ) {
        is $obj2->__mapper__->get_val($_), $input->{$_};
    }
    $obj2->__mapper__->set_val(id => 2);
    is $obj2->id, 2;
    $obj2->id(1);
    is_deeply $obj2->__mapper__->reducing, $input;

#    dies_ok {
#        $mapped_class->new({ id => 1, firstname => 'f', lastname => 'l' } );
#    };
};

{ # attribute exclue option
    my $mapped_class = 'MyTest::Basic::ArtistAutoExclude';
    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $meta->t('artist') => $mapped_class,
        accessors   => +{ auto => 1 },
        constructor => +{ auto => 1 },
        attributes  => +{
            exclude => +[qw(lastname)],
        }
    );

    ok $mapped_class->can('firstname');
    ok $mapped_class->can('id');
    ok !$mapped_class->can('lastname');

    ok my $obj = $mapped_class->new(
        { id => 1, firstname => 'f' } );
    is $obj->firstname, 'f';
    is $obj->id, 1;

#    dies_ok {
#        $mapped_class->new({ id => 1, firstname => 'f', lastname => 'l' } );
#    };
};

{ # attribute include and exclude  option
    my $mapped_class = 'MyTest::Basic::ArtistAutoIncludeExclude';
    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $meta->t('artist') => $mapped_class,
        accessors   => +{ auto => 1 },
        constructor => +{ auto => 1 },
        attributes  => +{
            include => +[qw(firstname lastname)],
            exclude => +[qw(lastname)],
        }
    );

    ok $mapped_class->can('firstname');
    ok $mapped_class->can('id');
    ok !$mapped_class->can('lastname');

    ok my $obj = $mapped_class->new( { firstname => 'f' } );
    is $obj->firstname, 'f';

#    dies_ok {
#        $mapped_class->new({ id => 1, firstname => 'f', lastname => 'l' } );
#    };
};


{ # map not exsits class
    my $mapped_class = 'MyTest::Basic::ArtistAutoNotExists';
    dies_ok {
        my $mapper = DBIx::ObjectMapper::Mapper->new(
            $meta->t('artist') => $mapped_class,
        );
    };
};

{ # compile error class
    my $mapped_class = 'MyTest::Basic::ArtistCompileError';
    dies_ok {
        DBIx::ObjectMapper::Mapper->new(
            $meta->t('artist') => $mapped_class,
        );
    };
};

{ # accessor only
    my $mapped_class = 'MyTest::AO::Artist';
    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $meta->t('artist') => $mapped_class,
        constructor => +{ auto => 1 },
    );

    ok $mapped_class->can('new');
    ok $mapped_class->can('firstname');
    ok $mapped_class->can('lastname');
    ok $mapped_class->can('fullname');

    ok my $obj = $mapped_class->new(
        { id => 1, firstname => 'f', lastname => 'l' } );
    is $obj->id, 1;
    is $obj->firstname, 'f';
    is $obj->lastname, 'l';
};

{ # constructor only
    my $mapped_class = 'MyTest::CO::Artist';
    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $meta->t('artist') => $mapped_class,
        accessors   => +{ auto => 1 },
        constructor => { arg_type => 'ARRAY' },
    );

    ok $mapped_class->can('new');
    ok $mapped_class->can('firstname');
    ok $mapped_class->can('lastname');

    ok my $obj = $mapped_class->new( 1, 'f', 'l' );
    is $obj->id, 1;
    is $obj->firstname, 'f';
    is $obj->lastname, 'l';

    my $input = { id => 1, firstname => 'f', lastname => 'l' };
    my $obj2 = $mapper->mapping($input);
    for( keys %$input ) {
        is $obj2->__mapper__->get_val($_), $input->{$_};
    }
    $obj2->__mapper__->set_val(id => 2);
    is $obj2->id, 2;
    $obj2->id(1);
    is_deeply $obj2->__mapper__->reducing, $input;

};

{ # array contructor argument
    my $mapped_class = 'MyTest::Basic::ArtistArray';
    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $meta->t('artist') => $mapped_class,
        constructor => { arg_type => 'ARRAY' },
        attributes  => {
            properties  => [
                {
                    isa => $meta->t('artist')->c('lastname'),
                },
                {
                    isa => $meta->t('artist')->c('firstname'),
                },
                {
                    isa => $meta->t('artist')->c('id'),
                },
            ],
        }
    );

    my $obj = $mapper->mapping({
        id => 10,
        firstname => 'firstname',
        lastname => 'lastname',
    });

    is $obj->firstname, 'firstname';
    is $obj->lastname, 'lastname';
    is $obj->id, 10;

    my $input = { id => 1, firstname => 'f', lastname => 'l' };
    my $obj2 = $mapper->mapping($input);
    for( keys %$input ) {
        is $obj2->__mapper__->get_val($_), $input->{$_};
    }
    $obj2->__mapper__->set_val(id => 2);
    is $obj2->id, 2;
    $obj2->id(1);
    is_deeply $obj2->__mapper__->reducing, $input;
};

{ # not include primary key
    my $mapped_class = 'MyTest::Basic::ArtistArray2';

    dies_ok {
        ok my $mapper = DBIx::ObjectMapper::Mapper->new(
            $meta->t('artist') => $mapped_class,
            constructor => { arg_type => 'ARRAY' },
            attributes  => {
                properties  => [
                    {
                        isa => $meta->t('artist')->c('lastname'),
                    },
                    {
                        isa => $meta->t('artist')->c('firstname'),
                    },
                ],
            }
        );
    };
};

{ # blessed ArrayRefClass
    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $artist_table => 'MyTest::Basic::ArrayRefArtist',
        constructor => { arg_type => 'ARRAY' },
    );

    my $input = { id => 1, firstname => 'f', lastname => 'l' };
    ok my $obj = $mapper->mapping( $input );
    is $obj->id, 1;
    is $obj->firstname, 'f';
    is $obj->lastname, 'l';

    for( keys %$input ) {
        is $obj->__mapper__->get_val($_), $input->{$_};
    }
    $obj->__mapper__->set_val(id => 2);
    is $obj->id, 2;
    $obj->id(1);

    is_deeply $obj->__mapper__->reducing, $input;
};

{ # generic getter/setter
    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $artist_table => 'MyTest::Basic::GenericAccessorArtist',
        accessors => {
            generic_setter => 'set',
            generic_getter => 'get',
        }
    );

    my $input = { id => 1, firstname => 'f', lastname => 'l' };
    ok my $obj = $mapper->mapping( $input );
    is $obj->get('id'), 1;
    is $obj->get('firstname'), 'f';
    is $obj->get('lastname'), 'l';

    for( keys %$input ) {
        is $obj->__mapper__->get_val($_), $input->{$_};
    }
    $obj->__mapper__->set_val(id => 2);
    is $obj->get('id'), 2;
    $obj->set('id' => 1);
    is_deeply $obj->__mapper__->reducing, $input;

};


done_testing;

__END__
