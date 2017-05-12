#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
#use Test::More 'no_plan';
use Test::More;
plan skip_all => 'Test irrelevant for now';


my $s = __PACKAGE__->SUPER::new();

# Syntax error in the requested page:
{
  local $SIG{__WARN__} = sub { 0 };
  my $res = eval { $s->ua->get("/coverage/syntax-error.asp") };

  ok( ! $res->is_success, "unsuccessful" );
  ok( $res->status_line =~ m/500\s+/, "status code of 500: '" . $res->status_line . "'" );

  ok(
    $s->ua->context->server->GetLastError,
    "Error says something about a syntax error"
  );
}


# Syntax error in an included file:
{
  local $SIG{__WARN__} = sub { 0 };
  my $res = eval { $s->ua->get("/coverage/includes-syntax-error.asp") };
  
  ok( (! $res) || ( ! $res->is_success ), 'request failed' );
  if( $res )
  {
    ok( ! $res->is_success, "unsuccessful" );
    ok( $res->status_line =~ m/500\s+/, "status code of 500: '" . $res->status_line . "'" );
  }# end if()
  ok(
    $s->ua->context->server->GetLastError,
    "Error says something about a syntax error"
  );
}


# Syntax error in a master page:
{
  local $SIG{__WARN__} = sub { 0 };
  my $res = eval { $s->ua->get("/coverage/syntax-error-master.asp") };

  ok( (! $res) || ( ! $res->is_success ), 'request failed' );
  if( $res )
  {
    ok( ! $res->is_success, "unsuccessful" );
    ok( $res->status_line =~ m/500\s+/, "status code of 500: '" . $res->status_line . "'" );
  }# end if()
  ok(
    $s->ua->context->server->GetLastError,
    "Error says something about a syntax error"
  );
}


# Syntax error in a master page, but we request the child page:
{
  local $SIG{__WARN__} = sub { 0 };
  my $res = eval { $s->ua->get("/coverage/page-using-syntax-error-masterpage.asp") };

  ok( (! $res) || ( ! $res->is_success ), 'request failed' );
  if( $res )
  {
    ok( ! $res->is_success, "unsuccessful" );
    ok( $res->status_line =~ m/500\s+/, "status code of 500: '" . $res->status_line . "'" );
  }# end if()

  ok(
    $s->ua->context->server->GetLastError,
    "Error says something about a syntax error"
  );
}


# Request a page that doesn't exist.  This should *not* produce an error:
{
  my $res = eval { $s->ua->get("/non-existent-page.asp") };

  ok( (! $res) || ( ! $res->is_success ), 'request failed' );
  if( $res )
  {
    ok( ! $res->is_success, "unsuccessful" );
    ok( $res->status_line =~ m/404\s+/, "status code of 404: '" . $res->status_line . "'" );
  }# end if()

  ok(
    ! $s->ua->context->server->GetLastError,
    "No error"
  );
}

