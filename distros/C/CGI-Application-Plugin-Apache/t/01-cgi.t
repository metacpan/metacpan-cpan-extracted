use Test::More;
use strict;
use lib './t/lib';
plan(tests => 3);
 
# 1..2
require_ok('CGI::Application::Plugin::Apache');
require_ok('ApachePlugin::CGI');
 
# 3
{
    my $app = ApachePlugin::CGI->new();
    eval {$app->handler() };
    like($@, qr/Can't locate object method "handler"/, 'simple: not using m_p');
}
 

