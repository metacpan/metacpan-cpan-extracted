use strict;
use warnings;
use Test::More;

{
    package MyApp::Context;
    use Context::Micro;

    sub foo {
        my $self = shift;
        $self->entry( 'foo' => sub {
            my $conf = $self->config->{foo};
            bless +{ conf => $conf, time => time() }, 'MyApp::Foo';
        } );
    }

    sub bar {
        my $self = shift;
        $self->entry( 'bar' => sub {
            my $conf = $self->config->{bar};
            bless +{ conf => $conf, time => time() }, 'MyApp::Bar';
        } );
    }

    sub hoge {
        my $self = shift;
        bless +{ conf => $self->config->{hoge}, time => time() }, 'MyApp::Hoge';
    }
};

my $config = +{
    foo => { a => 1 },
    bar => [ 'a', 'b', 'c' ],
    hoge => 'foobar',
};

my $c = MyApp::Context->new(config => $config);

isa_ok $c, 'MyApp::Context';
can_ok $c, qw/ foo bar hoge /;

is_deeply $c->{container}, {}, 'container is empty';

my $foo = $c->foo;
isa_ok $foo, 'MyApp::Foo';

is_deeply $c->{container}, { foo => $foo }, 'container contains foo only';

sleep 2;

my $foo2 = $c->foo;
is $foo, $foo2, '$foo and $foo2 is same object';
is_deeply $c->{container}, { foo => $foo }, 'container contains foo only too';

my $bar = $c->bar;
isa_ok $bar, 'MyApp::Bar';
isnt $foo, $bar, '$foo and $bar are not the same';
is_deeply $c->{container}, { foo => $foo, bar => $bar }, 'container contains foo and bar';

my $hoge = $c->hoge;
isa_ok $hoge, 'MyApp::Hoge';
isnt $foo, $hoge, '$foo and $hoge are not the same';
isnt $bar, $hoge, '$bar and $hoge are not the same too';
is_deeply $c->{container}, { foo => $foo, bar => $bar }, 'hoge is not exists in container';

sleep 2;

my $bar2 = $c->bar;
is $bar, $bar2, '$bar and $bar2 is same object';
my $hoge2 = $c->hoge;
isnt $hoge, $hoge2, '$hoge and $hoge2 are not the same';
is_deeply $c->{container}, { foo => $foo, bar => $bar }, 'hoge is not exists in container too';

done_testing;
