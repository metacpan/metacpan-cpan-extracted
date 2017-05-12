use strict;
use warnings;
use parent 'Blosxom::Plugin';
use Test::More tests => 13;

__PACKAGE__->mk_accessors({
    foo => undef,
    bar => q{},
    baz => 'qux',
    qux => sub { $_[0] },
});

my $plugin = __PACKAGE__;

can_ok $plugin, qw( foo bar baz qux );

is_deeply $plugin->dump, {};

# get
is $plugin->foo, undef;
is $plugin->bar, q{};
is $plugin->baz, 'qux';
is $plugin->qux, $plugin;

is_deeply $plugin->dump, {
    bar => q{},
    baz => 'qux',
    qux => $plugin,
};

# set
is $plugin->foo('bar'), 'bar';
is $plugin->bar('baz'), 'baz';
is $plugin->baz('qux'), 'qux';
is $plugin->qux('foo'), 'foo';

is_deeply $plugin->dump, {
    foo => 'bar',
    bar => 'baz',
    baz => 'qux',
    qux => 'foo',
};

$plugin->end;
is_deeply $plugin->dump, {};

sub dump { my $VAR1; eval $_[0]->SUPER::dump }
