package Catalyst::Plugin::AuthenCookie;

use strict;
use warnings;

our $VERSION = '0.07';

# No doubt SHA-512 is way overkill but it can't hurt (I hope).
use Digest::SHA qw( sha512_base64 );
use MRO::Compat;
use Params::Validate qw( validate HASHREF SCALAR );

sub setup
{
    my $self = shift;

    $self->next::method(@_);

    my $config = $self->config()->{authen_cookie};

    unless ( defined $config->{mac_secret} && length $config->{mac_secret} )
    {
        die "You must provide a mac_secret config value for the AuthenCookie plugin\n";
    }

    $config->{name} = 'authen-cookie'
        unless exists $config->{name};

    $config->{path} = '/'
        unless exists $config->{path};
}

{
    my $spec = { value   => { type => HASHREF },
                 expires => { type => SCALAR, default => undef },
               };

    sub set_authen_cookie
    {
        my $self = shift;
        my %p    = validate( @_, $spec );

        my $value = $p{value};

        $value->{MAC} = $self->_cookie_mac($value);

        my %cookie = $self->_cookie_from_config();

        $cookie{value} = $value;

        $cookie{expires} = $p{expires}
            if $p{expires};

        my $config = $self->_authen_cookie_config();

        $self->response()->cookies()->{ $config->{name} } = \%cookie;
    }
}

sub _cookie_from_config
{
    my $self = shift;

    my $config = $self->_authen_cookie_config();

    my %cookie;

    $cookie{domain} = $config->{domain}
        if $config->{domain};

    $cookie{path} = $config->{path};

    $cookie{secure} = $config->{secure};

    return %cookie;
}

sub _authen_cookie_config
{
    my $self = shift;

    return $self->config()->{authen_cookie};
}

sub _cookie_mac
{
    my $self  = shift;
    my $value = shift;

    my @hash_data;
    for my $key ( sort grep { $_ ne 'MAC' } keys %{ $value } )
    {
        push @hash_data, $key, $value->{$key};
    }

    my $config = $self->_authen_cookie_config();

    return sha512_base64( @hash_data, $config->{mac_secret} );
}

sub unset_authen_cookie
{
    my $self = shift;

    my %cookie = ( $self->_cookie_from_config(),
                   value   => '',
                   expires => '-1y',
                 );

    my $config = $self->_authen_cookie_config();

    $self->response()->cookies()->{ $config->{name} } = \%cookie;

    return;
}

sub authen_cookie_value
{
    my $self = shift;

    my $config = $self->_authen_cookie_config();

    my $cookie = $self->request()->cookies()->{ $config->{name} };

    return unless $cookie && $cookie->value();

    my %value = $cookie->value();

    my $mac = $self->_cookie_mac(\%value);

    return unless $value{MAC} && $value{MAC} eq $mac;

    return \%value;
}

1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::AuthenCookie - DEPRECATED - use CatalystX::AuthenCookie

=head1 SYNOPSIS

    use Catalyst qw( AuthenCookie );

    $c->set_authen_cookie( value => { user_id => 1234 } );

    my $value = $c->authen_cookie_value();

    print $value->{user_id};

    $c->unset_authen_cookie();

=head1 DESCRIPTION

B<This module is deprecated. Use L<CatalystX::AuthenCookie> instead.>

This plugin provides a few methods to help you implement a secure
cookie-based implementation scheme. It I<does not> interact with the
C<Catalyst::Plugin::Authentication> system, and expects that you will
implement the actual logging in and out inside your controller code.

What it does provide is a few methods for setting a cookie and
retrieving it later, along with some configuration of that cookie.

When it sets a cookie, it adds a MAC (Message Authentication Code) to
the cookie. The MAC is based off of the cookie's values and a
server-side secret you provide. This allows the plugin to verify that
the cookie is valid when it receives it from the client on future
requests, and prevents a malicious client from forging a user id. The
cookie is still vulnerable to hijacking (as are most common web
authentication mechanisms).

=head1 METHODS

This class provides the following methods:

=head2 $c->set_authen_cookie( value => $value, expires => $expires )

