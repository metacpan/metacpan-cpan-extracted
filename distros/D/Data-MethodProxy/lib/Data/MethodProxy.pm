package Data::MethodProxy;
use 5.008001;
use strict;
use warnings;
our $VERSION = '0.04';

=encoding utf8

=head1 NAME

Data::MethodProxy - Inject dynamic data into static data.

=head1 SYNOPSIS

    use Data::MethodProxy;
    
    my $mproxy = Data::MethodProxy->new();
    
    my $output = $mproxy->render({
        half_six => ['$proxy', 'main', 'half', 6],
    });
    # { half_six => 3 }
    
    sub half {
        my ($class, $number) = @_;
        return $number / 2;
    }

=head1 DESCRIPTION

A method proxy is an array ref describing a class method to call and the
arguments to pass to it.  The first value of the array ref is the scalar
C<$proxy>, followed by a package name, then a subroutine name which must
callable in the package, and a list of any subroutine arguments.

    [ '$proxy', 'Foo::Bar', 'baz', 123, 4 ]

The above is saying, do this:

    Foo::Bar->baz( 123, 4 );

The L</render> method is the main entry point for replacing all found
method proxies in an arbitrary data structure with the return value of
calling the methods.

=head2 Example

Consider this static YAML configuration:

    ---
    db:
        dsn: DBI:mysql:database=foo
        username: bar
        password: abc123

Putting your database password inside of a configuration file is usually
considered a bad practice.  You can use a method proxy to get around this
without jumping through a bunch of hoops:

    ---
    db:
        dsn: DBI:mysql:database=foo
        username: bar
        password:
            - $proxy
            - MyApp::Config
            - get_db_password
            - foo-bar

When L</render> is called on the above data structure it will
see the method proxy and will replace the array ref with the
return value of calling the method.

A method proxy, in Perl syntax, looks like this:

    ['$proxy', $package, $method, @args]

The C<$proxy> string can also be written as C<&proxy>.  The above is then
converted to a method call and replaced by the return value of the method call:

    $package->$method( @args );

In the above database password example the method call would be this:

    MyApp::Config->get_db_password( 'foo-bar' );

You'd still need to create a C<MyApp::Config> package, and add a
C<get_db_password> method to it.

=cut

use Scalar::Util qw( refaddr );
use Module::Runtime qw( require_module is_module_name );
use Carp qw( croak );

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

our $FOUND_DATA;

=head1 METHODS

=head2 render

    my $output = $mproxy->render( $input );

Traverses the supplied data looking for method proxies, calling them, and
replacing them with the return value of the method call.  Any value may be
passed, such as a hash ref, an array ref, a method proxy, an object, a scalar,
etc.  Array and hash refs will be recursively searched for method proxies.

If a circular reference is detected an error will be thrown.

=cut

sub render {
    my ($self, $data) = @_;

    return $data if !ref $data;

    local $FOUND_DATA = {} if !$FOUND_DATA;

    my $refaddr = refaddr( $data );
    if ($FOUND_DATA->{$refaddr}) {
        local $Carp::Internal{ (__PACKAGE__) } = 1;
        croak 'Circular reference detected in data passed to render()';
    }
    $FOUND_DATA->{$refaddr} = 1;

    if (ref($data) eq 'HASH') {
        return {
            map { $_ => $self->render( $data->{$_} ) }
            keys( %$data )
        };
    }
    elsif (ref($data) eq 'ARRAY') {
        if ($self->is_valid( $data )) {
            return $self->call( $data );
        }

        return [
            map { $self->render( $_ ) }
            @$data
        ];
    }

    return $data;
}

=head2 call

    my $return = $mproxy->call( ['$proxy', $package, $method, @args] );

Calls the method proxy and returns its return.

=cut

sub call {
    my ($self, $proxy) = @_;

    {
        local $Carp::Internal{ (__PACKAGE__) } = 1;
        croak 'Invalid method proxy passed to call()' if !$self->is_valid( $proxy );
        croak 'Uncallable method proxy passed to call()' if !$self->is_callable( $proxy );
    }

    my ($marker, $package, $method, @args) = @$proxy;
    require_module( $package );
    return $package->$method( @args );
}

=head2 is_valid

    die unless $mproxy->is_valid( ... );

Returns true if the passed value looks like a method proxy.

=cut

sub is_valid {
    my ($self, $proxy) = @_;

    return 0 if ref($proxy) ne 'ARRAY';
    my ($marker, $package, $method, @args) = @$proxy;

    return 0 if !defined $marker;
    return 0 if $marker !~ m{^[&\$]proxy$};
    return 0 if !defined $package;
    return 0 if !defined $method;

    return 1;
}

=head2 is_callable

    die unless $mproxy->is_callable( ... );

Returns true if the passed value looks like a method proxy,
and has a package and method which exist.

=cut

sub is_callable {
    my ($self, $proxy) = @_;

    return 0 if !$self->is_valid( $proxy );
    my ($marker, $package, $method, @args) = @$proxy;

    return 0 if !is_module_name( $package );
    return 0 if !$package->can( $method );

    return 1;
}

1;
__END__

=head1 SUPPORT

Please submit bugs and feature requests to the
Data-MethodProxy GitHub issue tracker:

L<https://github.com/bluefeet/Data-MethodProxy/issues>

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

