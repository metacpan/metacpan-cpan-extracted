#!/usr/bin/env perl
#
# This file is part of DNS-NIOS
#
# This software is Copyright (c) 2021 by Christian Segundo.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
use strictures 2;
use JSON qw(from_json);
use Mojolicious::Lite -signatures;
use Data::GUID qw( guid_string );

my $creds     = { username => "username", password => "password" };
my @records_a = ();

foreach ( 0 .. 1000 ) {
  push( @records_a, _random_record() );
}

app->log->level('error');

plugin 'basic_auth';

under sub {
  my $c = shift;
  return 1 if $c->basic_auth(
    realm => sub {
      return 1
        if "@_" eq join( " ", $creds->{username}, $creds->{password} );
    }
  );
  $c->render( template => 'AuthRequired', format => 'html', status => 401 );
  return undef; ## no critic (Subroutines::ProhibitExplicitReturnUndef)
};

group {
  under '/wapi/v2.7/record:a' => sub {
    my $c          = shift;
    my $conditions = { paging => 0 };

    my $parameters = $c->req->params->to_hash;

    if ( !$parameters->{_paging} ) {
      $conditions->{paging} = 1;
    }
    elsif ( !$parameters->{_paging}
      and $parameters->{_return_as_object} )
    {
      $conditions->{paging} = 1;
    }
    elsif ( $parameters->{_paging}
      and $parameters->{_return_as_object} )
    {
      $conditions->{paging} = 1;
    }

    $conditions->{paging} ? return 1 : $c->render(
      format   => 'json',
      template => 'Need_return_as_object',
      status   => 400
    );

    return undef; ## no critic (Subroutines::ProhibitExplicitReturnUndef)
  };

  del '/*ref' => sub {
    my $c                = shift;
    my $record_exists    = 0;
    my $record_exists_at = 0;
    foreach (@records_a) {
      if ( $_->{_ref} eq "record:a/" . $c->stash('ref') ) {
        $record_exists = 1;
        last;
      }
      $record_exists_at++;
    }

    return $c->render( text => "Not found", status => 404 ) if !$record_exists;
    splice( @records_a, $record_exists_at, 1 );
    return $c->render( text => "deleted", status => 200 );
  };

  put '/*ref' => sub {
    my $c                = shift;
    my $record_exists    = 0;
    my $record_exists_at = 0;
    foreach (@records_a) {
      if ( $_->{_ref} eq "record:a/" . $c->stash('ref') ) {
        $record_exists = 1;
        last;
      }
      $record_exists_at++;
    }

    return $c->render( text => "Not found", status => 404 ) if !$record_exists;

    foreach ( keys %{ $c->req->json } ) {
      $records_a[$record_exists_at]->{$_} = $c->req->json->{$_};
    }

    return $c->render(
      text   => "\"" . $records_a[$record_exists_at]->{_ref} . "\"",
      status => 200
    );
  };

  post q{} => sub {
    my $c = shift;
    defined $c->req->json->{$_}
      or return $c->render( text => "Bad Payload", status => 400 )
      for qw(name ipv4addr);

    foreach (@records_a) {
      return $c->render( text => "Conflict", status => 409 )
        if $_->{name} eq $c->req->json->{name};
    }

    push( @records_a, _a_record_from_payload( $c->req->json ) );
    $c->render( text => "\"" . $c->req->json->{_ref} . "\"", status => 201 );
  };

  get q{} => sub {
    my $c = shift;
    if ( !%{ $c->req->params->to_hash } and $#records_a >= 1000 ) {
      return $c->render(
        format   => 'json',
        template => 'Result_set_too_large',
        status   => 400
      );
    }
    else {
      return $c->render(
        json => {
          result => \@records_a
        },
        status => 200
      );
    }

    if (  %{ $c->req->params->to_hash }{_paging}
      and %{ $c->req->params->to_hash }{_return_as_object} )
    {
      return $c->render(
        json => {
          next_page_id => "789c55904d6ec3201046f",
          result       => \@records_a
        },
        status => 200
      );
    }
  };

};

sub _random_record {
  my $name = lc guid_string() . ".ext.home";

  my @digits;
  for ( 0 .. 3 ) {
    push @digits, int( rand(255) + 1 );
  }
  my $ipv4addr = join '.', @digits;

  return _a_record_from_payload(
    {
      name     => $name,
      ipv4addr => $ipv4addr
    }
  );
}

sub _a_record_from_payload {
  my $json_payload = shift;
  $json_payload->{_ref} =
    'record:a/' . lc guid_string() . ":$json_payload->{name}/default";
  $json_payload->{view} = "default";
  return $json_payload;
}

app->start;

__DATA__

@@ Result_set_too_large.json.ep
{
  "Error": "AdmConProtoError: Result set too large (> 1000)",
  "code": "Client.Ibap.Proto",
  "text": "Result set too large (> 1000)"
}

@@ Need_return_as_object.json.ep
{
  "Error": "AdmConProtoError: _return_as_object needs to be enabled for paging requests.",
  "code": "Client.Ibap.Proto",
  "text": "_return_as_object needs to be enabled for paging requests."
}

@@ AuthRequired.html.ep
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
  <head>
    <title>401 Authorization Required</title>
  </head>
  <body>
    <h1>Authorization Required</h1>
    <p>This server could not verify that you
    are authorized to access the document
    requested.  Either you supplied the wrong
    credentials (e.g., bad password), or your
    browser doesn't understand how to supply
    the credentials required.</p>
  </body>
</html>
