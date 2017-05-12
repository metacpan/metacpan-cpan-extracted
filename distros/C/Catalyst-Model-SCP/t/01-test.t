use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 1;
use Test::WWW::Mechanize::Catalyst;

# go to the home page
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp');
$mech->get_ok('/');


