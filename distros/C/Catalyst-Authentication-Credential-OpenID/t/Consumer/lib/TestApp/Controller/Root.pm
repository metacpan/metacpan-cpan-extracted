package TestApp::Controller::Root;

use strict;
use warnings;
no warnings "uninitialized";
use base 'Catalyst::Controller';
use Net::OpenID::Server;

__PACKAGE__->config->{namespace} = '';

=head1 NAME

TestApp::Controller::Root - Root Controller for TestApp.

=head1 DESCRIPTION

D'er... testing. Has an OpenID provider to test the OpenID credential against.

=cut

sub provider : Local {
    my ( $self, $c, $username ) = @_;

    my $nos = Net::OpenID::Server
        ->new(
              get_args     => $c->req->query_params,
              post_args    => $c->req->body_params,
              get_user => sub { $c->user },
              is_identity  => sub {
                  my ( $user, $identity_url ) = @_;
                  return unless $user;
                  my ( $check ) = $identity_url =~ /(\w+)\z/;
                  return $check eq $user->id; # simple auth here
              },
              is_trusted => sub {
                  my ( $user, $trust_root, $is_identity ) = @_;
                  return $is_identity; # enough that they passed is_identity
              },
              setup_url => $c->uri_for($c->req->path, {moo => "setup"}),
              server_secret => $c->config->{startup_time},
              );

  # From your OpenID server endpoint:

    my ( $type, $data ) = $nos->handle_page;

    if ($type eq "redirect")
    {
        $c->res->redirect($data);
    }
    elsif ($type eq "setup")
    {
        my %setup_opts = %{$data};
        $c->res->body(<<"");
You're not signed in so you can't be verified.
<a href="/login">Sign in</a> | <a href="/signin_openid">OpenId</a>.

      # it's then your job to redirect them at the end to "return_to"
      # (or whatever you've named it in setup_map)
    }
    else
    {
        $c->res->content_type($type);
        if ( $username )
        {
            my $server_uri = $c->uri_for($c->req->path);
            $data =~ s,(?=</head>),<link rel="openid.server" href="$server_uri" />,;
        }
        $c->res->body($data);
    }
}

sub logout : Local {
    my($self, $c) = @_;
    $c->logout if $c->user_exists;
    $c->delete_session();
    $c->res->redirect($c->uri_for("/"));
}

sub login : Local {
    my($self, $c) = @_;

    if ( $c->req->method eq 'POST'
         and
         $c->authenticate({ username => $c->req->body_params->{username},
                            password => $c->req->body_params->{password} }) )
    {
#        $c->res->body("You are signed in!");
        $c->res->redirect($c->uri_for("/"));
    }
    else
    {
        my $action = $c->req->uri->path;
        $c->res->body(<<"");
<html><head/><body><form name="login" action="$action" method="POST">
  <input type="text" name="username" />
  <input type="password" name="password" />
  <input type="submit" value="Sign in" />
</form>
</body></html>

    }
}

sub signin_openid : Local {
    my($self, $c) = @_;

    if ( $c->authenticate({}, "openid") )
    {
        $c->res->body("You did it with OpenID!");
    }
    else
    {
        my $action = $c->req->uri->path;
        $c->res->body(<<"");
 <form action="$action" method="GET" name="openid">
  <input type="text" name="openid_identifier" class="openid" size="50" />
  <input type="submit" value="Sign in with OpenID" />
  </form>

    }
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->response->body(
                       join(" ",
                            "You are",
                            $c->user ? "" : "not",
                            "signed in. <br/>",
                            $c->user ? ( $c->user->id || %{$c->user} ) : '<a href="/login">Sign in</a> | <a href="/signin_openid">OpenId</a>.'
                            )
                       );
}

sub end : Private {
    my ( $self, $c ) = @_;
    $c->response->content_type("text/html");
}

=head1 LICENSE

This library is free software, you can redistribute it and modify
it under the same terms as Perl itself.

=cut

1;
