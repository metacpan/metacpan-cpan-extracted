#!/usr/bin/perl

##############################################################################
# Set up the tests.
##############################################################################

use strict;
use Test::More tests => 109;
use File::Spec;

##############################################################################
# Create a simple class.
##############################################################################

package Class::Meta::TestPerson;
use strict;

# Make sure we can load Class::Meta.
BEGIN { main::use_ok( 'Class::Meta' ) }

BEGIN {
    # Import Test::More functions into this package.
    Test::More->import;

    # Create a new Class::Meta object.
    ok( my $c = Class::Meta->new(key     => 'person',
                                 package => __PACKAGE__),
        "Create CM object" );

    isa_ok($c, 'Class::Meta');

    # Create a new method with all of the parameters set.
    sub foo_meth { 'foo' }
    ok( my $meth = $c->add_method(
        name    => 'foo_meth',
        desc    => 'The foo method',
        label   => 'Foo method',
        context => Class::Meta::CLASS,
        view    => Class::Meta::PUBLIC
    ), 'Create foo_meth' );

    isa_ok($meth, 'Class::Meta::Method');

    # Test its accessors.
    is( $meth->name, "foo_meth", "Check foo_meth name" );
    is( $meth->desc, "The foo method", "Check foo_meth desc" );
    is( $meth->label, "Foo method", "Check foo_meth label" );
    ok( $meth->view == Class::Meta::PUBLIC, "Check foo_meth view" );
    ok( $meth->context == Class::Meta::CLASS, "Check foo_meth context" );
    is ($meth->call(__PACKAGE__), 'foo', 'Call the foo_meth method' );

    # Okay, now test to make sure that an attempt to create a method directly
    # fails.
    eval { my $meth = Class::Meta::Method->new };
    ok( my $err = $@, "Get method construction exception");
    like( $err, qr/Package 'Class::Meta::TestPerson' cannot create/,
        "Caught proper exception");

    # Now try it without a name.
    eval{ $c->add_method() };
    ok( $err = $@, "Caught no name exception");
    like( $err, qr/Parameter 'name' is required in call to new/,
        "Caught proper no name exception");

    # Try a duplicately-named method.
    eval{ $c->add_method(name => 'foo_meth') };
    ok( $err = $@, "Caught dupe name exception");
    like( $err, qr/Method 'foo_meth' already exists in class/,
        "Caught proper dupe name exception");

    # Try a of bogus visibility.
    eval { $c->add_method( name => 'new_meth',
                         view  => 10) };
    ok( $err = $@, "Caught another bogus view exception");
    like( $err, qr/Not a valid view parameter: '10'/,
        "Caught another proper bogus view exception");

    # Try a of bogus context.
    eval { $c->add_method( name => 'new_meth',
                         context  => 10) };
    ok( $err = $@, "Caught another bogus context exception");
    like( $err, qr/Not a valid context parameter: '10'/,
        "Caught another proper bogus context exception");

    # Try a bogus caller.
    eval { $c->add_method( name => 'new_meth',
                         caller => 'foo' ) };
    ok( $err = $@, "Caught bogus caller exception");
    like( $err, qr/Parameter caller must be a code reference/,
        "Caught proper bogus caller exception");

    # Now test all of the defaults.
    sub new_meth { 22 }
    ok( $meth = $c->add_method( name => 'new_meth' ), "Create 'new_meth'" );
    isa_ok($meth, 'Class::Meta::Method');

    # Test its accessors.
    is( $meth->name, "new_meth", "Check new_meth name" );
    ok( ! defined $meth->desc, "Check new_meth desc" );
    ok( ! defined $meth->label, "Check new_meth label" );
    ok( $meth->view == Class::Meta::PUBLIC, "Check new_meth view" );
    ok( $meth->context == Class::Meta::OBJECT, "Check new_meth context" );
    is( $meth->call(__PACKAGE__), '22', 'Call the new_meth method' );

    # Now install a method.
    ok( $meth = $c->add_method(
        name => 'implicit',
        code => sub { return 'implicitly' },
    ), 'Define a method');
    isa_ok($meth, 'Class::Meta::Method');

    ok( $c->build, 'Build the class' );
    can_ok( __PACKAGE__, 'implicit' );
    is( __PACKAGE__->implicit, 'implicitly',
        'It should be the method we installed' );
    is( $meth->call(__PACKAGE__), 'implicitly',
        'and we should be able to call it indirectly' );
}

# Now try subclassing Class::Meta.

package Class::Meta::SubClass;
use base 'Class::Meta';
sub add_method {
    Class::Meta::Method->new( shift->SUPER::class, @_);
}

package Class::Meta::AnotherTest;
use strict;

BEGIN {
    # Import Test::More functions into this package.
    Test::More->import;

    # Create a new Class::Meta object.
    ok( my $c = Class::Meta::SubClass->new(
        key     => 'another',
        package => __PACKAGE__
    ), "Create subclassed CM object" );

    isa_ok($c, 'Class::Meta');
    isa_ok($c, 'Class::Meta::SubClass');
    sub foo_meth { 100 }
    ok( my $meth = $c->add_method( name => 'foo_meth'),
        'Create subclassed foo_meth' );

    isa_ok($meth, 'Class::Meta::Method');

    # Test its accessors.
    is( $meth->name, "foo_meth", "Check new foo_meth name" );
    ok( ! defined $meth->desc, "Check new foo_meth desc" );
    ok( ! defined $meth->label, "Check new foo_meth label" );
    ok( $meth->view == Class::Meta::PUBLIC, "Check new foo_meth view" );
    ok( $meth->context == Class::Meta::OBJECT, "Check new foo_meth context" );
    is( $meth->call(__PACKAGE__), '100', 'Call the new foo_meth method' );
}

