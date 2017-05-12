#!perl -w
use strict;
use Test::More tests => 33;
use Test::Exception;

use Data::Util qw(is_instance instance);

BEGIN{
	package Foo;
	sub new{ bless {}, shift }

	package Bar;
	our @ISA = qw(Foo);

	package Foo_or_Bar;
	our @ISA = qw(Foo);

	package Baz;
	sub new{ bless {}, shift }
	sub isa{
		my($x, $y) = @_;
		return $y eq 'Foo';
	}

	package Broken;
	sub isa; # pre-declaration only

	package AL;
	sub new{ bless {}, shift }
	sub DESTROY{}
	sub isa;

	sub AUTOLOAD{
		#our $AUTOLOAD; ::diag "$AUTOLOAD(@_)";
		1;
	}

	package AL_stubonly;

	sub new{ bless{}, shift; }
	sub DESTROY{};
	sub isa;

	sub AUTOLOAD;

}

ok  is_instance(Foo->new, 'Foo'), 'is_instance';
ok !is_instance(Foo->new, 'Bar');
ok  is_instance(Foo->new, 'UNIVERSAL'), 'is_instance of UNIVERSAL';

ok  is_instance(Bar->new, 'Foo');
ok  is_instance(Bar->new, 'Bar');

ok  is_instance(Baz->new, 'Foo');
ok !is_instance(Baz->new, 'Bar');
ok !is_instance(Baz->new, 'Baz');

ok is_instance(Foo_or_Bar->new, 'Foo');
ok!is_instance(Foo_or_Bar->new, 'Bar');
@Foo_or_Bar::ISA = qw(Bar);
ok is_instance(Foo_or_Bar->new, 'Bar'), 'ISA changed dynamically';


# no object reference

ok !is_instance('Foo', 'Foo');
ok !is_instance({},    'Foo');

ok !is_instance({}, 'HASH');

dies_ok{ is_instance(Broken->new(), 'Broken')  };

ok is_instance(AL->new, 'AL');
ok is_instance(AL->new, 'Foo');

dies_ok { is_instance(AL_stubonly->new, 'AL') };

isa_ok instance(Foo->new, 'Foo'), 'Foo', 'instance';
isa_ok instance(Bar->new, 'Foo'), 'Foo';

dies_ok{ instance(undef, 'Foo') };
dies_ok{ instance(1, 'Foo')     };
dies_ok{ instance('', 'Foo')    };
dies_ok{ instance({}, 'Foo')    };
dies_ok{ instance(Foo->new, 'Bar') };


# error
dies_ok{ is_instance('Foo', Foo->new()) } 'illigal argument order';
dies_ok{ is_instance([], [])            } 'illigal use';
dies_ok{ is_instance()                  } 'not enough argument';
dies_ok{ is_instance([], undef)         } 'uninitialized class';

dies_ok{ instance('Foo', Foo->new())    } 'illigal argument order';
dies_ok{ instance([], [])               } 'illigal use';
dies_ok{ instance()                     } 'not enough argument';
dies_ok{ instance([], undef)            } 'uninitialized class';
