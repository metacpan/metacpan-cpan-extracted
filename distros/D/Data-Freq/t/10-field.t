#!perl -T

use strict;
use warnings;

use Test::More tests => 12;

use Data::Freq::Field;

subtest default => sub {
    plan tests => 2;
    
    my $field = Data::Freq::Field->new();
    
    is(ref($field), 'Data::Freq::Field');
    is_deeply($field, {type => 'text', aggregate => 'count', sort => 'score', order => 'desc'});
};

subtest simple_type => sub {
    plan tests => 21;
    
    is(Data::Freq::Field->new('text'   )->type, 'text'  );
    is(Data::Freq::Field->new('texts'  )->type, 'text'  );
    is(Data::Freq::Field->new('num'    )->type, 'number');
    is(Data::Freq::Field->new('nums'   )->type, 'number');
    is(Data::Freq::Field->new('number' )->type, 'number');
    is(Data::Freq::Field->new('numbers')->type, 'number');
    
    is_deeply([map {Data::Freq::Field->new('date'   )->$_} qw(type strftime)], ['date', '%Y-%m-%d'         ]);
    is_deeply([map {Data::Freq::Field->new('dates'  )->$_} qw(type strftime)], ['date', '%Y-%m-%d'         ]);
    is_deeply([map {Data::Freq::Field->new('time'   )->$_} qw(type strftime)], ['date', '%Y-%m-%d %H:%M:%S']);
    
    is_deeply([map {Data::Freq::Field->new('year'   )->$_} qw(type strftime)], ['date', '%Y'               ]);
    is_deeply([map {Data::Freq::Field->new('years'  )->$_} qw(type strftime)], ['date', '%Y'               ]);
    is_deeply([map {Data::Freq::Field->new('month'  )->$_} qw(type strftime)], ['date', '%Y-%m'            ]);
    is_deeply([map {Data::Freq::Field->new('months' )->$_} qw(type strftime)], ['date', '%Y-%m'            ]);
    is_deeply([map {Data::Freq::Field->new('day'    )->$_} qw(type strftime)], ['date', '%Y-%m-%d'         ]);
    is_deeply([map {Data::Freq::Field->new('days'   )->$_} qw(type strftime)], ['date', '%Y-%m-%d'         ]);
    is_deeply([map {Data::Freq::Field->new('hour'   )->$_} qw(type strftime)], ['date', '%Y-%m-%d %H'      ]);
    is_deeply([map {Data::Freq::Field->new('hours'  )->$_} qw(type strftime)], ['date', '%Y-%m-%d %H'      ]);
    is_deeply([map {Data::Freq::Field->new('minute' )->$_} qw(type strftime)], ['date', '%Y-%m-%d %H:%M'   ]);
    is_deeply([map {Data::Freq::Field->new('minutes')->$_} qw(type strftime)], ['date', '%Y-%m-%d %H:%M'   ]);
    is_deeply([map {Data::Freq::Field->new('second' )->$_} qw(type strftime)], ['date', '%Y-%m-%d %H:%M:%S']);
    is_deeply([map {Data::Freq::Field->new('seconds')->$_} qw(type strftime)], ['date', '%Y-%m-%d %H:%M:%S']);
};

subtest simple_aggregate => sub {
    plan tests => 10;
    
    is(Data::Freq::Field->new('uniq'   )->aggregate, 'unique');
    is(Data::Freq::Field->new('unique' )->aggregate, 'unique');
    is(Data::Freq::Field->new('max'    )->aggregate, 'max');
    is(Data::Freq::Field->new('maximum')->aggregate, 'max');
    is(Data::Freq::Field->new('min'    )->aggregate, 'min');
    is(Data::Freq::Field->new('minimum')->aggregate, 'min');
    is(Data::Freq::Field->new('av'     )->aggregate, 'average');
    is(Data::Freq::Field->new('ave'    )->aggregate, 'average');
    is(Data::Freq::Field->new('avg'    )->aggregate, 'average');
    is(Data::Freq::Field->new('average')->aggregate, 'average');
};

subtest simple_sort => sub {
    plan tests => 6;
    
    is(Data::Freq::Field->new('count')->sort, 'count');
    is(Data::Freq::Field->new('value')->sort, 'value');
    is(Data::Freq::Field->new('first')->sort, 'first');
    is(Data::Freq::Field->new('last' )->sort, 'last');
    
    is(Data::Freq::Field->new('occur'     )->sort, 'first');
    is(Data::Freq::Field->new('occurrence')->sort, 'first');
};

subtest simple_order => sub {
    plan tests => 4;
    
    is(Data::Freq::Field->new('asc'       )->order, 'asc');
    is(Data::Freq::Field->new('ascending' )->order, 'asc');
    is(Data::Freq::Field->new('desc'      )->order, 'desc');
    is(Data::Freq::Field->new('descending')->order, 'desc');
};

