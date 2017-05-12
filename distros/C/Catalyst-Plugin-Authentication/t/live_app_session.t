use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Test::WWW::Mechanize::Catalyst; require Catalyst::Plugin::Session; require Catalyst::Plugin::Session::State::Cookie };
    plan skip_all => "This test needs Test::WWW::Mechanize::Catalyst, Catalyst::Plugin::Session and Catalyst::Plugin::Session::State::Cookie installed" if $@;
    plan skip_all => "This test needs Test::WWW::Mechanize::Catalyst >= 0.50, you have only $Test::WWW::Mechanize::Catalyst::VERSION"
        unless $Test::WWW::Mechanize::Catalyst::VERSION >= 0.50;
}

use lib 't/lib';
use Test::WWW::Mechanize::Catalyst qw/AuthSessionTestApp/; # for the cookie support

my $m = Test::WWW::Mechanize::Catalyst->new;

$m->get_ok("http://localhost/moose", "get ok");
$m->get_ok("http://localhost/elk", "get ok");

$m->get("http://localhost/yak");
ok(!$m->success, 'Not ok, user unable to be resotred == nasal demons');

foreach my $type (qw/ goat fluffy_bunny possum butterfly /) {
    $m->get_ok("http://localhost/$type", "get $type ok");
}

done_testing;

