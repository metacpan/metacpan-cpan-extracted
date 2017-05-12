#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

BEGIN {
    eval { require Test::WWW::Mechanize::Catalyst };
    plan skip_all =>
      "This test requires Test::WWW::Mechanize::Catalyst in order to run"
      if $@;
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.40 required' if $Test::WWW::Mechanize::Catalyst::VERSION < 0.40;
    plan tests => 43;
}

use Test::WWW::Mechanize::Catalyst 'PerUserTestApp';

my $m = Test::WWW::Mechanize::Catalyst->new;
my $h = "http://localhost";

$m->get_ok("$h/show_items");
$m->content_is("");

$m->get_ok("$h/add_item/foo");

$m->get_ok("$h/show_items");
$m->content_is( "foo", "added item" );

$m->get_ok("$h/add_item/bar");

$m->get_ok("$h/show_items");
$m->content_is( join( ", ", sort qw/foo bar/ ), "added both items" );

$m->get_ok("$h/auth_login/foo");

$m->get_ok("$h/show_items");
$m->content_is( join( ", ", sort qw/foo bar/ ),
    "items still there after login" );

$m->get_ok("$h/auth_logout");

$m->get_ok("$h/show_items");
$m->content_is( "", "items gone after logout" );

$m->get_ok("$h/auth_login/foo");

$m->get_ok("$h/show_items");
$m->content_is( join( ", ", sort qw/foo bar/ ), "items restored after login" );

$m->get_ok("$h/auth_logout");

$m->get_ok("$h/auth_login/bar");

$m->get_ok("$h/add_item/gorch");

$m->get_ok("$h/auth_logout");

$m->get_ok("$h/auth_login/foo");

$m->get_ok("$h/show_items");
$m->content_is( join( ", ", sort qw/foo bar/ ),
    "items restored with intermediate other user" );

$m->get_ok("$h/auth_logout");

$m->get_ok("$h/add_item/ding");

$m->get_ok("$h/add_item/baz");

$m->get_ok("$h/show_items");
$m->content_is( join( ", ", sort qw/ding baz/ ), "new items for a guest user" );

$m->get_ok("$h/auth_login/foo");

$m->get_ok("$h/show_items");
$m->content_is(
    join( ", ", sort qw/foo bar ding baz/ ),
"session data merged, items from user session and guest session are both there"
);

$m->get_ok("$h/auth_logout");

$m->get_ok("$h/auth_login/gorch");

$m->get_ok("$h/add_item/moose");

$m->get_ok("$h/auth_logout");

$m->get_ok("$h/add_item/elk");

$m->get_ok("$h/show_items");
$m->content_is( "elk", "new items for a guest user" );

$m->get_ok("$h/auth_login/gorch");

$m->get_ok("$h/show_items");
$m->content_is( join( ", ", sort qw/elk moose/ ),
    "items merged with in-user store" );

is_deeply(
    [
        sort keys %{ PerUserTestApp->config->{authentication}{users}{gorch}
              ->get_session_data->{items}
          }
    ],
    [qw/elk moose/],
    "all items in user->session_data"
);
