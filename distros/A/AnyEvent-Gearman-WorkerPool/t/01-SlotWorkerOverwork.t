package main;

use lib qw( lib t/lib );
use Test::More tests=>3;
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

my $w = TestWorker->new(job_servers=>\@js,cv=>AE::cv,boss_channel=>'', channel=>'test',workleft=>2);


my $c = gearman_client @js;

$cv->begin(sub{
    DEBUG 'group done';
    $cv->send});

$cv->begin;
my $task1 = $c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
    my $job = shift;
    my $res = shift;
    is $res,'OLLEH','client result ok 1';
    DEBUG '1';
    $cv->end;
});

$cv->begin;
my $task2 = $c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
    my $job = shift;
    my $res = shift;

    is $res,'OLLEH','client result ok 2';
    DEBUG '2';
    $cv->end;
});

$cv->end;

my $res = $cv->recv;

undef($t);
undef($c);
gstop();


done_testing();
