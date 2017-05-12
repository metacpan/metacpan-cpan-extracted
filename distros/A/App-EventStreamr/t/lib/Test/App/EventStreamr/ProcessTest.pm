package Test::App::EventStreamr::ProcessTest;
use Test::More;
use Method::Signatures;
use Moo;
use namespace::clean;

has 'process' => ( is => 'rw' );
has 'config' => ( is => 'rw' );
has 'id' => ( is => 'ro' );


method run_tests() {
  TODO: {
    local $TODO = "Process tests broken with Travis" if ($ENV{TRAVIS});

    subtest 'Instantiation' => sub {
      can_ok($self->process, qw(start running stop run_stop));
    };
    
    subtest 'Run Stop Starting' => sub {
      $self->process->run_stop();
    
      is($self->process->running, 1, "Process was Started");
    };
    
    $self->config->{control}{$self->id}{run} = 2;
    subtest 'Run Stop Process Restarting' => sub {
      is($self->process->_restart, 1, "Process Expected to Restart");
      $self->process->run_stop();
       
      is($self->process->running, 0, "Process was Stopped");
      
      $self->process->run_stop();
      $self->process->run_stop();
    
      is($self->process->running, 1, "Process was Started");
    };
    
    $self->config->{run} = 0;
    
    subtest 'Run Stop System' => sub {
      $self->process->run_stop();
    
      is($self->process->running, 0, "Process was Stopped");
      
      $self->process->run_stop();
      
      $self->config->{run} = 1;
      
      $self->process->run_stop();
    
      is($self->process->running, 1, "Process was Started");
    };
    
    $self->config->{control}{$self->id}{run} = 0;
    
    subtest 'Run Stop Stopping' => sub {
      $self->process->run_stop();
    
      is($self->process->running, 0, "Process was Stopped");
    };
  }
}

1;
