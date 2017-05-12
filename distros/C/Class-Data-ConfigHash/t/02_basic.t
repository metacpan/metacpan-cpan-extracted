package MyClass;
use strict;
use base qw(Class::Data::ConfigHash);
__PACKAGE__->config( foo => 1, bar => 2);

package MySubClass;
use base qw(MyClass);

package main;

use strict;
use Test::More (tests => 9);

{ # Basic access
    is(MyClass->config->{foo}, 1);
    is(MyClass->config->{bar}, 2);

    MyClass->config(foo => 3);
    is(MyClass->config->{foo}, 3);

    MyClass->config->{bar} = 4;
    is(MyClass->config->{bar}, 4);
}

{ # Feed a hashref instead of a hash
    MyClass->config({ foo => 5, bar => 6 });
    is(MyClass->config->{foo}, 5);
    is(MyClass->config->{bar}, 6);
}

{ # Inheritance at work
    is( MySubClass->config->{foo}, 5 );
}

{ # What if you gave a null config
    my $config = MyClass->config;
    MyClass->config(undef);

    is_deeply( $config, MyClass->config );
}

{ # Complex
    MyClass->config( foo => { baz => 1 } );
    is_deeply( MyClass->config->{foo}, { baz => 1 });
}
