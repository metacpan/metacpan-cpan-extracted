package Callable;

use 5.010;
use strict;
use utf8;
use warnings;

use Carp qw(croak);
use Module::Load;
use Scalar::Util qw(blessed);

use overload '&{}' => '_to_sub', '""' => '_to_string';
use constant ( USAGE =>
'Usage: Callable->new(&|$|[object|"class"|"class->constructor", "method"])'
);

our $VERSION = "0.02";

our $DEFAULT_CLASS_CONSTRUCTOR = 'new';

sub new {
    my ( $class, @options ) = @_;

    if (   @options
        && blessed( $options[0] )
        && $options[0]->isa(__PACKAGE__) )
    {
        return $options[0]->_clone( splice @options, 1 );
    }

    my $self = bless { options => \@options }, $class;
    $self->_validate_options();

    return $self;
}

sub _clone {
    my ( $self, @options ) = @_;

    if (@options) {
        unshift @options, $self->{options}->[0];
    }
    else {
        @options = @{ $self->{options} };
    }

    return bless { options => \@options }, ref($self);
}

sub _first_arg {
    my ( $self, $value ) = @_;

    if ( @_ > 1 ) {
        $self->{__first_arg} = $value;
    }

    if (wantarray) {
        return unless exists $self->{__first_arg};
        return ( $self->{__first_arg} );
    }

    return $self->{__first_arg} // undef;
}

sub _handler {
    my ( $self, $caller ) = @_;

    unless ( exists $self->{__handler} ) {
        $self->{__handler} = $self->_make_handler($caller);
    }

    return $self->{__handler};
}

sub _make_handler {
    my ( $self, $caller ) = @_;

    my ( $source, @default_args ) = @{ $self->{options} };
    my $ref = ref $source;

    my $handler =
      $ref eq 'CODE' ? $source
      : (
          $ref eq 'ARRAY' ? $self->_make_object_handler( $source, $caller )
        : $self->_make_scalar_handler( $source, $caller )
      );
    my @args = ( $self->_first_arg, @default_args );

    if (@args) {
        my $inner = $handler;
        $handler = sub { $inner->( @args, @_ ) };
    }

    return $handler;
}

sub _make_object_handler {
    my ( $self, $source, $caller ) = @_;

    my ( $object, $method, @args ) = @{$source};

    unless ( blessed $object) {
        my ( $class, $constructor, $garbage ) = split /\Q->\E/, $object;

        croak "Wrong class name format: $object" if defined $garbage;

        load $class;

        $constructor //= $DEFAULT_CLASS_CONSTRUCTOR;

        $object = $class->$constructor(@args);
    }

    $self->_first_arg($object);

    return $object->can($method);
}

sub _make_scalar_handler {
    my ( $self, $name, $caller ) = @_;

    my @path = split /\Q->\E/, $name;
    croak "Wrong subroutine name format: $name" if @path > 2;

    if ( @path == 2 ) {
        $path[0] ||= $caller;
        $self->_first_arg( $path[0] );
        $name = join '::', @path;
    }

    @path = split /::/, $name;

    if ( @path == 1 ) {
        unshift @path, $caller;
    }

    $name = join( '::', @path );
    my $handler = \&{$name};

    croak "Unable to find subroutine: $name" if not $handler;

    return $handler;
}

sub _to_string {
    my ($self) = @_;

    return $self->_to_sub( scalar caller )->();
}

sub _to_sub {
    my ( $self, $caller ) = @_;

    $caller //= caller;

    return $self->_handler($caller);
}

sub _validate_options {
    my ($self) = @_;

    croak USAGE unless @{ $self->{options} };

    my $source = $self->{options}->[0];
    my $ref    = ref($source);
    croak USAGE unless $ref eq 'CODE' || $ref eq 'ARRAY' || $ref eq '';

    if ( $ref eq 'ARRAY' ) {
        croak USAGE if @{$source} < 2;
        croak USAGE unless blessed $source->[0] || ref( $source->[0] ) eq '';
        croak USAGE if ref $source->[1];
    }
}

1;
__END__

=encoding utf-8

=head1 DISCLAIMER

Sorry for my English ...

=head1 NAME

Callable - make different things callable

