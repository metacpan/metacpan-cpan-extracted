use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/../example/lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

$ENV{CALLBACKERY_CONF} = $FindBin::Bin.'/callbackery.cfg';

my $t = Test::Mojo->new('CallBackery');

my %lastMsg;
$t->app->log->on(message => sub { 
    my ($log, $level, @lines) = @_;
    my $line = join '', @lines;
    # diag $line;
    if ($ENV{CALLBACKERY_RPC_LOG}){
       if ($line =~ /(CALL|RETURN)/){
          $lastMsg{$1} = $line;
       }
    }
});

$ENV{CALLBACKERY_RPC_LOG}=0;
for (1..2){
    %lastMsg = ();

    $t->post_ok('/QX-JSON-RPC' => json => { id => 1, service => 'default', method => 'ping'} )
      ->status_is(200)
      ->content_type_is('application/json; charset=utf-8')
      ->json_is({id => 1,result => "pong"});

    if ($ENV{CALLBACKERY_RPC_LOG}) {
        is($lastMsg{CALL},'[*UNKNOWN*|127.0.0.1] CALL ping([])');
        is($lastMsg{RETURN},'[*UNKNOWN*|127.0.0.1] RETURN {"id":1,"result":"pong"}');
    }

    $t->get_ok('/doc')
      ->content_like('/CallBackery::Index/')
      ->status_is(200);
    $ENV{CALLBACKERY_RPC_LOG}=1;
    $t->app->log->level('info');
}

done_testing();
