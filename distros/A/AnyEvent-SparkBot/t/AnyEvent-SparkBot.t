use Modern::Perl;
use Log::LogMethods::Log4perlLogToString;
use Carp qw(confess);
use AnyEvent::Loop;
use Data::Dumper;
#BEGIN { $SIG{__DIE__} = sub { confess @_ }; }
use Test::More qw(no_plan);

my $class='AnyEvent::SparkBot';
require_ok($class);
use_ok($class);

my $string='';
my $logger=LoggerToString($class,$string);
my $token=exists $ENV{SPARK_TOKEN} ? $ENV{SPARK_TOKEN} : 'this is not a valid token';
my $self=$class->new(pingEvery=>1,logger=>$logger,token=>$token,on_message=>\&on_message);

isa_ok($self,$class);
ok($self->can('start_connection'),'check for start_connection support');

SKIP: {
  skip '$ENV{RUN_HTTP_TESTS} not true', 3 unless $ENV{RUN_HTTP_TESTS};
my $result=$self->getWsUrl;
diag $string;
$string='';
isa_ok($result,'Data::Result');

SKIP: {
  skip "$result", 1 unless $result;

  my $ws=$result->get_data->{webSocketUrl};
  ok($ws,'should have a websocket string');
  $self->start_connection($ws);

  my $t;
  LOOP_TEST:  {
    $t=AnyEvent->timer(after=>4,cb=>sub { no warnings;last LOOP_TEST });
    AnyEvent::Loop::run;
  }

  undef $t;
  ok($self->connection,'should break out of the listener loop without an ussue');
  $self->connection->close;
  
  $self=$class->new(reconnect_sleep=>0,pingEvery=>1,logger=>$logger,token=>$token,on_message=>\&on_message);
  $self->handle_reconnect;
  LOOP_TEST:  {
    $t=AnyEvent->timer(after=>10,cb=>sub { no warnings;last LOOP_TEST });
    AnyEvent::Loop::run;
  }
  undef $t;
  ok($self->connection,'should break out of the listener loop without an ussue');
  $self->connection->close;
}

}
sub on_message {
  my ($self,$json,$message)=@_;
  
}

done_testing;
