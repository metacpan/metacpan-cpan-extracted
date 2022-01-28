use 5.010;
use strict;
use utf8;
use warnings;

use Test::More tests => 6;

use Test::Exception;

use_ok 'Callable';

sub foo { 'main:foo' }
sub bar { ( $_[0] // '' ) eq __PACKAGE__ ? 'main:bar' : 'Bad method call' }
sub baz { 'main:baz' . join( ',', @_ ) }

{

    package Foo;

    use Callable;

    sub foo { 'Foo:foo' }
    sub bar { ( $_[0] // '' ) eq __PACKAGE__ ? 'Foo:bar' : 'Bad method call' }
    sub baz { 'Foo:baz' . join( ',', @_ ) }

    sub with_package           { Callable->new('Foo::foo') }
    sub without_package        { Callable->new('foo'); }
    sub method_with_package    { Callable->new('Foo->bar') }
    sub method_without_package { Callable->new('->bar') }
    sub with_args              { Callable->new('Foo::baz') }
}

{

    package Class;

    use Carp qw(croak);

    sub new         { bless [ splice @_, 1 ], __PACKAGE__ }
    sub constructor { bless [ splice @_, 1 ], __PACKAGE__ }

    sub foo {
        croak 'Bad instance method call' unless $_[0]->isa(__PACKAGE__);
        'Class:foo';
    }

    sub bar {
        croak 'Bad instance method call' unless $_[0]->isa(__PACKAGE__);
        'Class:bar:' . join( ',', @{ $_[0] } );
    }

    sub baz {
        croak 'Bad instance method call' unless $_[0]->isa(__PACKAGE__);
        my @args = ( @{ $_[0] }, splice( @_, 1 ) );
        'Class:baz:' . join( ',', @args );
    }
}

$INC{Class} = 1;    # disable loading by Module::Load

sub test_callable {
    my ( $source, $args, $expected, $comment ) = @_;

    $comment //= '';

    eval {
        my $callable = Callable->new( $source, @{$args} );

        is_deeply $callable->() => $expected, "Valid call result ($comment)";

        if ( not ref $expected ) {
            is
              "$callable" => $expected,
              "Valid interpolation result ($comment)";
        }
    };

    if ($@) {
        die "[$comment] $@";
    }
}

subtest 'Make subroutine callable' => sub {
    plan tests => 4;

    test_callable( sub { 'foo' }, [] => 'foo', 'subroutine source' );
    test_callable(
        sub { 'foo:' . $_[0] }, ['bar'] => 'foo:bar',
        'subroutine source with default arg'
    );
};

subtest 'Make scalar callable' => sub {
    plan tests => 17;

    test_callable( 'foo',      [] => 'main:foo', 'scalar without package' );
    test_callable( 'Foo::foo', [] => 'Foo:foo',  'scalar with package' );
    test_callable( 'baz', ['zz'] => 'main:bazzz', 'scalar with default args' );

    test_callable( Foo::with_package(), [] => 'Foo:foo', 'with_package' );
    test_callable(
        Foo::without_package(), [] => 'main:foo',
        'without_package'
    );
    test_callable( Foo::with_args(), ['zz'] => 'Foo:bazzz', 'with_args' );

    test_callable(
        Foo::method_with_package(), [] => 'Foo:bar',
        'method_with_package'
    );
    test_callable(
        Foo::method_without_package(), [] => 'main:bar',
        'method_without_package'
    );

    my $source   = 'not_existing_subroutine';
    my $callable = Callable->new($source);
    dies_ok { $callable->() }, 'Unable to call not existing';
};

subtest 'Make instance callable' => sub {
    plan tests => 2;

    test_callable(
        [ Class->new(), 'foo' ], [] => 'Class:foo',
        'instance as source'
    );
};

subtest 'Make class callable' => sub {
    plan tests => 10;

    test_callable(
        [ Class => 'foo' ], [] => 'Class:foo',
        'class name as source'
    );
    test_callable(
        [ 'Class->constructor' => 'foo' ], [] => 'Class:foo',
        'class name with constructor as source'
    );

    test_callable(
        [ Class => 'bar', 'foo', 'bar' ], [] => 'Class:bar:foo,bar',
        'class name with constructor args'
    );
    test_callable(
        [ Class => 'baz' ], [ 'foo', 'bar' ] => 'Class:baz:foo,bar',
        'class name with args'
    );
    test_callable(
        [ Class => 'baz', 'foo', 'bar' ],
        [qw(3 2 1)] => 'Class:baz:foo,bar,3,2,1',
        'class name with all default args'
    );
};

subtest 'Pass args to callable' => sub {
    plan tests => 2;

    my $callable = Callable->new( [ Class => 'baz', 'foo' ], 'bar' );

    is $callable->('baz') => 'Class:baz:foo,bar,baz',
      'class name with all args';
    is "$callable" => 'Class:baz:foo,bar', 'class name with args interpolation';
};
