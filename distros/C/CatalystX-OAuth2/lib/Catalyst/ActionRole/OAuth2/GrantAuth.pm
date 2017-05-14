package Catalyst::ActionRole::OAuth2::GrantAuth;
use Moose::Role;
use Try::Tiny;
use CatalystX::OAuth2::Request::GrantAuth;

# ABSTRACT: Authorization grant endpoint for OAuth2 authentication flows


with 'CatalystX::OAuth2::ActionRole::Grant';

sub build_oauth2_request {
  my ( $self, $controller, $c ) = @_;

  my $store = $controller->store;
  my $req;
  try {
    $req = CatalystX::OAuth2::Request::GrantAuth->new(
      %{ $c->req->query_parameters } );
    $req->store($store);
    $req->user($c->user) if $c->user_exists;
  }
  catch {
    $c->log->error($_);

    # need to figure out a better way, but this will do for now
    $c->res->body('warning: response_type/client_id invalid or missing');

    $c->detach;
  };

  return $req;
}

1;

__END__

=pod

=head1 NAME

Catalyst::ActionRole::OAuth2::GrantAuth - Authorization grant endpoint for OAuth2 authentication flows

=head1 VERSION

version 0.001004

=head1 SYNOPSIS

    package AuthServer::Controller::OAuth2::Provider;
    use Moose;
    BEGIN { extends 'Catalyst::Controller::ActionRole' }

    with 'CatalystX::OAuth2::Controller::Role::Provider';

    __PACKAGE__->config(
      store => {
        class => 'DBIC',
        client_model => 'DB::Client'
      }
    );

    sub grant : Chained('/') Args(0) Does('OAuth2::GrantAuth') {
      my ( $self, $c ) = @_;

      my $oauth2 = $c->req->oauth2;

      $c->user_exists and $oauth2->user_is_valid(1)
        or $c->detach('/passthrulogin');
    }

=head1 DESCRIPTION

This action role implements the authorization confirmation endpoint that asks
the user if he wishes to grant resource access to the client. This is
generally done by presenting a form to the user. Regardless of the mechanism
used for this confirmation, the C<$c->req->oauth2> object must be informed of
the user's decision via the C<user_is_valid> attribute, which must be true by
the end of the request, in order for the authorization flow to be continued.

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
