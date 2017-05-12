[![Build Status](https://travis-ci.org/xaicron/p5-Data-WeightedRoundRobin.svg?branch=master)](https://travis-ci.org/xaicron/p5-Data-WeightedRoundRobin)
# NAME

Data::WeightedRoundRobin - Serve data in a Weighted RoundRobin manner.

# SYNOPSIS

    use Data::WeightedRoundRobin;
    my $dwr = Data::WeightedRoundRobin->new([
        qw/foo bar/,
        { value => 'baz', weight => 50 },
        { key => 'hoge', value => [qw/fuga piyo/], weight => 120 },
    ]);
    $dwr->next; # 'foo' : 'bar' : 'baz' : [qw/fuga piyo/] = 100 : 100 : 50 : 120

# DESCRIPTION

Data::WeightedRoundRobin is a Serve data in a Weighted RoundRobin manner.

# METHODS

- `new([$list:ARRAYREF, $option:HASHREF])`

    Creates a Data::WeightedRoundRobin instance.

        $dwr = Data::WeightedRoundRobin->new();               # empty rr data
        $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);  # foo : bar = 100 : 100

        # foo : bar : baz : qux = 100 : 100 : 120 : 50 :
        $dwr = Data::WeightedRoundRobin->new([
            'foo',
            { value => 'bar' },
            { value => 'baz', weight => 120 },
            { key => 'qux', value => [qw/q u x/], weight => 50 },
            \{ foo => 'bar' },
        ]);

    Sets default\_weight option, DEFAULT is **$Data::WeightedRoundRobin::DEFAULT\_WEIGHT**.

        # foo : bar : baz = 0.3 : 0.7 : 1
        $dwr = Data::WeightedRoundRobin->new([
            { value => 'foo', weight => 0.3 },
            { value => 'bar', weight => 0.7 },
            { value => 'baz' },
        ], { default_weight => 1 });

- `next()`

    Fetch a data.

         my $dwr = Data::WeightedRoundRobin->new([
             qw/foo bar/],
             { value => 'baz', weight => 50 },
         );
         
         # Infinite loop
         while (my $data = $dwr->next) {
             say $data; # foo : bar : baz = 100 : 100 : 50 
         }
        

- `set($list:ARRAYREF)`

    Sets datum.

        $drw->set([
            { value => 'foo', weight => 100 },
            { value => 'bar', weight => 50  },
        ]);

    You can specify the following data.

        [qw/foo/]                           # eq [ { key => 'foo', value => 'foo', weight => 100 } ]
        [{ value => 'foo' }]                # eq [ { key => 'foo', value => 'foo', weight => 100 } ]
        [{ key => 'foo', value => 'foo' }]  # eq [ { key => 'foo', value => 'foo', weight => 100 } ] 

- `add($value:SCALAR || $value:HASHREF)`

    Add a value. You can add NOT already value. Returned value is 1 or 0, but if error is undef.

        use Test::More;
        my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
        is $dwr->add('baz'), 1, 'added baz';
        is $dwr->add('foo'), 0, 'foo is exists';
        is $dwr->add({ value => 'hoge', weight => 80 }), 1, 'added hoge with weight 80';
        is $dwr->add(), undef, 'error';

- `replace($value:SCALAR || $value::HASHREF)`

    Replace a value. Returned value is 1 or 0, but if error is undef.

        use Test::More;
        my $dwr = Data::WeightedRoundRobin->new([qw/foo/, { value => 'bar', weight => 50 }]);
        is $dwr->replace('bar'), 1, 'replaced bar to default weight (50 -> 100)';
        is $dwr->replace('hoge'), 0, 'hoge is not found';
        is $dwr->replace({ value => 'foo', weight => 80 }), 1, 'replaced foo with weight 80';
        is $dwr->replace(), undef, 'error';

- `remove($value:SCALAR)`

    Remove a value. Returned value is 1 or 0, but if error is undef.

        use Test::More;
        my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
        is $dwr->remove('foo'), 1, 'removed foo';
        is $dwr->remove('hoge'), 0, 'hoge is not found';
        is $dwr->remove(), undef, 'error';

- `save()`

    When destroyed `$guard` is gone, will return to the saved state.

        my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
        {
            my $guard = $drw->save;
            $drw->remove('foo');
            is $drw->next, 'bar';
        }

        # return to saved state
        my $data = $dwr->next; # foo or bar

# AUTHOR

xaicron &lt;xaicron {at} cpan.org>

# COPYRIGHT

Copyright 2011 - xaicron

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
