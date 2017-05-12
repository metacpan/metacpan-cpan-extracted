#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 65;
use Test::Exception;

use ok 'Class::MethodCache' => qw(:all);

{
	package Foo;

	sub foo { "Foo::foo" }

	package Bar;

	use vars qw(@ISA);
	@ISA = qw(Foo);

	sub bar { "Bar::bar" }

	package Gorch;

	sub gorch { "Gorch::gorch" }
}

is( get_cached_method(*Bar::bar), undef, "no cached method Bar::bar" );
is( get_cached_method(*Bar::foo), undef, "no cached method Bar::foo" );
is( get_cached_method(*Bar::gorch), undef, "no cached method Bar::gorch" );
is( get_cv(*Bar::bar), \&Bar::bar, "cv Bar::bar" );
is( get_cv(*Bar::foo), undef, "no cv Bar::foo" );
is( get_cv(*Bar::gorch), undef, "no cv Bar::gorch" );

is( Bar->bar, "Bar::bar", "Bar->bar" );
is( Bar->foo, "Foo::foo", "Bar->foo" );
is( eval { Bar->gorch }, undef, "Bar->gorch" );

is( get_cached_method(*Bar::foo), \&Foo::foo, "cached method Bar::foo" );
is( get_cached_method(*Bar::bar), undef, "no cached method Bar::bar" );
is( get_cached_method(*Bar::gorch), undef, "no cached method Bar::gorch" );
is( get_cv(*Bar::bar), \&Bar::bar, "cv Bar::bar" );
is( get_cv("Bar::bar"), \&Bar::bar, "cv Bar::bar (fq)" );
is( get_cv(*Bar::foo), \&Foo::foo, "cv Bar::foo" );
is( get_cv(*Bar::gorch), undef, "no cv Bar::gorch" );


push @Bar::ISA, "Gorch";

is( get_cached_method(*Bar::foo), undef, "no cached method Bar::foo" );
is( get_cached_method(*Bar::bar), undef, "no cached method Bar::bar" );
is( get_cached_method(*Bar::gorch), undef, "no cached method Bar::gorch" );
is( get_cv(*Bar::bar), \&Bar::bar, "cv Bar::bar" );
is( get_cv(*Bar::foo), \&Foo::foo, "cv Bar::foo" );
is( get_cv(*Bar::gorch), undef, "no cv Bar::gorch" );

cmp_ok( get_cvgen(*Bar::foo), "<", get_class_gen("Bar"), "cvgen less than class gen" );

update_cvgen(*Bar::foo);

is( get_cvgen(*Bar::foo), get_class_gen("Bar"), "cvgen now equals class gen" );

is( get_cached_method(*Bar::foo), \&Foo::foo, "cached method Bar::foo" );
is( get_cached_method(*Bar::bar), undef, "no cached method Bar::bar" );
is( get_cached_method(*Bar::gorch), undef, "no cached method Bar::gorch" );
is( get_cv(*Bar::bar), \&Bar::bar, "cv Bar::bar" );
is( get_cv(*Bar::foo), \&Foo::foo, "cv Bar::foo" );
is( get_cv(*Bar::gorch), undef, "no cv Bar::gorch" );

is( Bar->bar, "Bar::bar", "Bar->bar" );
is( Bar->foo, "Foo::foo", "Bar->foo" );
is( Bar->gorch, "Gorch::gorch", "Bar->gorch" );

is( get_cached_method(*Bar::foo), \&Foo::foo, "cached method Bar::foo" );
is( get_cached_method(*Bar::bar), undef, "no cached method Bar::bar" );
is( get_cached_method(*Bar::gorch), \&Gorch::gorch, "cached method Gorch::gorch" );
is( get_cv(*Bar::bar), \&Bar::bar, "cv Bar::bar" );
is( get_cv(*Bar::foo), \&Foo::foo, "cv Bar::foo" );
is( get_cv(*Bar::gorch), \&Gorch::gorch, "cv Bar::gorch" );

set_cv(*Bar::gorch, \&Foo::foo);

is( Bar->gorch, "Foo::foo", "cache overridden" );
is( Bar->foo, "Foo::foo", "Bar->foo still works" );

@Bar::ISA = @Bar::ISA;

is( Bar->gorch, "Gorch::gorch", "cache reset" );
is( Bar->foo, "Foo::foo", "Bar->foo still works" );

is( get_gv_refcount(*Bar::gorch), 1, "Bar::gorch globref is not shared" );

my $oink = sub { "oink" };
set_cached_method(*Bar::oink, $oink);

is( eval { Bar->oink }, "oink", "create oink method" );

@Bar::ISA = @Bar::ISA;

is( get_cv(*Bar::oink), $oink, "cv Bar::oink" );

throws_ok { Bar->oink } qr/oink/, "no more oink method";

is( get_cv(*Bar::oink), undef, "cv Bar::oink" );


is( Bar->foo, "Foo::foo", "Bar->foo" );

is( get_cv(*Bar::foo), \&Foo::foo, "cv for Bar::foo" );

set_cv( *Bar::foo, undef );

is( get_cv(*Bar::foo), undef, "no cv for Bar::foo" );

is( get_cvgen(*Bar::foo), get_class_gen("Bar"), "cvgen is up to date" );

eval { Bar->foo }; # throws_ok breaks this on 5.8, incrementing PL_sub_generation (apparently it requires something?
like( $@, qr/can't locate.*foo/i, "foo method is cached as unresolved" );

@Bar::ISA = @Bar::ISA;

is( get_cv(*Bar::foo), undef, "no cv for Bar::foo" );

lives_ok { Bar->foo } "foo method works again";

is( get_cv(*Bar::foo), \&Foo::foo, "cv for Bar::foo" );

eval { Bar->new_method };
like( $@, qr/can't locate.*new_method/i, "new_method is unresolved" );

# add the entry without incrementing the cache gen
set_cv(*Foo::new_method, sub { "new_method" });

eval { Bar->new_method };
like( $@, qr/can't locate.*new_method/i, "new_method is cached as unresolved" );

{
	no warnings 'once';
	# delete the cache
	delete_cv(*Bar::new_method);
}

is( eval { Bar->new_method }, "new_method", "new_method works" );

delete_cv(*Foo::new_method);

is( eval { Bar->new_method }, "new_method", "new_method still works on bar" );

eval { Foo->new_method };
like( $@, qr/can't locate.*new_method/i, "new_method unresolved on Foo" );

@Bar::ISA = @Bar::ISA;

eval { Bar->new_method };
like( $@, qr/can't locate.*new_method/i, "new_method is unresolved on Bar" );


throws_ok { update_cvgen(*Bar::bar) } qr/real method/, "can't update cvgen of real method";

throws_ok { set_cached_method(*Bar::bar, sub { "blah" } ) } qr/real method/, "can't overwrite real method with cached method";


