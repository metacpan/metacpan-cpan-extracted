use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/../example/lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

$ENV{CALLBACKERY_CONF} = $FindBin::Bin.'/callbackery.cfg';

my $t = Test::Mojo->new('CallBackery');

$t->post_ok('/QX-JSON-RPC' => json => { id => 1, service => 'default', method => 'ping'} )
  ->status_is(200)
  ->content_type_is('application/json; charset=utf-8')
  ->json_is({id => 1,result => "pong"});

$t->get_ok('/doc')
  ->content_like('/CallBackery::Index/')
  ->status_is(200);

done_testing();
