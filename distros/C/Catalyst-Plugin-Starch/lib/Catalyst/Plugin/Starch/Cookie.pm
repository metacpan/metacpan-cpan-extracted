package Catalyst::Plugin::Starch::Cookie;
use 5.010001;
use strictures 2;
our $VERSION = '0.06';

=head1 NAME

Catalyst::Plugin::Starch::Cookie - Track starch state in a cookie.

=head1 SYNOPSIS

    package MyApp;
    
    use Catalyst qw(
        Starch::Cookie
        Starch
    );

=head1 DESCRIPTION

This plugin utilizes the L<Starch::Plugin::CookieArgs> plugin to add
a bunch of arguments to the Starch object, search the request cookies for
the session cookie, and write the session cookie at the end of the request.

See the L<Starch::Plugin::CookieArgs> documentation for a
list of arguments you can specify in the Catalyst configuration for
L<Catalyst::Plugin::Starch>.

=cut

use Class::Method::Modifiers qw( fresh );

use Moose::Role;
use namespace::clean;

=head1 COMPATIBILITY

Most of the methods documented in
L<Catalyst::Plugin::Session::Cookie/METHODS> are not
supported at this time:

=over

=item *

The C<make_session_cookie>, C<calc_expiry>,
C<calculate_session_cookie_expires>, C<cookie_is_rejecting>,
C<delete_session_id>, C<extend_session_id>,
C<get_session_id>, and C<set_session_id> methods are not currently
supported but could be if necessary.

=back

The above listed un-implemented methods and attributes will throw an exception
if called.

=cut

# These are already blocked by Catalyst::Plugin::Starch:
#    delete_session_id extend_session_id
#    get_session_id set_session_id

foreach my $method (qw(
    make_session_cookie calc_expiry
    calculate_session_cookie_expires cookie_is_rejecting
)) {
    fresh $method => sub{
        Catalyst::Exception->throw( "The $method method is not implemented by Catalyst::Plugin::Starch::Cookie" );
    };
}

=head1 METHODS

=head2 get_session_cookie

Returns the L<CGI::Simple::Cookie> object from L<Catalyst::Request>
for the session cookie, if there is one.

=cut

sub get_session_cookie {
    my ($c) = @_;

    my $cookie_name = $c->starch->cookie_name();
    my $cookie = $c->req->cookies->{ $cookie_name };

    return $cookie;
}

=head2 update_session_cookie

This is called automatically by the C<finalize_headers> step in Catalyst.  This method
is provided if you want to override the behavior.

=cut

sub update_session_cookie {
    my ($c) = @_;
    return if !$c->_has_sessionid();
    my $cookie_name = $c->starch->cookie_name();
    $c->res->cookies->{ $cookie_name } = $c->starch_state->cookie_args();
    return;
}

after prepare_cookies => sub{
    my ($c) = @_;

    my $cookie = $c->get_session_cookie();
    return if !$cookie;

    my $id = $cookie->value();
    return if !$c->starch->state_id_type->check( $id );

    $c->_set_sessionid( $id );
    return;
};

before finalize_headers => sub{
    my ($c) = @_;
    $c->update_session_cookie();
    return;
};

around default_starch_plugins => sub{
    my $orig = shift;
    my $c = shift;

    return [
        @{ $c->$orig() },
        '::CookieArgs',
    ];
};

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Catalyst::Plugin::Starch/AUTHOR> and
L<Catalyst::Plugin::Starch/LICENSE>.

=cut

