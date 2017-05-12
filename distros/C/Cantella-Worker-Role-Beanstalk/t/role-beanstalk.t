
use strict;
use warnings;
use Test::Most qw(defer_plan die);
use Log::Dispatch;
use Beanstalk::Client;

BEGIN {
  use_ok('Cantella::Worker::Role::Beanstalk');
}

{
  package TestCantellaWorkerBeanstalk;

  use Moose;
  with(
    'Cantella::Worker::Role::Worker',
    'Cantella::Worker::Role::Beanstalk'
  );

  around get_work => sub {
    my $orig = shift;
    my $self = shift;
    my $job = $self->$orig(@_);
    $self->shutdown unless defined $job;
    return $job;
  };

  sub work {
    my ($self, $job) = @_;
    my ($name) = $job->args;
    if( $name eq 'fail'){
      $job->release;
    } elsif( $name =~ /pass/) {
      if(my $x = $job->delete){
        $self->logger->notice("DOING $name\n");
      } else {
        my $id = $job->id;
        my $err_msg = $job->error;
        $self->logger->error("FAILED TO DELETE: $id: '$err_msg'");
      }
    }
  }
}

unless ( defined $ENV{'TEST_BEANSTALK_HOST'} ){
  diag "Can't test unless the BEANSTALK_HOST variables is set";
  all_done(1);
  exit;
}

my $tube_name = exists $ENV{'TEST_BEANSTALK_TUBE'} ? $ENV{'TEST_BEANSTALK_TUBE'} : 'test-cantella-worker';

my $client = Beanstalk::Client->new({
  server => $ENV{'TEST_BEANSTALK_HOST'},
  default_tube => $tube_name,
});

{
  my %jobs = map { $_, $client->put({}, $_)->id}
    qw/pass1 pass2 pass3 fail pass4 pass5 pass6/;
  my( @notice_messages, @error_messages);
  my $logger = Log::Dispatch->new(
    outputs => [
      [ Array => ( min_level => 'notice', max_level => 'notice', array => \@notice_messages) ],
      [ Array => ( min_level => 'error', max_level => 'error', array => \@error_messages) ],
    ]
  );

  lives_ok {
    my $worker = TestCantellaWorkerBeanstalk->new(
      logger => $logger,
      interval => 1,
      beanstalk_clients => [ $client ],
      reserve_timeout => 1,
      max_tries => 4,
    );
    $worker->start;
  } 'instantiate';

  is_deeply(\@error_messages, [], 'no errors');
  @notice_messages = map {$_->{message}} @notice_messages;
  my $bury =grep { /Job exceeds max-tries. Burying job $jobs{fail} from tube '${tube_name}' with args: 'fail'/ } @notice_messages;
  ok($bury, 'job buried');
  my $stats = $client->stats_job($jobs{fail});
  is($stats->state, 'buried', 'job really buried');
  is($stats->reserves, 5, 'correct reserve number'); #4 + 1 (where it got buried)
}

{
  my %jobs = map { $_, $client->put({}, $_)->id}
    qw/pass1 pass2 pass3 fail pass4 pass5 pass6/;
  my( @notice_messages, @error_messages);
  my $logger = Log::Dispatch->new(
    outputs => [
      [ Array => ( min_level => 'notice', max_level => 'notice', array => \@notice_messages) ],
      [ Array => ( min_level => 'error', max_level => 'error', array => \@error_messages) ],
    ]
  );
  my $worker = TestCantellaWorkerBeanstalk->new(
    logger => $logger,
    interval => 1,
    beanstalk_clients => [ $client ],
    delete_on_max_tries => 1,
    reserve_timeout => 1,
    max_tries => 4,
  );
  $worker->start;

  is_deeply(\@error_messages, [], 'no errors');
  @notice_messages = map {$_->{message}} @notice_messages;
  my $deleted = grep { /Job exceeds max-tries. Deleting job $jobs{fail} from tube '${tube_name}' with args: 'fail'/ } @notice_messages;
  ok($deleted, 'job deleted');
  my $stats = $client->stats_job($jobs{fail});
  ok(!defined($stats), 'job really deleted');
}

all_done(9);
