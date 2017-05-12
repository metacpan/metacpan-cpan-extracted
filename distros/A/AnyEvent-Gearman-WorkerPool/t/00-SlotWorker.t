package main;

use lib qw( lib t/lib );
use Test::More tests=>4;
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use TestWorker;
use Log::Log4perl qw(:easy);
# Log::Log4perl->easy_init($DEBUG);

my $port = '9955';
my @js = ("localhost:$port");

my $cv = AE::cv;
my $t = AE::timer 10,0,sub{ $cv->send('timeout')};

use_ok('Gearman::Server');
gstart($port);

my $w = TestWorker->new(job_servers=>\@js, cv => AE::cv, channel=>'test');


my $c = gearman_client @js;

$cv->begin(sub{$cv->send});


$cv->begin;
$c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
    my $job = shift;
    my $res = shift;
    is $res,'OLLEH','client result ok';
    
    $cv->end;
});

$cv->begin;
$c->add_task('TestWorker::slowreverse'=>'HELLO', on_complete=>sub{
    my $job = shift;
    my $res = shift;
    is $res,'OLLEH','client result ok slow';
    
    $cv->end;
});


$cv->end;

my $res = $cv->recv;
isnt $res,'timeout','ends successfully';
undef($t);
undef($c);
gstop();


done_testing();
