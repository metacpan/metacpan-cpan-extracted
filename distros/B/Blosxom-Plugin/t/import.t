use strict;
use warnings;
use Test::Exception;
use Test::More tests => 9;

$INC{'MyComponent.pm'}++;

package MyComponent;
BEGIN { *imported_function = sub {} }
use Blosxom::Plugin;

__PACKAGE__->requires(qw/req1 req2/);

__PACKAGE__->mk_accessors({
    bar => 'MyComponent bar',
    baz => 'MyComponent baz',
});

sub qux {
    my $pkg = shift;
    join ' ', $pkg->req1, $pkg->req2;
}

package my_plugin;
use parent 'Blosxom::Plugin';

__PACKAGE__->mk_accessors({
    req1 => 'hello',
    req2 => 'world',
});

__PACKAGE__->load_components( '+MyComponent' );

sub foo { 'my_plugin foo' }
sub baz { 'my_plugin baz' }

package another_plugin;
use parent 'Blosxom::Plugin';

package main;

my $plugin = 'my_plugin';

can_ok $plugin, qw( foo bar baz qux );

for my $method (qw/imported_function init requires mk_accessors/) {
    ok !defined &{"$plugin\::$method"}, "$method() should be undefined";
}

is $plugin->bar, 'MyComponent bar';
is $plugin->baz, 'my_plugin baz';
is $plugin->qux, 'hello world';

throws_ok { another_plugin->load_components('+MyComponent') }
    qr/^Can't apply 'MyComponent' to 'another_plugin'/;
