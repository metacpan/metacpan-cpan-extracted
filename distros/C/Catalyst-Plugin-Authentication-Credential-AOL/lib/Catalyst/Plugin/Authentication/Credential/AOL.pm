package Catalyst::Plugin::Authentication::Credential::AOL;

use strict;
our $VERSION = '0.02';

use UNIVERSAL::require;
use JSON::Any;

sub setup {
    my $c = shift;
    my $config = $c->config->{authentication}->{aol} ||= {};
    ( $config->{user_class}
        ||=  "Catalyst::Plugin::Authentication::User::Hash" )->require;
    $c->NEXT::setup(@_);
}

sub authenticate_aol {
    my $c = shift;

    my $config = $c->config->{authentication}->{aol};

    my $current = $c->req->uri;
    $current->query(undef); # no query

    if ($c->req->params->{token_a}) {
        my $uri = URI->new("http://api.screenname.aol.com/auth/getInfo");
        $uri->query_form(
            devId => $config->{devId},
            f     => 'json',
            # referer needs to be an actual Referer: header, but since
            # we do redirection, it doesn't match with succUrl :/
            referer => $current->as_string,
            a     => $c->req->params->{token_a},
        );

        my $ua = LWP::UserAgent->new(agent => "Catalyst::Plugin::Authentication::Credential::AOL/$VERSION");
        my $res = $ua->get($uri);
        unless ($res->is_success) {
            $c->log->info("Authentication failure: HTTP error " . $res->status_line);
            return;
        }

        my $data = JSON::Any->jsonToObj($res->content);
        unless (($data->{response}->{statusCode} || '') eq '200') {
            $c->log->info("Authentication failure: " . $data->{response}->{statusCode});
            return;
        }

        my $user = $data->{response}->{data}->{userData};
        $c->log->debug("Successfully authenticated user '$user->{loginId}'.")
            if $c->debug;

        my $store = $config->{store} || $c->default_auth_store;
        if ( $store
             and my $store_user
             = $store->get_user( $user->{loginId}, $user ) ) {
            $c->set_authenticated($store_user);
        } else {
            $user = $config->{user_class}->new($user);
            $c->set_authenticated($user);
        }

        return 1;
    } else {
        my $uri = URI->new("http://api.screenname.aol.com/auth/login");
        $uri->query_form(
            devId => $config->{devId},
            succUrl => $current,
        );

        $c->res->redirect($uri);
        return;
    }
}

1;
__END__

=for stopwords OpenID OpenAuth

=head1 NAME

Catalyst::Plugin::Authentication::Credential::AOL - AOL OpenAuth credential

=head1 SYNOPSIS

  # myapp.yaml
  authentication:
    aol:
      devId: AOL_DEVELOPER_TOKEN

  # MyApp.pm
  package MyApp;
  use Catalyst qw/
      Authentication
      Authentication::Credential::AOL
      Session
      Session::Store::FastMmap
      Session::State::Cookie
  /;

  # MyApp/Controller/Signin.pm
  sub aol : Local {
      my($self, $c) = @_;

      if ($c->authenticate_aol) {
          # login succeed
          $c->res->redirect("/");
      }

      # login failed
  }

  # in your templates
  <a href="[% c.uri_for('/signin/aol') | html %]">Sign in via AOL</a>

=head1 DESCRIPTION

Catalyst::Plugin::Authentication::Credential::AOL is a Catalyst
Authentication credential plugin for AOL OpenAuth. Since AOL does
OpenID you can just use OpenID credential, but OpenAuth gives more
granular control over authentication.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>,
L<Catalyst::Plugin::Authentication::Credential::OpenID>,
L<http://dev.aol.com/openauth>

=cut
