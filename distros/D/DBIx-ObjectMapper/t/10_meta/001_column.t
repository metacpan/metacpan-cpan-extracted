use strict;
use warnings;
use Test::More;
use Test::Exception;
use Encode;

use DBIx::ObjectMapper::Metadata::Table::Column;
use DBIx::ObjectMapper::Metadata::Table::Column::Type::Text;

my $c = DBIx::ObjectMapper::Metadata::Table::Column->new(
    {   name        => 'type',
        sep         => '.',
        table       => 'b',
        type => DBIx::ObjectMapper::Metadata::Table::Column::Type::Text->new( undef, 'utf8' ),
        is_nullable => 1,
        validation  => undef,
        on_update   => sub { '-on_update' },
        default     => sub { '-default' },
        readonly    => undef,
        from_storage   => sub { $_[0] . '-inflate' },
        to_storage     => sub { $_[0] . '-deflate' },
        server_default => undef,
    }
);

{ # basic
    is $c->name, 'type', 'get name';
    is $c->sep, '.', 'get sep';
    is $c->table, 'b', 'get table';
    is $c, 'b.type', 'to_string';
};

{ # oprator
    is_deeply $c->op('%%', 'opcheck'), [ 'b.type', '%%', 'opcheck-deflate'], 'custom operator';
    is_deeply $c->eq('eqcheck'), [ 'b.type', '=', 'eqcheck-deflate'], 'eq';

    is_deeply $c == 'a', [ 'b.type', '=', 'a-deflate' ], '==';
    is_deeply $c eq 'a', [ 'b.type', '=', 'a-deflate' ], 'eq';

    is_deeply $c !=  1 , [ 'b.type', '!=', '1-deflate' ], '!=';
    is_deeply $c ne  1 , [ 'b.type', '!=', '1-deflate' ], 'ne';

    is_deeply $c <=  2 , [ 'b.type', '<=', '2-deflate' ], '<=';
    is_deeply $c le  2 , [ 'b.type', '<=', '2-deflate' ], 'le';

    is_deeply $c >=  3 , [ 'b.type', '>=', '3-deflate' ], '>=';
    is_deeply $c ge  3 , [ 'b.type', '>=', '3-deflate' ], 'ge';

    is_deeply $c >   4 , [ 'b.type', '>', '4-deflate' ], '>';
    is_deeply $c gt  4 , [ 'b.type', '>', '4-deflate' ], 'gt';

    is_deeply $c <   5 , [ 'b.type', '<', '5-deflate'], '<';
    is_deeply $c lt  5 , [ 'b.type', '<', '5-deflate'], 'lt';

    is_deeply $c->between(1, 2), [ 'b.type', 'BETWEEN', ['1-deflate' , '2-deflate' ]], 'between';
    is_deeply $c->in(1,2,3,4), [ 'b.type', 'IN', ['1-deflate' ,'2-deflate' ,'3-deflate' ,'4-deflate'] ], 'IN';
    is_deeply $c->not_in(1,2,3,4), [ 'b.type', 'NOT IN', ['1-deflate' ,'2-deflate' ,'3-deflate' ,'4-deflate'] ], 'NOT IN';
    is_deeply $c->like('%Led%'), [ 'b.type', 'LIKE', '%Led%-deflate'], 'LIKE';
    is_deeply $c->not_like('%Led%'), [ 'b.type', 'NOT LIKE', '%Led%-deflate'], 'NOT LIKE';

    is $c->desc, 'b.type DESC', 'DESC';

    is_deeply $c->as('t'), [ 'b.type', 't' ], 'as(to_array)';
    is_deeply { $c->is('b') }, { 'type' => 'b' }, 'is(hash)';
    is_deeply { $c->is(undef) } , { 'type' => undef }, 'is(undef)';
};

{ # property
    is ref($c->type), 'DBIx::ObjectMapper::Metadata::Table::Column::Type::Text', 'property type';
    is $c->is_nullable, 1, 'property is_nullable';
};

{ # from/to_storage
    use utf8;
    is $c->from_storage('あ'), 'あ-inflate', 'from_storage';
    is $c->to_storage(), '-default-deflate', 'to_storage default';
    is $c->to_storage({ type => 'い'}), Encode::encode('utf8', 'い-deflate'), 'to_stroage utf8';
    is $c->to_storage_on_update(), '-on_update-deflate', 'to_storage_on_update';
};

{ # vaidation

    $c = DBIx::ObjectMapper::Metadata::Table::Column->new(
        {   name        => 'type',
            sep         => '.',
            table       => 'b',
            type        => DBIx::ObjectMapper::Metadata::Table::Column::Type::Text->new,
            is_nullable => 1,
            validation  => sub { $_[0] =~ /^\d+$/ },
            on_update   => undef,
            default     => undef,
            readonly    => undef,
            from_storage => undef,
            to_storage     => undef,
            server_default => undef,
        }
    );

    ok $c->validation->(1), 'do validation';
    ok !$c->validation->('a'), 'do vlaidation';
    dies_ok { $c->to_storage({ type => 'foo'}) } 'to_storage invalid';
    is $c->to_storage({ type=> 2 }), 2, 'to_storage valid';
};

{ # readonly
    $c = DBIx::ObjectMapper::Metadata::Table::Column->new(
        {   name        => 'type',
            sep         => '.',
            table       => 'b',
            type        => DBIx::ObjectMapper::Metadata::Table::Column::Type::Text->new,
            is_nullable => 1,
            validation  => undef,
            on_update   => undef,
            default     => undef,
            readonly    => 1,
            to_storage     => undef,
            from_storage     => undef,
            server_default => undef,
        }
    );

    ok $c->readonly, 'readonly';
    ok $c->to_storage({ type => 'str'}), 'readonly to_storage';
    dies_ok { $c->to_storage_on_update({ type => 'str'}) } 'readonly to_storage_on_update';
};

{ # func
    ok my $func = $c->func('substr', 0, 10), 'function';
    is ref($func), 'DBIx::ObjectMapper::Metadata::Table::Column::Func', 'function ref';
    is $func . q{}, 'SUBSTR(b.type, 0, 10)', 'function as_str';
    my $op = $func == 1;
    is_deeply $op, [ 'SUBSTR(b.type, 0, 10)', '=', 1];
    my $alias = $func->as_alias('fuga');
    is $alias . q{}, 'SUBSTR(fuga.type, 0, 10)', 'function with alias';

    my $func2 = $func->func('sum');
    is $func2 . q{}, 'SUM(SUBSTR(b.type, 0, 10))', 'nested function';

    my $func2_alias = $func2->as_alias('hoge');
    is $func2_alias . q{}, 'SUM(SUBSTR(hoge.type, 0, 10))';

    my $func3 = $func2->func('max');
    is $func3 . q{}, 'MAX(SUM(SUBSTR(b.type, 0, 10)))', 'nested function2';
};


{ # conc
    is $c->connc('bar'), "b.type || 'bar'";
    is $c->connc($c), 'b.type || b.type';
};

done_testing;