subtest simple_pos => sub {
    plan tests => 7;
    
    is_deeply(Data::Freq::Field->new(  0)->pos, [0]);
    is_deeply(Data::Freq::Field->new(  1)->pos, [1]);
    is_deeply(Data::Freq::Field->new(  2)->pos, [2]);
    is_deeply(Data::Freq::Field->new( 10)->pos, [10]);
    
    is_deeply(Data::Freq::Field->new( -1)->pos, [-1]);
    is_deeply(Data::Freq::Field->new( -2)->pos, [-2]);
    is_deeply(Data::Freq::Field->new(-10)->pos, [-10]);
};

subtest hash_1 => sub {
    plan tests => 21;
    
    is(Data::Freq::Field->new({type => 'text'  })->type, 'text');
    is(Data::Freq::Field->new({type => 'number'})->type, 'number');
    is(Data::Freq::Field->new({type => 'date'  })->type, 'date');
    is_deeply([map {Data::Freq::Field->new({type => 'month' })->{$_}} qw(type strftime)], ['date', '%Y-%m']);
    
    is_deeply(Data::Freq::Field->new({pos => 0})->pos, [0]);
    is_deeply(Data::Freq::Field->new({pos => 1})->pos, [1]);
    is_deeply(Data::Freq::Field->new({key => 'foo'})->key, ['foo']);
    
    is(Data::Freq::Field->new({aggregate => 'unique' })->aggregate, 'unique');
    is(Data::Freq::Field->new({aggregate => 'max' })->aggregate, 'max');
    is(Data::Freq::Field->new({aggregate => 'min' })->aggregate, 'min');
    is(Data::Freq::Field->new({aggregate => 'average' })->aggregate, 'average');
    
    is(Data::Freq::Field->new({sort => 'count' })->sort, 'count');
    is(Data::Freq::Field->new({sort => 'value' })->sort, 'value');
    is(Data::Freq::Field->new({sort => 'first' })->sort, 'first');
    is(Data::Freq::Field->new({sort => 'last'  })->sort, 'last');
    
    is(Data::Freq::Field->new({offset =>  0})->offset,  0);
    is(Data::Freq::Field->new({offset =>  1})->offset,  1);
    is(Data::Freq::Field->new({offset => -1})->offset, -1);
    
    is(Data::Freq::Field->new({limit =>  0})->limit,  0);
    is(Data::Freq::Field->new({limit =>  1})->limit,  1);
    is(Data::Freq::Field->new({limit => -1})->limit, -1);
};

subtest hash_2 => sub {
    plan tests => 14;
    
    is_deeply([map {Data::Freq::Field->new({type => 'text'  , sort => 'count'})->$_} qw(type sort)], ['text', 'count']);
    is_deeply([map {Data::Freq::Field->new({type => 'number', sort => 'value'})->$_} qw(type sort)], ['number', 'value']);
    is_deeply([map {Data::Freq::Field->new({type => 'date'  , sort => 'first'})->$_} qw(type sort)], ['date', 'first']);
    
    is_deeply([map {Data::Freq::Field->new({sort => 'count', order => 'asc' })->$_} qw(sort order)], ['count', 'asc']);
    is_deeply([map {Data::Freq::Field->new({sort => 'value', order => 'desc'})->$_} qw(sort order)], ['value', 'desc']);
    is_deeply([map {Data::Freq::Field->new({sort => 'first', order => 'asc' })->$_} qw(sort order)], ['first', 'asc']);
    is_deeply([map {Data::Freq::Field->new({sort => 'last' , order => 'desc'})->$_} qw(sort order)], ['last', 'desc']);
    
    is_deeply([map {Data::Freq::Field->new({type => 'year' , pos =>   2  })->$_} qw(type pos)], ['date', [2]]);
    is_deeply([map {Data::Freq::Field->new({sort => 'first', key => 'bar'})->$_} qw(sort key)], ['first', ['bar']]);
    is_deeply([map {Data::Freq::Field->new({pos  =>    3   , key => 'baz'})->$_} qw(pos key)], [[3], ['baz']]);
    is_deeply([map {Data::Freq::Field->new({pos  => [0..3] , key => [qw(a b c)]})->$_} qw(pos key)], [[0, 1, 2, 3], ['a', 'b', 'c']]);
    
    is_deeply([map {Data::Freq::Field->new({offset =>  0, limit =>  1})->$_} qw(offset limit)], [ 0,  1]);
    is_deeply([map {Data::Freq::Field->new({offset =>  1, limit => -1})->$_} qw(offset limit)], [ 1, -1]);
    is_deeply([map {Data::Freq::Field->new({offset => -1, limit =>  0})->$_} qw(offset limit)], [-1,  0]);
};

subtest array => sub {
    plan tests => 5;
    
    is_deeply([map {Data::Freq::Field->new(['text', 'value', 'desc'])->$_} qw(type sort order)], ['text', 'value', 'desc']);
    is_deeply([map {Data::Freq::Field->new(['month', 'count', 'asc'])->$_} qw(type strftime sort order)], ['date', '%Y-%m', 'count', 'asc']);
    
    is_deeply([map {Data::Freq::Field->new([1, 0, 3])->$_} qw(pos)], [[1, 0, 3]]);
    is_deeply([map {Data::Freq::Field->new([1, 0, [3, 2]])->$_} qw(pos)], [[1, 0, 3, 2]]);
    is_deeply([map {Data::Freq::Field->new(['number', 1, 0, [3, 2]])->$_} qw(type pos)], ['number', [1, 0, 3, 2]]);
};

