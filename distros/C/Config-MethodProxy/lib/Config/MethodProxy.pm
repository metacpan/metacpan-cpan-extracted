package Config::MethodProxy;
$Config::MethodProxy::VERSION = '0.02';
=head1 NAME

Config::MethodProxy - Integrate dynamic logic with static configuration.

=head1 SYNOPSIS

    use Config::MethodProxy;
    
    $config = get_your_config_somewhere();
    $config = apply_method_proxies( $config );

=head1 DESCRIPTION

A method proxy is a particular data structure which, when found,
is replaced by the value returned by calling that method.  In this
way static configuration can be setup to call your code and return
dynamic contents.  This makes static configuration much more powerful,
and gives you the ability to be more declarative in how dynamic values
make it into your configuration.

=head1 EXAMPLE

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
            - bar

When L</apply_method_proxies> is called on the above data structure it will
see the method proxy and will replace the array ref with the return value of
calling the method.

A method proxy, in Perl syntax, looks like this:

    ['$proxy', $package, $method, @args]

The C<$proxy> string can also be written as C<&proxy>.  The above is then
converted to a method call and replaced by the return value of the method call:

    $package->$method( @args );

In the above database password example the method call would be this:

    MyApp::Config->get_db_password( 'bar' );

You would still need to create a C<MyApp::Config> package, and add a
C<get_db_password> method to it.

=cut

use Scalar::Util qw( refaddr );
use Module::Runtime qw( require_module is_module_name );
use Carp qw( croak );

use strictures 2;
use namespace::clean;

use Exporter qw( import );

our @EXPORT = qw(
    apply_method_proxies
);

our @EXPORT_OK = qw(
    apply_method_proxies
    is_method_proxy
    call_method_proxy
);

our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

=head1 FUNCTIONS

Only the L</apply_method_proxies> function is exported by default.

=head2 apply_method_proxies

    $config = apply_method_proxies( $config );

Traverses the supplied data looking for method proxies, calling them, and
replacing them with the return value of the method.  Any value may be passed,
such as a hash ref, an array ref, a method proxy, an object, a scalar, etc.
Array and hash refs will be recursively searched for method proxies.

If a circular reference is detected an error will be thrown.

=cut

our $found_data;

sub apply_method_proxies {
    my ($data) = @_;

    return $data if !ref $data;

    local $found_data = {} if !$found_data;
    my $refaddr = refaddr( $data );
    if ($found_data->{$refaddr}) {
        local $Carp::Internal{ (__PACKAGE__) } = 1;
        croak 'Circular reference encountered in data passed to apply_method_proxies';
    }
    $found_data->{$refaddr} = 1;

    if (ref($data) eq 'HASH') {
        return {
            map { $_ => apply_method_proxies( $data->{$_} ) }
            keys( %$data )
        };
    }
    elsif (ref($data) eq 'ARRAY') {
        if (is_method_proxy( $data )) {
            return call_method_proxy( $data );
        }

        return [
            map { apply_method_proxies( $_ ) }
            @$data
        ];
    }

    return $data;
}

=head2 is_method_proxy

    if (is_method_proxy( $some_data )) { ... }

Returns true if the supplied data is an array ref where the first value
is the string C<$proxy> or C<&proxy>.

=cut

sub is_method_proxy {
    my ($proxy) = @_;

    return 0 if ref($proxy) ne 'ARRAY';
    return 0 if !@$proxy;
    return 0 if !defined $proxy->[0];
    return 0 if $proxy->[0] !~ m{^[&\$]proxy$};

    return 1;
}

=head2 call_method_proxy

    call_method_proxy( ['$proxy', $package, $method, @args] );

Calls a method proxy and returns the value.

=cut

sub call_method_proxy {
    my ($proxy) = @_;

    local $Carp::Internal{ (__PACKAGE__) } = 1;

    croak 'Not a method proxy array ref' if !is_method_proxy( $proxy );

    my ($marker, $package, $method, @args) = @$proxy;

    croak 'The method proxy package is undefined' if !defined $package;
    croak 'The method proxy method is undefined' if !defined $method;

    croak "The method proxy package, '$package', is not a valid package name"
        if !is_module_name( $package );

    require_module( $package );

    return $package->$method( @args );
}

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