=head1 SYNOPSIS

    my $db = DBI->connect( ... );
    my $router = My::Router->new(
        # use subroutine as handler
        '/' => Callable->(
            sub { my ($db, $request) = @_; ... },

            # inject default arguments to handler
            $db
        ),

        # use subroutine by name as handler
        '/profile' => Callable->new(
            # call handler as package method
            'Controller::Profile->home',

            # inject default arguments to handler
            db => $db,
            authenticated_only => 1
        ),

        # create class instance and use it as handler
        '/admin' => Callable->new(
            [
                # class_name => method
                'Controller::Admin' => 'home',

                # inject arguments to constructor
                db => $db
            ],

            # inject default arguments to handler
            restrictions => {role => 'admin'}
        ),
    );

    my $handler = $router->match($ENV{REQUEST_URI});

    # send additional arguments when calling handler
    my $response = $handler->(Request->new(%ENV));
    print $response->dump();

=head1 DESCRIPTION

Callable is a simple wrapper for make subroutines from different sources.
Can be used in applications with configurable callback maps (e.g. website router config).
Inspired by PHP's L<callable|https://www.php.net/manual/ru/language.types.callable.php>

=head1 METHODS

=head2 new($source[, @default_args])

Create instance. Arguments:

=over

=item $source

See L</SOURCES>

=item @default_args

Default arguments that will be sent to handler

    my $hello = Callable->new(sub { join ', ', @_; }, 'Hello');
    print $hello->('World'); # Hello, World
    print $hello->('Bro'); # Hello, Bro
    print "$hello, World"; # Hello, World

=back

=head2 overload '&{}'

Callable instance can be called like a subroutine reference:

    my $foo = Callable->new( ... );
    my $result = $foo->();

=head2 overload '""'

Callable instance can be interpolated:

    my $foo = Callable->new( ... );
    my $result = "Foo: $foo."; # same as 'Foo: ' . $foo->() . '.'

=head1 SOURCES

=head2 subroutine reference

    my $foo = Callable->new(sub { ... });

=head2 subroutine name

    my $foo = Callable->new('foo::bar');

Finds subroutine reference by it's name (C<\&{$name}>). Name can be:
Fully-qualified (C<Module::Name::sub_name>) names used as is,
not qualified names (C<sub_name>) will be prefixed with package, where
callable was called from (see L<caller>):

    {
        package Foo;
        sub foo { 'Foo' }
        sub bar { Callable->new('Foo::foo') }
        sub baz { Callable->new('foo') }
    }

    package main;

    # ok, fully-qualified name 'Foo::foo', subroutine found
    print Foo::bar->();

    # not ok, 'foo' has no package name, so it will be interpreted as 'main::foo'
    print Foo::baz->();

=head2 package method

Same as L</subroutine name>, but with C<-E<gt>> before subroutine name:

    # Fully-qualified
    my $foo = Callable->new('Module::Name->sub_name');

    # Not qualified
    my $foo = Callable->new('->sub_name');

=head2 object method

    my $obj = My::Class->new( ... );
    my $foo = Callable->new([$obj => 'method_name']);

=head2 class and method

    my $foo = Callable->new(['My::Class' => 'method_name']);

C<$foo-E<gt>()> creates C<My::Class> instance and calls C<-E<gt>metod_name>.

Constructor name can be specified:

    my $foo = Callable->new(['My::Class->constructor_name' => 'method_name']);

C<$Callable::DEFAULT_CLASS_CONSTRUCTOR> is used when no constructor name
given (C<new> by default)

=head2 callable

Callable instance can be cloned from another callable instance:

    my $source = Callable->new(sub { ... });
    my $foo = Callable->new($source);

Usable for re-create class instance (L</class and method>) and/or for resetting
default L</Arguments>

=head1 ARGUMENTS

Send arguments when calling:

    my $foo = Callable->new(sub { join ',', @_ });
    print $foo->(qw(Hello , World)); # prints Hello,World

Send default arguments when create instance:

    my $foo = Callable->new(sub { join ',', @_ }, 'Hello');
    print $foo->(qw(, World)); # prints Hello,World
    print $foo->(qw(, Bro)); # prints Hello,Bro

Send arguments to class constructor:

    {
        package My::Class;
        sub new {
            my $class = shift;
            return bless \@_, $class;
        }

        sub foo {
            my $self = shift;
            return join ' ', @{$self}, @_;
        }
    }

    my $foo = Callable->new(['My::Class', 'foo', 'Hello'], ',');
    print $foo->('World'); # prints Hello , World
    print $foo->('Bro'); # prints Hello , Bro

=head1 LICENSE

Copyright (C) Al Tom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Al Tom E<lt>al-tom.ru@yandex.ruE<gt>

=cut

