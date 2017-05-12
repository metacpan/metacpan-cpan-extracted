
use strict;

use Test::More;    # last test to print

use lib 't/lib';
use Catalyst::Plugin::MemoryUsage;

if ( $Catalyst::Plugin::MemoryUsage::os_not_supported ) {
    plan skip_all => "os $^O is not supported";
    exit;
}

use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp');

my $x = $MyLog::mylog;  # to keep the warnings happy

$mech->get_ok('/index');

my ( $profile ) = grep { /\Q[MemoryUsage]/ } @{ $MyLog::mylog->{debug} };

ok $profile, "profile is reported";

like $profile, qr/in the middle of index/, '$c->memory_usage->record() output';

note $profile;

done_testing();

