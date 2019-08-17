use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

$ENV{CALLBACKERY_CONF} = $FindBin::Bin.'/callbackery.cfg';

my $t = Test::Mojo->new('CallBackery');

$t->app->log->on(message => sub { 
    my ($log, $level, @lines) = @_;
    if ($ENV{CALLBACKERY_RPC_LOG}){
       if ($lines[0] =~ /CALL|RETURN/){
          like($lines[0],qr{UnknowUser});
       }
    }
});


for (1..2){
    $t->post_ok('/QX-JSON-RPC' => json => { id => 1, service => 'default', method => 'ping'} )
      ->status_is(200)
      ->content_type_is('application/json; charset=utf-8')
      ->json_is({id => 1,result => "pong"});

    $t->get_ok('/doc')
      ->content_like('/CallBackery::Index/')
      ->status_is(200);
    $ENV{CALLBACKERY_RPC_LOG}=1;
}
$ENV{CALLBACKERY_RPC_LOG}=0;

my $c = p1->new;

my $data = {
    k => { lalala => '123' }
};

$c->dataCleaner($data);

is ($data->{k}{lalala},'xxx','pass clean check');

my $login = ['tobi','secret'];
$c->dataCleaner($login,'login');
is ($login->[1],'xxx','pass special login check');

done_testing();
1;


package p1;
use Mojo::Base qw(CallBackery::Controller::RpcService);
sub passMatch {
    qr{lalala};
};
1;
