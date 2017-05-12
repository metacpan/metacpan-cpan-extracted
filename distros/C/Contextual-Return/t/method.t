use Contextual::Return;
use Test::More 'no_plan';
use strict;

sub foo_with_default_method {
    return
        METHOD {
            bar           => sub { 'bar method called'     },
            qr/ba(.)/     => sub { $1 . ' method called'   },
            ['qux','dux'] => sub { "$_ method called"      },
            qr/.*/        => sub { 'DEFAULT method called' },
        }
        DEFAULT { 'DEFAULT value' }
}

is foo_with_default_method()->bar, 'bar method called',     'bar method';
is foo_with_default_method()->baz, 'z method called',       'baz method';
is foo_with_default_method()->qux, 'qux method called',     'qux method';
is foo_with_default_method()->dux, 'dux method called',     'dux method';
is foo_with_default_method()->jax, 'DEFAULT method called', 'DEFAULT method';
is foo_with_default_method()     , 'DEFAULT value',         'DEFAULT';


sub foo_with_method_and_obj {
    return
        METHOD {
            bar => sub { 'bar method called' },
        }
        OBJREF {
            bless {}, 'Bar';
        }
        DEFAULT { 'DEFAULT value' }
}

is foo_with_method_and_obj()->bar, 'bar method called',     'bar method called';
is foo_with_method_and_obj()->baz, 'Bar::baz',              'OBJREF method called';
is foo_with_method_and_obj()     , 'DEFAULT value',         'DEFAULT value';




package Bar;

sub baz { "Bar::baz" }
