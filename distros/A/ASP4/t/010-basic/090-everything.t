#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

my $api = ASP4::API->new;

ok( my $res = $api->ua->get('/everything/step01.asp'), "Got res");

ok(
  $res = $api->ua->get('/handlers/dev.headers'), "Got headers res again"
);
is(
  $res->header('content-type') => 'text/x-test'
);
is(
  $res->header('content-length') => 3000
);
is(
  $res->content => "X"x3000
);

# static:
{
  ok(
    my $res = $api->ua->get('/static.txt'),
    "Got /static.txt"
  );
  is(
    $res->content => "Hello, World!\n",
    "content is correct"
  );
}

# static 404:
{
  ok(
    my $res = $api->ua->get('/missing-file.txt'),
    "Requested /missing-file.txt"
  );
  ok(
    ! $res->is_success,
    "Not successful"
  );
  like $res->status_line, qr{^404}, "Status looks like a 404 error";
}


