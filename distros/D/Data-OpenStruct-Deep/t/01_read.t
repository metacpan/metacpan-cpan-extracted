use Test::Base;
use Test::Deep;
use Data::OpenStruct::Deep;

plan tests => 5;

my $struct = Data::OpenStruct::Deep->new({
    foo => 'foo',
    bar => {
        baz  => [qw(foo bar baz)],
        quux => {
            foobar => 'foobar',
        }
    },
});

is $struct->foo => 'foo';
cmp_deeply $struct->bar => { baz => [qw(foo bar baz)], quux => { foobar => 'foobar' } };
cmp_deeply $struct->bar->baz => [qw(foo bar baz)];
cmp_deeply $struct->bar->quux => { foobar => 'foobar' };
is $struct->bar->quux->foobar => 'foobar';
