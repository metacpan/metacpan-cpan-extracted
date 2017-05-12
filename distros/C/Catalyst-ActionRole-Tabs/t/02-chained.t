#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 10;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
BEGIN {
    use_ok('TestChained');
}

use Catalyst::Test 'TestChained';

my ($c, $expect, $query, $resp);

$query = '/test';
($resp, $c) = ctx_request($query);
ok($resp->header('status') == 200, "fetch $query 200 OK");
$expect = 'root-browse';
is($resp->content, $expect, "content correct: $expect");
is_deeply(
    $c->stash->{tabs},
    [
	{
	    name => 'browse',
	    label => 'Browse',
	    selected => 1,
	    uri => URI->new('http://localhost/test'),
	},
	{
	    name => 'add',
	    label => 'Add',
	    selected => '',
	    uri => URI->new('http://localhost/test/add'),
	},
    ],
    'tab data generated successfully'
);

$query = '/test/id/1337/edit';
($resp, $c) = ctx_request($query);
ok($resp->header('status') == 200, "fetch $query 200 OK");
$expect = 'root-id-edit';
is($resp->content, $expect, "content correct: $expect");
is_deeply(
    $c->stash->{tabs},
    [
	{
	    name => 'view',
	    label => 'View',
	    selected => '',
	    uri => URI->new('http://localhost/test/id/1337'),
	},
	{
	    name => 'edit',
	    label => 'Edit',
	    selected => 1,
	    uri => URI->new('http://localhost/test/id/1337/edit'),
	},
	{
	    name => 'remove',
	    label => 'Remove',
	    selected => '',
	    uri => URI->new('http://localhost/test/id/1337/remove'),
	},
    ],
    'tab data generated successfully'
);

$query = '/test/id/1337/update';
($resp, $c) = ctx_request($query);
ok($resp->header('status') == 200, "fetch $query 200 OK");
$expect = 'root-id-update';
is($resp->content, $expect, "content correct: $expect");
is_deeply(
    $c->stash->{tabs},
    [
	{
	    name => 'view',
	    label => 'View',
	    selected => '',
	    uri => URI->new('http://localhost/test/id/1337'),
	},
	{
	    name => 'edit',
	    label => 'Edit',
	    selected => 1,
	    alias => 'update',
	    uri => URI->new('http://localhost/test/id/1337/edit'),
	},
	{
	    name => 'remove',
	    label => 'Remove',
	    selected => '',
	    uri => URI->new('http://localhost/test/id/1337/remove'),
	},
    ],
    'tab data generated successfully'
);

