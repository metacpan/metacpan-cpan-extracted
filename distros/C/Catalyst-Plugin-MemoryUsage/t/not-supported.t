use strict;
use warnings;

use lib 't/lib';
use Test::More;                      # last test to print

use Catalyst::Plugin::MemoryUsage;

if ( $Catalyst::Plugin::MemoryUsage::os_not_supported ) {
    plan skip_all => "os $^O is supported";
    exit;
}

use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp');

$mech->get_ok('/index');

done_testing();

