#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 41;
use Test::Exception;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/tlib";

use Icydee::MockCatalyst;
use Icydee::TestObject;

BEGIN { use_ok('Catalyst::TraitFor::Controller::Breadcrumb::Followed') };

# Create a mock Catalyst object
my $c = Icydee::MockCatalyst->new;
$c->set_action('foo');
$c->req->set_arguments('one','two');

# Object which uses the Role
my $followed = Icydee::TestObject->new;

$followed->breadcrumb_start($c,'Foo Title');

ok($c->session->{breadcrumb}, "There is a breadcrumb");
is(scalar @{$c->session->{breadcrumb}}, 1, "Array length");
my $breadcrumb = $c->session->{breadcrumb}[0];
ok($breadcrumb, "There is an array entry");
is($breadcrumb->{title}, 'Foo Title', "Correct title");
is($breadcrumb->{class}, 'current', "Correct class");
is($breadcrumb->{uri}, 'foo/one/two', "Correct URI");

# do a breadcrumb_add
$c->set_action('bar');
$c->req->set_arguments('three','4');
$followed->breadcrumb_add($c, 'Bar Title');

ok($c->session->{breadcrumb}, "There is a breadcrumb");
is(scalar @{$c->session->{breadcrumb}}, 2, "Array length");
$breadcrumb = $c->session->{breadcrumb}[0];
ok($breadcrumb, "There is an array entry");
is($breadcrumb->{title}, 'Foo Title', "Correct title");
is($breadcrumb->{class}, 'lastDone', "Correct class");
is($breadcrumb->{uri}, 'foo/one/two', "Correct URI");

$breadcrumb = $c->session->{breadcrumb}[1];
ok($breadcrumb, "There is an array entry");
is($breadcrumb->{title}, 'Bar Title', "Correct title");
is($breadcrumb->{class}, 'current', "Correct class");
is($breadcrumb->{uri}, 'bar/three/4', "Correct URI");

# do another breadcrumb_add
$c->set_action('dum');
$c->req->set_arguments('5','six');
$followed->breadcrumb_add($c, 'Dum Title');

ok($c->session->{breadcrumb}, "There is a breadcrumb");
is(scalar @{$c->session->{breadcrumb}}, 3, "Array length");
$breadcrumb = $c->session->{breadcrumb}[0];
ok($breadcrumb, "There is an array entry");
is($breadcrumb->{title}, 'Foo Title', "Correct title");
is($breadcrumb->{class}, 'done', "Correct class");
is($breadcrumb->{uri}, 'foo/one/two', "Correct URI");

$breadcrumb = $c->session->{breadcrumb}[1];
ok($breadcrumb, "There is an array entry");
is($breadcrumb->{title}, 'Bar Title', "Correct title");
is($breadcrumb->{class}, 'lastDone', "Correct class");
is($breadcrumb->{uri}, 'bar/three/4', "Correct URI");

$breadcrumb = $c->session->{breadcrumb}[2];
ok($breadcrumb, "There is an array entry");
is($breadcrumb->{title}, 'Dum Title', "Correct title");
is($breadcrumb->{class}, 'current', "Correct class");
is($breadcrumb->{uri}, 'dum/5/six', "Correct URI");

# Now set back to an earlier URI
$c->set_action('bar');
$c->req->set_arguments('three','4');
$followed->breadcrumb_add($c, 'Bar Title');

ok($c->session->{breadcrumb}, "There is a breadcrumb");
is(scalar @{$c->session->{breadcrumb}}, 2, "Array length");
$breadcrumb = $c->session->{breadcrumb}[0];
ok($breadcrumb, "There is an array entry");
is($breadcrumb->{title}, 'Foo Title', "Correct title");
is($breadcrumb->{class}, 'lastDone', "Correct class");
is($breadcrumb->{uri}, 'foo/one/two', "Correct URI");

$breadcrumb = $c->session->{breadcrumb}[1];
ok($breadcrumb, "There is an array entry");
is($breadcrumb->{title}, 'Bar Title', "Correct title");
is($breadcrumb->{class}, 'current', "Correct class");
is($breadcrumb->{uri}, 'bar/three/4', "Correct URI");

