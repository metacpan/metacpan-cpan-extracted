package Catalyst::ActionRole::OAuth2::AuthToken::ViaRefreshToken;
use Moose::Role;
use Try::Tiny;
use CatalystX::OAuth2::Request::RefreshToken;

# ABSTRACT: Authorization token refresh provider endpoint for OAuth2 authentication flows


with 'CatalystX::OAuth2::ActionRole::Token';

sub build_oauth2_request {
  my ( $self, $controller, $c ) = @_;

  my $store = $controller->store;
  my $req;

  try {
    $req = CatalystX::OAuth2::Request::RefreshToken->new(
      %{ $c->req->query_parameters } );
    $req->store($store);
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

Catalyst::ActionRole::OAuth2::AuthToken::ViaRefreshToken - Authorization token refresh provider endpoint for OAuth2 authentication flows

=head1 VERSION

version 0.001004

=head1 SYNOPSIS

    package AuthServer::Controller::OAuth2::Provider;
    use Moose;

    BEGIN { extends 'Catalyst::Controller::ActionRole' }

    use URI;

    with 'CatalystX::OAuth2::Controller::Role::Provider';

    __PACKAGE__->config(
      store => {
        class => 'DBIC',
        client_model => 'DB::Client'
      }
    );

    sub refresh : Chained('/') Args(0) Does('OAuth2::AuthToken::ViaRefreshToken') {}

    1;

=head1 DESCRIPTION

This action role implements an endpoint that exchanges a refresh token for an
access token.

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
