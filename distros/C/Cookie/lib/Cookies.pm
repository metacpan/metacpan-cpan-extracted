##----------------------------------------------------------------------------
## Cookies API for Server & Client - ~/lib/Cookies.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/14
## Modified 2021/12/14
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Cookies;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Cookie::Jar );
    our $VERSION = $Cookie::Jar::VERSION;
};

1;

__END__

=encoding utf-8

=head1 NAME

Cookies - Cookies API for Server & Client

=head1 SYNOPSIS

    use Cookies;
    my $jar = Cookies->new( request => $r ) ||
    return( $self->error( "An error occurred while trying to get the cookie jar." ) );
    # set the default host
    $jar->host( 'www.example.com' );
    $jar->fetch;
    # or using a HTTP::Request object
    # Retrieve cookies from Cookie header sent from client
    $jar->fetch( request => $http_request );
    if( $jar->exists( 'my-cookie' ) )
    {
        # do something
    }
    # get the cookie
    my $sid = $jar->get( 'my-cookie' );
    # get all cookies
    my @all = $jar->get( 'my-cookie', 'example.com', '/' );
    # set a new Set-Cookie header
    $jar->set( 'my-cookie' => $cookie_object );
    # Remove cookie from jar
    $jar->delete( 'my-cookie' );
    # or using the object itself:
    $jar->delete( $cookie_object );

    # Create and add cookie to jar
    $jar->add(
        name => 'session',
        value => 'lang=en-GB',
        path => '/',
        secure => 1,
        same_site => 'Lax',
    ) || die( $jar->error );
    # or add an existing cookie
    $jar->add( $some_cookie_object );

    my $c = $jar->make({
        name => 'my-cookie',
        domain => 'example.com',
        value => 'sid1234567',
        path => '/',
        expires => '+10D',
        # or alternatively
        maxage => 864000
        # to make it exclusively accessible by regular http request and not ajax
        http_only => 1,
        # should it be used under ssl only?
        secure => 1,
    });

    # Add the Set-Cookie headers
    $jar->add_response_header;
    # Alternatively, using a HTTP::Response object or equivalent
    $jar->add_response_header( $http_response );
    $jar->delete( 'some_cookie' );
    $jar->do(sub
    {
        # cookie object is available as $_ or as first argument in @_
    });

    # For client side
    # Takes a HTTP::Response object or equivalent
    # Extract cookies from Set-Cookie headers received from server
    $jar->extract( $http_response );
    # get by domain; by default sort it
    my $all = $jar->get_by_domain( 'example.com' );
    # Reverse sort
    $all = $jar->get_by_domain( 'example.com', sort => 0 );

    # Save cookies repository as json
    $jar->save( '/some/where/mycookies.json' ) || die( $jar->error );
    # Load cookies into jar
    $jar->load( '/some/where/mycookies.json' ) || die( $jar->error );

    # Save encrypted
    $jar->save( '/some/where/mycookies.json',
    {
        encrypt => 1,
        key => $key,
        iv => $iv,
        algo => 'AES',
    }) || die( $jar->error );
    # Load cookies from encrypted file
    $jar->load( '/some/where/mycookies.json',
    {
        decrypt => 1,
        key => $key,
        iv  => $iv,
        algo => 'AES'
    }) || die( $jar->error );

    # Merge repository
    $jar->merge( $jar2 ) || die( $jar->error );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This module implement a cookie jar and inherits all of its methods from L<Cookie::Jar>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Cookie>, L<Cookie::Jar>, L<Cookie::Domain>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
