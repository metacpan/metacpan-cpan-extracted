# vim: set ft=perl :

use Test::More tests => 4;
use Test::MockObject;
use Test::MockObject::Extends;

BEGIN { use_ok('Catalyst::Plugin::UserAgent') }

my $user_agent = Test::MockObject::Extends->new('Catalyst::Plugin::UserAgent');
$user_agent->set_always(config => {
    lwp_user_agent => {
        agent => 'test-agent/1.0',
    },
});

my $ua = $user_agent->user_agent;
ok($ua);
isa_ok($ua, 'LWP::UserAgent');
is($ua->agent, 'test-agent/1.0');
