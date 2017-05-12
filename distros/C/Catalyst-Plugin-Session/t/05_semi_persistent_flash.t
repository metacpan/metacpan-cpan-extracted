#!/usr/bin/perl -w
use strict;

use Test::More;

BEGIN {
    eval { require Catalyst::Plugin::Session::State::Cookie; Catalyst::Plugin::Session::State::Cookie->VERSION(0.03) }
        or plan skip_all =>
            "Catalyst::Plugin::Session::State::Cookie version 0.03 or higher is required for this test";

    eval { require Test::WWW::Mechanize::Catalyst }
      or plan skip_all =>
      'Test::WWW::Mechanize::Catalyst is required for this test';

    plan tests => '10';

}

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst 'FlashTestApp';

my $ua = Test::WWW::Mechanize::Catalyst->new;

# flash absent for initial request
$ua->get_ok( "http://localhost/first");
$ua->content_contains( "flash is not set", "not set");

# present for 1st req.
$ua->get_ok( "http://localhost/second");
$ua->content_contains( "flash set first time", "set first");

# should be the same 2nd req.
$ua->get_ok( "http://localhost/third");
$ua->content_contains( "flash set second time", "set second");

# and the third request, flash->{is_set} has the same value as 2nd.
$ua->get_ok( "http://localhost/fourth");
$ua->content_contains( "flash set 3rd time, same val as prev.", "set third");


# and should be absent again for the 4th req.
$ua->get_ok( "http://localhost/fifth");
$ua->content_contains( "flash is not", "flash has gone");

