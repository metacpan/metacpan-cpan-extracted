use Test::More tests => 4;
use Attribute::Static;

package Foo;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub bar : Static {
    my $class = shift;
}

sub baz {
    my $self = shift;
}

package main;

# OK
eval { Foo->bar };
is($@, '', 'call static');
# OK
eval { Foo->bar };
is($@, '', 'call static');

my $foo = Foo->new;

# NG
eval { $foo->bar };
like($@, qr/static/, 'call not static');
# OK
eval { $foo->baz };
is($@, '', 'call not static');
