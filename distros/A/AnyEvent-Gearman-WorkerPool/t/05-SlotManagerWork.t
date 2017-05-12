package main;

use lib qw( lib t/lib );
use Test::More tests=>12;
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use AnyEvent::Gearman::Client;
use AnyEvent::Gearman::WorkerPool;
use Log::Log4perl qw(:easy);
# Log::Log4perl->easy_init($DEBUG);


use Scalar::Util qw(weaken);
my $port = '9955';
my @js = ("localhost:$port");

use_ok('Gearman::Server');
gstart($port);

my $cv = AE::cv;

my $sig = AE::signal 'INT'=> sub{ 
DEBUG "TERM!!";
    $cv->send;
};

my $t = AE::timer 10,0,sub{ $cv->send('timeout')};


my $slotman = AnyEvent::Gearman::WorkerPool->new(
    config=>
    {
        global=>{
            job_servers=>\@js,
            libs=>['t/lib','./lib'],
            max=>3,
            },
        slots=>{
            'TestWorker'=>{
            min=>3, 
            max=>5,
            workleft=>10,
            }
        }
    },
);

$slotman->start();



my $c = gearman_client @js;


$cv->begin( sub{ $cv->send } );
my @tasks;
foreach (1..10 ){
    my $n = $_;
    my $str = "HELLO$n";
    $cv->begin;
    my $res = $c->add_task(
        'TestWorker::reverse'=>$str,
        on_complete=>sub{
            my $job = shift;
            my $res = shift;
            is $res,reverse($str),"check $n $res";
            $cv->end;
        },
    );
    push(@tasks, $res);
}
    
$cv->end;
    
DEBUG 'waiting...';
my $res = $cv->recv;
isnt $res,'timeout','ends successfully';
undef($tt);
$slotman->stop;
undef($slotman);

gstop();

done_testing();
