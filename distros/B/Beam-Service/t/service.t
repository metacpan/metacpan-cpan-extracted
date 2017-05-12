
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{ package
    My::Object;
    use Moo;
    with 'Beam::Service';
}
{ package
    Beam::Wire; # Fake Beam::Wire object
    use Moo;
}

my $obj;
ok !(exception { $obj = My::Object->new( name => 'foo', container => Beam::Wire->new ) }),
    'Beam::Service accepts name and container attributes';
is $obj->name, 'foo', 'name is correct';
is ref $obj->container, 'Beam::Wire', 'container is correct';

ok !(exception { $obj = My::Object->new }),
    'Beam::Service object can be created without name or container';

ok exception { My::Object->new( container => 'foo' ) },
    'Beam::Service container attribute must be Beam::Wire object';

ok exception { My::Object->new( name => Beam::Wire->new ) },
    'Beam::Service name attribute must be string';

done_testing;

