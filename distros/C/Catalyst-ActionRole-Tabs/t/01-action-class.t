#!perl

use strict;
use warnings;
use Test::More tests => 7;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
BEGIN {
    use_ok('TestApp');
}

use Catalyst::Test 'TestApp';

my ($c, $query, $resp);

$query = '/browse';
($resp, $c) = ctx_request($query);
ok($resp->header('status') == 200, "fetch $query 200 OK");
is($resp->content, 'action: browse', "content correct");
is_deeply(
    $c->stash->{tabs},
    [
	{
	    name => 'browse',
	    label => 'Browse',
	    selected => 1,
	    uri => URI->new('http://localhost/browse'),
	},
	{
	    name => 'add',
	    label => 'Add',
	    selected => '',
	    uri => URI->new('http://localhost/add'),
	},
    ],
    'tab data generated successfully'
);

$query = '/edit?id=42&other=foo';
($resp, $c) = ctx_request($query);
ok($resp->header('status') == 200, "fetch $query 200 OK");
is($resp->content, 'action: edit', "content correct");
is_deeply(
    $c->stash->{tabs},
    [
	{
	    name => 'view',
	    label => 'View',
	    selected => '',
	    uri => URI->new('http://localhost/view?id=42'),
	},
	{
	    name => 'edit',
	    label => 'Edit',
	    selected => 1,
	    uri => URI->new('http://localhost/edit?id=42'),
	},
	{
	    name => 'remove',
	    label => 'Remove',
	    selected => '',
	    uri => URI->new('http://localhost/remove?id=42'),
	},
    ],
    'tab data generated successfully'
);