subtest default_type => sub {
    plan tests => 4;
    
    is(Data::Freq::Field->new()->type, 'text');
    is_deeply([map {Data::Freq::Field->new('date')->$_} qw(type strftime)], ['date', '%Y-%m-%d']);
    is_deeply([map {Data::Freq::Field->new('%H')->$_} qw(type strftime)], ['date', '%H']);
    is_deeply([map {Data::Freq::Field->new(['count', 'asc', [1..3]])->$_} qw(type sort order pos)], ['text', 'count', 'asc', [1, 2, 3]]);
};

subtest default_aggregate => sub {
    plan tests => 4;
    
    is(Data::Freq::Field->new()->aggregate, 'count');
    is(Data::Freq::Field->new('number')->aggregate, 'count');
    is(Data::Freq::Field->new('date')->aggregate, 'count');
    is(Data::Freq::Field->new({sort => 'value'})->aggregate, 'count');
};

subtest default_sort => sub {
    plan tests => 25;
    
    is_deeply([map {Data::Freq::Field->new()->$_} qw(type sort order)], ['text', 'score', 'desc']);
    
    is_deeply([map {Data::Freq::Field->new('text'  )->$_} qw(type sort order)], ['text'  , 'score', 'desc']);
    is_deeply([map {Data::Freq::Field->new('number')->$_} qw(type sort order)], ['number', 'value', 'asc' ]);
    is_deeply([map {Data::Freq::Field->new('date'  )->$_} qw(type sort order)], ['date'  , 'value', 'asc' ]);
    
    is_deeply([map {Data::Freq::Field->new(['text', 'value'])->$_} qw(type sort order)], ['text', 'value', 'asc' ]);
    is_deeply([map {Data::Freq::Field->new(['text', 'count'])->$_} qw(type sort order)], ['text', 'count', 'desc']);
    is_deeply([map {Data::Freq::Field->new(['text', 'score'])->$_} qw(type sort order)], ['text', 'score', 'desc']);
    is_deeply([map {Data::Freq::Field->new(['text', 'first'])->$_} qw(type sort order)], ['text', 'first', 'asc' ]);
    is_deeply([map {Data::Freq::Field->new(['text', 'last' ])->$_} qw(type sort order)], ['text', 'last' , 'desc']);
    
    is_deeply([map {Data::Freq::Field->new(['text', 'asc'  ])->$_} qw(type sort order)], ['text', 'score', 'asc' ]);
    is_deeply([map {Data::Freq::Field->new(['text', 'desc' ])->$_} qw(type sort order)], ['text', 'score', 'desc']);
    
    is_deeply([map {Data::Freq::Field->new(['number', 'value'])->$_} qw(type sort order)], ['number', 'value', 'asc' ]);
    is_deeply([map {Data::Freq::Field->new(['number', 'count'])->$_} qw(type sort order)], ['number', 'count', 'desc']);
    is_deeply([map {Data::Freq::Field->new(['number', 'score'])->$_} qw(type sort order)], ['number', 'score', 'desc']);
    is_deeply([map {Data::Freq::Field->new(['number', 'first'])->$_} qw(type sort order)], ['number', 'first', 'asc' ]);
    is_deeply([map {Data::Freq::Field->new(['number', 'last' ])->$_} qw(type sort order)], ['number', 'last' , 'desc']);
    
    is_deeply([map {Data::Freq::Field->new(['number', 'asc'  ])->$_} qw(type sort order)], ['number', 'value', 'asc' ]);
    is_deeply([map {Data::Freq::Field->new(['number', 'desc' ])->$_} qw(type sort order)], ['number', 'value', 'desc']);
    
    is_deeply([map {Data::Freq::Field->new(['date', 'value'])->$_} qw(type sort order)], ['date', 'value', 'asc' ]);
    is_deeply([map {Data::Freq::Field->new(['date', 'count'])->$_} qw(type sort order)], ['date', 'count', 'desc']);
    is_deeply([map {Data::Freq::Field->new(['date', 'score'])->$_} qw(type sort order)], ['date', 'score', 'desc']);
    is_deeply([map {Data::Freq::Field->new(['date', 'first'])->$_} qw(type sort order)], ['date', 'first', 'asc' ]);
    is_deeply([map {Data::Freq::Field->new(['date', 'last' ])->$_} qw(type sort order)], ['date', 'last' , 'desc']);
    
    is_deeply([map {Data::Freq::Field->new(['date', 'asc'  ])->$_} qw(type sort order)], ['date', 'value', 'asc' ]);
    is_deeply([map {Data::Freq::Field->new(['date', 'desc' ])->$_} qw(type sort order)], ['date', 'value', 'desc']);
};
