#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
    use_ok("Catalyst::Authentication::Store::Crowd::User");
}

my $user = Catalyst::Authentication::Store::Crowd::User->new({
    info => { name => 'kee', 'display-name' => 'Kee Thiwanruk' }
});

is( $user->id, 'kee', '$user->id correct' );
is( $user->get('display-name'), 'Kee Thiwanruk', '$user->get correct' );
is( $user->get('field') ,undef , '$user->get return undef if no field in info' );

done_testing();