This method takes a C<value> and an optional C<expires> parameter and
sets a cookie based on those values, as well as this plugin's
configuration.

The C<value> parameter must be a hash reference. Presumably, it will
contain something like a user id, which will allow you to identify the
user on future requests.

The C<expires> parameter is optional. If given, it should be something
that C<CGI::Cookie> can handle, like "+1d".

Also see the L<CONFIG> section for more details on configuring the
cookie.

=head2 $c->unset_authen_cookie()

This method removes the cookie from the client by sending a new cookie
header with an expiration time in the past and an empty value.

=head2 $c->authen_cookie_value()

This method returns a hash reference containing the value of the
authentication cookie. This method simply returns false if there is no
cookie or if the MAC is invalid.

=head1 CONFIG

The top-level configuration key for this plugin is
"authen_cookie". Most of the configuration keys correspond to
C<CGI::Cookie> constructor parameters, and reading that module's
documentation may be helpful. The follow config keys are available for
this module:

=over 4

=item * name - optional

The name of the cookie. This defaults to "authen-cookie". It's
probably a good idea to set this to something specific to your app.

=item * mac_secret - required

This can be any scalar value. It should be a value that is consistent
across application restarts and multiple app servers, as changing this
secret will invalidate existing cookies.

You should never reveal to clients, since once it is known it is easy
to forge a valid cookie.

=item * path - optional

The path to which the cookie applies. Defaults to F</>.

=item * secure - optional

This is a boolean indicating whether the cookie is SSL-only or
not. Defaults to false.

=item * domain - optional

The domain used for the cookie. By default, this is not set at all,
but if your app operates across multiple hostnames in the same domain,
you probably want to set this.

=back

=head1 USAGE EXAMPLE

This module I<does not> provide a complete authentication solution,
and will require some code on your side to tie things together.

Presumably, you want to be able to identify a user on each request and
probably make a object from one of your model classes for that
user. You also need to decide when to set and remove the cookie,
presumably in your controller.

Here are some examples of each piece you might implement. First, a
login action in your controller:

  package MyApp::Controller::User;

  sub login : Local
  {
      my $self = shift;
      my $c    = shift;

      my $email = $c->request()->param('email_address');
      my $pw    = $c->request()->param('password');

      my $user =
          MyApp::Model::User->new( email    => $email,
                                   password => $pw,
                                 );

      if ( ! $user )
      {
          # login failed, do something to handle that
      }

      my %expires;
      %expires = ( expires => '+1y' )
          if $c->request()->param('remember');

      $c->set_authen_cookie( value => { user_id => $user->user_id() },
                             %expires,
                           );

      # redirect to some other page
  }

One thing to note is that the user will not be retrievable from the
cookie until the I<next> request. If you always redirect after a form
POST this isn't an issue, but for some apps it may be important.

The logout action is even simpler:

  package MyApp::Controller::User;

  sub logout : Local
  {
      my $self = shift;
      my $c    = shift;

      $c->unset_authen_cookie();

      # redirect
  }

Finally, we need a small plugin to retrieve the user from the cookie
on request:

    package MyApp::Plugin::User;

    use strict;
    use warnings;

    use base 'Class::Accessor::Fast';

    __PACKAGE__->mk_accessors( '_user', '_checked_cookie' );


    sub user
    {
        my $self = shift;

        my $user = $self->_user();

        unless ( $user || $self->_checked_cookie() )
        {
            $user = $self->_get_user_from_cookie();
            $self->_user($user);
            $self->_checked_cookie(1);
        }

        return $user;
    }

    sub _get_user_from_cookie
    {
        my $self = shift;

        my $cookie = $self->authen_cookie_value();

        return unless $cookie && $cookie->{user_id};

        return MyApp::Model::User->new( user_id => $cookie->{user_id} );
    }

    1;

Loading this plugin gives you a C<< $c->user() >> method which fetches
the user on demand. The C<_checked_cookie> attribute is there to
prevent us from checking for the cookie repeatedly when the cookie
does not exist or reference a valid user. Another solution would be to
return an object representing a guest user as a default.

=head1 AUTHOR

Dave Rolsky, C<< <autarch@urth.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-authencookie@rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
