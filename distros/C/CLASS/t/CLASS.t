#!/usr/bin/perl -w

use 5.004;

use Test::More tests => 22;

BEGIN { use_ok('CLASS'); }


package Foo;
use CLASS;

::is( CLASS,  __PACKAGE__,              'CLASS is right' );
::is( $CLASS,  __PACKAGE__,             '$CLASS is right' );


sub bar { 23 }
sub check_caller { caller }

::is( CLASS->bar, 23,              'CLASS->meth' );
::is( $CLASS->bar, 23,             '$CLASS->meth' );

#line 42
eval { CLASS->i_dont_exist };
my $CLASS_death = $@;
#line 42
eval { $CLASS->i_dont_exist };
my $CLASS_scalar_death = $@;
#line 42
eval { __PACKAGE__->i_dont_exist };
my $Foo_death = $@;
::is( $CLASS_death, $Foo_death,   '__PACKAGE__ and CLASS die the same' );
::is( $CLASS_scalar_death, $Foo_death, '__PACKAGE__ and $CLASS die the same' );

#line 29
my $CLASS_caller = CLASS->check_caller;
my $CLASS_scalar_caller = $CLASS->check_caller;
my $Foo_caller   = __PACKAGE__->check_caller;
::is($CLASS_caller, $Foo_caller,  'caller preserved' );
::is($CLASS_scalar_caller, $Foo_caller,  'caller preserved' );


sub foo { return join ':', @_ }

::is( CLASS->foo,         'Foo',        'Right CLASS  to class method call' );
::is( $CLASS->foo,         'Foo',       'Right $CLASS to class method call' );
::is( CLASS->foo('bar'),  'Foo:bar',    'CLASS:  Arguments preserved' );
::is( $CLASS->foo('bar'),  'Foo:bar',   '$CLASS: Arguments preserved' );


{
    package Bar;
    use CLASS;

    sub Yarrow::Func {
        my($passed_class, $passed_class_scalar) = @_;
        ::is( CLASS, __PACKAGE__,    'CLASS works in tricky subroutine' );
        ::is( $CLASS, __PACKAGE__,   '$CLASS works in tricky subroutine' );

        ::is( $passed_class,        'Foo', 'CLASS as sub argument'  );
        ::is( $passed_class_scalar, 'Foo', '$CLASS as sub argument' );

        ::is( $_[0], 'Foo', 'CLASS in @_'  );
        ::is( $_[1], 'Foo', '$CLASS in @_' );
    }
}

Yarrow::Func(CLASS, $CLASS);


# Make sure AUTOLOAD is preserved.
package Bar;
sub AUTOLOAD { return "Autoloader" }

::is( CLASS->i_dont_exist, 'Autoloader',        'CLASS:  AUTOLOAD preserved' );
::is( $CLASS->i_dont_exist, 'Autoloader',       '$CLASS: AUTOLOAD preserved' );


package main;
eval q{ CLASS(42); };
like( $@, '/^Too many arguments for main::CLASS/', 
                                                'CLASS properly prototyped' );
