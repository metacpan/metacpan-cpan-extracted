use strict;
use Test::More tests => 8;

BEGIN { use_ok('Attribute::Protected') }

package SomeClass;

sub foo :Private   { }
sub bar :Protected { }
sub baz :Public    { }

sub call_foo {
    my $self = shift;
    $self->foo;
}

sub call_bar {
    my $self = shift;
    $self->bar;
}

package DerivedClass;
@DerivedClass::ISA = qw(SomeClass);

sub call_foo_direct {
    my $self = shift;
    $self->foo;
}

sub call_bar_direct {
    my $self = shift;
    $self->bar;
}

package main;

my $some = bless {}, 'SomeClass';

# NG: private
eval { $some->foo };
like($@, qr/private/, 'call private from outside');

# NG: protected
eval { $some->bar };
like($@, qr/protected/, 'call protected from outside');

# OK: public
eval { $some->baz };
is($@, '', 'call public');

# OK: private
eval { $some->call_foo };
is($@, '', 'call private from inside');

# OK: protected
eval { $some->call_bar };
is($@, '', 'call protected from inside');

my $derived = bless {}, 'DerivedClass';

# NG: private
eval { $derived->call_foo_direct };
like($@, qr/private/, 'call private from derived');

# OK: protected
eval { $derived->call_bar_direct };
is($@, '', 'call protected from derived');

