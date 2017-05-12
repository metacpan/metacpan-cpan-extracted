package Catalyst::Plugin::Authentication::Credential::OpenID;

use strict;
use warnings;
our $VERSION = '0.03';

use Net::OpenID::Consumer;
use LWPx::ParanoidAgent;
use UNIVERSAL::require;

sub setup {
    my $c = shift;
    my $config = $c->config->{authentication}->{openid} ||= {};
    ( $config->{user_class}
        ||=  "Catalyst::Plugin::Authentication::User::Hash" )->require;
    $c->NEXT::setup(@_);
}

sub authenticate_openid {
    my($c, $uri) = @_;

    my $config = $c->config->{authentication}->{openid};

    my $csr = Net::OpenID::Consumer->new(
        ua => LWPx::ParanoidAgent->new,
        args => $c->req->params,
        consumer_secret => sub { $_[0] },
    );

    my @try_params = qw( openid_url openid_identifier claimed_uri );
    if ($uri ||= (grep defined, @{$c->req->params}{@try_params})[0]) {
        my $current = $c->req->uri;
        $current->query(undef); # no query
        my $identity = $csr->claimed_identity($uri)
            or Catalyst::Exception->throw($csr->err);
        my $check_url = $identity->check_url(
            return_to  => $current . '?openid-check=1',
            trust_root => $current,
            delayed_return => 1,
        );
        $c->res->redirect($check_url);
        return 0;
    } elsif ($c->req->param('openid-check')) {
        if (my $setup_url = $csr->user_setup_url) {
            $c->res->redirect($setup_url);
            return 0;
        } elsif ($csr->user_cancel) {
            return 0;
        } elsif (my $identity = $csr->verified_identity) {
            my $user = +{ map { $_ => scalar $identity->$_ }
                qw( url display rss atom foaf declared_rss declared_atom declared_foaf foafmaker ) };

            my $store = $config->{store} || $c->default_auth_store;
            if ( $store
                 and my $store_user
                 = $store->get_user( $user->{url}, $user ) ) {
                $c->set_authenticated($store_user);
            } else {
                $user = $config->{user_class}->new($user);
                $c->set_authenticated($user);
            }
            return 1;
        } else {
            Catalyst::Exception->throw("Error validating identity: " .
                $csr->err);
        }
    } else {
        return 0;
    }
}

1;
__END__

=for stopwords
    Flickr
    OpenID
    TypeKey
    app
    auth
    callback
    foaf
    foafmaker
    plugins
    rss
    url
    URI

=head1 NAME

Catalyst::Plugin::Authentication::Credential::OpenID - OpenID credential for Catalyst::Auth framework

=head1 SYNOPSIS

  use Catalyst qw/
    Authentication
    Authentication::Credential::OpenID
    Session
    Session::Store::FastMmap
    Session::State::Cookie
  /;

  # MyApp.yaml -- optional
  authentication:
    openid:
      use_session: 1
      user_class: MyApp::M::User::OpenID

  # whatever in your Controller pm
  sub default : Private {
      my($self, $c) = @_;
      if ($c->user_exists) { ... }
  }

  sub signin_openid : Local {
      my($self, $c) = @_;

      if ($c->authenticate_openid) {
          $c->res->redirect( $c->uri_for('/') );
      }
  }

  # foo.tt
  <form action="[% c.uri_for('/signin_openid') %]" method="GET">
  <input type="text" name="openid_url" class="openid" />
  <input type="submit" value="Sign in with OpenID" />
  </form>

=head1 DESCRIPTION

Catalyst::Plugin::Authentication::Credential::OpenID is an OpenID
credential for Catalyst::Plugin::Authentication framework.

=head1 METHODS

=over 4

=item authenticate_openid

  $c->authenticate_openid;

Call this method in the action you'd like to authenticate the user via
OpenID. Returns 0 if auth is not successful, and 1 if user is
authenticated.

User class specified with I<user_class> config, which defaults to
Catalyst::Plugin::Authentication::User::Hash, will be instantiated
with the following parameters.

By default, L<authenticate_openid> method looks for claimed URI
parameter from the form field named C<openid_url>,
C<openid_identifier> or C<claimed_uri>. If you want to use another
form field name, call it like:

  $c->authenticate_openid( $c->req->param('myopenid_param') );

=over 8

=item url

=item display

=item rss

=item atom

=item foaf

=item declared_rss

=item declared_atom

=item declared_foaf

=item foafmaker

=back

See L<Net::OpenID::VerifiedIdentity> for details.

=back

=head1 DIFFERENCE WITH Authentication::OpenID

There's already Catalyst::Plugin::Authentication::OpenID
(Auth::OpenID) and this plugin tries to deprecate it.

=over 4

=item *

Don't use this plugin with Auth::OpenID since method names will
conflict and your app won't work.

=item *

Auth::OpenID uses your root path (/) as an authentication callback but
this plugin uses the current path, which means you can use this plugin
with other Credential plugins, like Flickr or TypeKey.

=item *

This plugin is NOT a drop-in replacement for Auth::OpenID, but your
app needs only slight modifications to work with this one.

=item *

This plugin is based on Catalyst authentication framework, which means
you can specify I<user_class> or I<auth_store> in your app config and
this modules does the right thing, like other Credential modules. This
crates new User object if authentication is successful, and works with
Session too.

=back

=head1 AUTHOR

Six Apart, Ltd. E<lt>cpan@sixapart.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication::OpenID>, L<Catalyst::Plugin::Authentication::Credential::Flickr>

=cut
