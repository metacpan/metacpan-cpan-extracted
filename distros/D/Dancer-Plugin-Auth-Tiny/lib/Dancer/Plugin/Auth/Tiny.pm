use 5.008001;
use strict;
use warnings;

package Dancer::Plugin::Auth::Tiny;
# ABSTRACT: Require logged-in user for specified routes
our $VERSION = '0.002'; # VERSION

use Carp qw/croak/;

use Dancer ':syntax';
use Dancer::Plugin;

my $conf;
my %dispatch = ( login => \&_build_login, );

register 'needs' => sub {
  my ( $self, $condition, @args ) = plugin_args(@_);

  my $builder = $dispatch{$condition};

  if ( ref $builder eq 'CODE' ) {
    return $builder->(@args);
  }
  else {
    croak "Unknown authorization condition '$condition'";
  }
};

sub extend {
  my ( $class, @args ) = @_;
  unless ( @args % 2 == 0 ) {
    croak "arguments to $class\->extend must be key/value pairs";
  }
  %dispatch = ( %dispatch, @args );
}

sub _build_login {
  my ($coderef) = @_;
  return sub {
    $conf ||= { _default_conf(), %{ plugin_setting() } }; # lazy
    if ( session $conf->{logged_in_key} ) {
      goto $coderef;
    }
    else {
      my $query_params = params("query");
      my $data =
        { $conf->{callback_key} => uri_for( request->path, $query_params ) };
      for my $k ( @{ $conf->{passthrough} } ) {
        $data->{$k} = params->{$k} if params->{$k};
      }
      return redirect uri_for( $conf->{login_route}, $data );
    }
  };
}

sub _default_conf {
  return (
    login_route   => '/login',
    logged_in_key => 'user',
    callback_key  => 'return_url',
    passthrough   => [qw/user/],
  );
}

register_plugin for_versions => [ 1, 2 ];

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Dancer::Plugin::Auth::Tiny - Require logged-in user for specified routes

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Dancer::Plugin::Auth::Tiny;

  get '/private' => needs login => sub { ... };

  get '/login' => sub {
    # put 'return_url' in a hidden form field
    template 'login' => { return_url => params->{return_url} };
  };

  post '/login' => sub {
    if ( _is_valid( params->{user}, params->{password} ) ) {
      session user => params->{user},
      return redirect params->{return_url} || '/';
    }
    else {
      template 'login' => { error => "invalid username or password" };
    }
  };

  sub _is_valid { ... } # this is up to you

=head1 DESCRIPTION

This L<Dancer> plugin provides an extremely simple way of requiring that a user
be logged in before allowing access to certain routes.

It is not "Tiny" in the usual CPAN sense, but it is "Tiny" with respect to
Dancer authentication plugins.  It provides very simple sugar to wrap route
handlers with an authentication closure.

The plugin provides the C<needs> keyword and a default C<login> wrapper that
you can use like this:

  get '/private' => needs login => $coderef;

The code above is roughly equivalent to this:

  get '/private' => sub {
    if ( session 'user' ) {
      goto $coderef;
    }
    else {
      return redirect uri_for( '/login',
        { return_url => uri_for( request->path, request->params ) } );
    }
  };

It is up to you to provide the '/login' route, handle actual authentication,
and set C<user> session variable if login is successful.

If the original request contains a parameter in the C<passthrough> list, it
will be added to the login query. For example,
C<http://example.com/private?user=dagolden> will be redirected as
C<http://example.com/login?user=dagolden&return_url=...>.  This facilitates
pre-populating a login form.

=for Pod::Coverage extend

=head1 CONFIGURATION

You may override any of these settings:

=over 4

=item *

C<login_route: /login> -- defines where a protected route is redirected

=item *

C<logged_in_key: user> -- defines the session key that must be true to indicate a logged-in user

=item *

C<callback_key: return_url> -- defines the parameter key with the original request URL that is passed to the login route

=item *

C<passthrough: - user> -- a list of parameters that should be passed through to the login handler

=back

=head1 EXTENDING

The class method C<extend> may be used to add (or override) authentication
criteria. For example, to add a check for the C<session 'is_admin'> key:

  Dancer::Plugin::Auth::Tiny->extend(
    admin => sub {
      my ($coderef) = @_;
      return sub {
        if ( session "is_admin" ) {
          goto $coderef;
        }
        else {
          redirect '/access_denied';
        }
      };
    }
  );

  get '/super_secret' => needs admin => sub { ... };

It takes key/value pairs where the value must be a closure generator that wraps
arguments passed to C<needs>.

You could pass additional arguments before the code reference like so:

  # don't conflict with Dancer's any()
  use Syntax::Keyword::Junction 'any' => { -as => 'any_of' };

  Dancer::Plugin::Auth::Tiny->extend(
    any_role => sub {
      my $coderef = pop;
      my @requested_roles = @_;
      return sub {
        my @user_roles = @{ session("roles") || [] };
        if ( any_of(@requested_roles) eq any_of(@user_roles) {
          goto $coderef;
        }
        else {
          redirect '/access_denied';
        }
      };
    }
  );

  get '/parental' => needs any_role => qw/mom dad/ => sub { ... };

=head1 SEE ALSO

For more complex L<Dancer> authentication, see:

=over 4

=item *

L<Dancer::Plugin::Auth::Extensible>

=item *

L<Dancer::Plugin::Auth::RBAC>

=back

For password authentication algorithms for your own '/login' handler, see:

=over 4

=item *

L<Auth::Passphrase>

=item *

L<Dancer::Plugin::Passphrase>

=back

=head1 ACKNOWLEDGMENTS

This simplified Auth module was inspired by Dancer::Plugin::Auth::Extensible by
David Precious and discussions about its API by member of the Dancer Users
mailing list.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/dancer-plugin-auth-tiny/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/dancer-plugin-auth-tiny>

  git clone git://github.com/dagolden/dancer-plugin-auth-tiny.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