##############################################################################
# Now try subclassing Class::Meta::Method.
package Class::Meta::Method::Sub;
use base 'Class::Meta::Method';

# Make sure we can override new and build.
sub new { shift->SUPER::new(@_) }
sub build { shift->SUPER::build(@_) }

sub foo { shift->{foo} }

package main;
ok( my $cm = Class::Meta->new( method_class => 'Class::Meta::Method::Sub'),
    "Create Class" );
ok( my $meth = $cm->add_method(name => 'foo', foo => 'bar'),
    "Add foo method" );
isa_ok($meth, 'Class::Meta::Method::Sub');
isa_ok($meth, 'Class::Meta::Method');
is( $meth->name, 'foo', "Check an attibute");
is( $meth->foo, 'bar', "Check added attibute");

##############################################################################
# Now try enforcing method views.
VIEW: {
    package My::View;
    use Test::More;

    BEGIN {
        ok my $cm = Class::Meta->new(
            key     => 'view',
            package => __PACKAGE__,
            trust   => 'My::Trust',
        ), 'Create CM object';

        ok $cm->add_constructor( name => 'new' ), 'Add a constructor';
        ok $cm->add_method(
            name => 'public',
            view => Class::Meta::PUBLIC,
            code => sub { },
        ), 'Add a public method';
        ok $cm->add_method(
            name => 'private',
            view => Class::Meta::PRIVATE,
            code => sub { },
        ), 'Add a private method';
        ok $cm->add_method(
            name => 'trusted',
            view => Class::Meta::TRUSTED,
            code => sub { },
        ), 'Add a trusted method';
        ok $cm->add_method(
            name => 'protected',
            view => Class::Meta::PROTECTED,
            code => sub { },
        ), 'Add a protected method';

        ok $cm->build, 'Build the class';
    };

    ok my $view = My::View->new, 'Create new private view object';
    is undef, $view->public,     'Should be able to access public';
    is undef, $view->private,    'Should be able to access private';
    is undef, $view->trusted,    'Should be able to access trusted';
    is undef, $view->protected,  'Should be able to access protected';
}

# Make sure that visibility is enforced.
ok my $view = My::View->new, 'Create new public view object';
is undef, $view->public,     'Should be able to access public';
eval { $view->private };
chk( 'private exception', qr/private is a private method of My::View/);
eval { $view->trusted };
chk( 'trusted exception', qr/trusted is a trusted method of My::View/);
eval { $view->protected };
chk( 'protected exception', qr/protected is a protected method of My::View/);

# Check visibility in an inherited class.
INHERIT: {
    package My::Viewer;
    use base 'My::View';
    use Test::More;
    ok my $view = My::View->new, 'Create new inherited view object';
    is undef, $view->public,     'Should be able to access public';
    eval { $view->private };
    main::chk( 'private exception', qr/private is a private method of My::View/);
    eval { $view->trusted };
    main::chk( 'trusted exception', qr/trusted is a trusted method of My::View/);
    is undef, $view->protected,  'Should be able to access protected';
}

# Check visibility in a trusted class.
TRUST: {
    package My::Trust;
    use Test::More;
    ok my $view = My::View->new, 'Create new trusted view object';
    is undef, $view->public,     'Should be able to access public';
    eval { $view->private };
    main::chk( 'private exception', qr/private is a private method of My::View/);
    is undef, $view->trusted,    'Should be able to access trusted';
    eval { $view->protected };
    main::chk( 'protected exception', qr/protected is a protected method of My::View/);
}

##############################################################################
# Now create a class using strings instead of contants.
STRINGS: {
    package My::Strings;
    use Test::More;
    ok my $cm = Class::Meta->new( key => 'strings' ),
        'Create strings meta object';
    ok $cm->add_method(
        name    => 'foo',
        view    => 'PUBLIC',
        context => 'Object',
    ), 'Add a method using strings for constant values';
    ok $cm->build, 'Build the class';
}

ok my $class = My::Strings->my_class, 'Get the class object';
ok my $attr = $class->methods( 'foo' ), 'Get the "foo" method';
is $attr->view, Class::Meta::PUBLIC, 'The view should be PUBLIC';
is $attr->context, Class::Meta::OBJECT, 'The context should be OBJECT';

sub chk {
    my ($name, $qr) = @_;
    # Catch the exception.
    ok( my $err = $@, "Caught $name error" );
    # Check its message.
    like( $err, $qr, "Correct error" );
    # Make sure it refers to this file.
    SKIP: {
        skip 'Older Carp lacks @CARP_NOT support', 2 unless $] >= 5.008;
        like( $err, qr/(?:at\s+\Q$0\E|\Q$0\E\s+at)\s+line/, 'Correct context' );
        # Make sure it doesn't refer to other Class::Meta files.
        unlike( $err, qr|lib/Class/Meta|, 'Not incorrect context')
    }
}
