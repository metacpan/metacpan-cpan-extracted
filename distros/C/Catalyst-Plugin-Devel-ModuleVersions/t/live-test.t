#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

my $v = eval <<END;
use Catalyst::Plugin::Devel::ModuleVersions;
Catalyst::Plugin::Devel::ModuleVersions->VERSION
END


# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->{catalyst_debug} = 1;
$mech->get('http://localhost/', 'get main page');
$mech->content_like(qr/Loaded Modules/i, 'see if it has our text');

SKIP: {
    skip "No \$VERSION defined for our module, probably running with prove. Try dzil test to make sure it works", 1 unless $v;
    $mech->content_like(qr/Catalyst::Plugin::Devel::ModuleVersions $v/, 
        "see if we loaded the right version of us") or diag($mech->content);
}
