#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
    use_ok("Catalyst::Authentication::Credential::Crowd");
    use_ok("TestApp");
}

use Test::WWW::Mechanize::Catalyst qw/TestApp/;
my $mech = Test::WWW::Mechanize::Catalyst->new;

subtest "authentication pass" => sub {
    $mech->get_ok('/auth?username=kee&password=test');
    $mech->content_contains( 'pass' );
    done_testing();
};

subtest "authentication fail" => sub {
    $mech->get_ok('/auth?username=abc&password=def');
    $mech->content_contains( 'fail' );
    done_testing();
};

subtest "app settings denial" => sub {
    $mech->get_ok('/auth?username=denied&password=def');
    $mech->content_contains( '0:0:0:0:0:1' );
};

done_testing();
