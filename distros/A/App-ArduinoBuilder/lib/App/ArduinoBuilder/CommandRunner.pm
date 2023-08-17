package App::ArduinoBuilder::CommandRunner;

use strict;
use warnings;
use utf8;

use App::ArduinoBuilder::Logger ':all_logger';
use Data::Dumper;
use Exporter 'import';
use POSIX ':sys_wait_h';
use Time::HiRes 'usleep';

our @EXPORT_OK = qw(default_runner);
our @EXPORT = @EXPORT_OK;

my %children;

package App::ArduinoBuilder::CommandRunner::Task {
  use App::ArduinoBuilder::Logger ':all_logger';
  use Time::HiRes 'usleep';

  sub new {
    my ($class, %data) = @_;
    return bless {%data}, $class;
  }

  sub data {
    my ($this) = @_;
    fatal "Trying to read the data of a still running task" if $this->running();
    die $this->{error} if exists $this->{error};
    # TODO: we should have a variant for undef wantarray that does not setup
    # the whole pipe to get the return data.
    # Note: wantarray here is not necessarily the same as when the task was set
    # up, it is the responsibility of the caller to set the 'scalar' option
    # correctly.
    return wantarray ? @{$this->{data}} : $this->{data}[0];
  }

  sub running {
    my ($this) = @_;
    return $this->{running};
  }

  sub wait {
    my ($this) = @_;
    usleep(1000) while $this->{running};
    return;
  }

  sub pid {
    my ($this) = @_;
    return $this->{pid};
  }
}

$SIG{CHLD} = sub {
  local ($!, $?);
  while( (my $pid = waitpid( -1, &WNOHANG)) > 0 ) {
    my $task = delete $children{$pid};
    unless (defined $task) {
      full_debug "Got SIGCHLD for unknown children with pid == ${pid}";
      return;
    }
    $task->{runner}{current_tasks}-- unless $task->{untracked};
    if ($?) {
      if ($task->{catch_error}) {
        $task->{error} = "Child command failed: $?";
      } else {
        debug "Child process (pid == ${pid}) failed, waiting for all other child processes";
        undef while wait() != -1;
        fatal 'Child command failed';
      }
    } elsif ($task->{channel}) {
      local $/;
      my $fh = $task->{channel};
      my $data = <$fh>;
      close $fh;
      no warnings;
      no strict;
      $task->{data} = eval $data;
      fatal "Cannot parse the output of child task $task->{task_id} (pid == ${pid}): $@" if $@;
    }
    $task->{running} = 0;
    full_debug "Child pid == ${pid} returned (task id == $task->{task_id}) --> current tasks == $task->{runner}{current_tasks}";
  }
};

sub new {
  my ($class, %options) = @_;
  my $this =
    bless {
      max_parallel_tasks => $options{max_parallel_tasks} // 1,
      parallelize => $options{parallelize} // 1,
      current_tasks => 0,
    }, $class;
  return $this;
}

my $default_runner = App::ArduinoBuilder::CommandRunner->new();
sub default_runner {
  return $default_runner;
}

my $task_count = 0;

sub _fork_and_run {
  my ($this, $sub, %options) = @_;
  %options = (%{$this}, %options);
  pipe my $tracker_i, my $tracker_o;  # From the parent to the child.
  pipe my $response_i, my $response_o;  # From the child to the parent.
  my $task_id = $task_count++;
  my $pid = CORE::fork();
  $this->{current_tasks}++ unless $options{untracked};
  fatal "Cannot fork a sub-process" unless defined $pid;

  if ($pid == 0) {
    $SIG{CHLD} = 'DEFAULT';
    if (exists $options{SIG}) {
      while (my ($k, $v) = each %{$options{SIG}}) {
        $SIG{$k} = $v;
      }
      print $response_o "ready\n";
      $response_o->flush();
    }

    # In the child task
    close $tracker_o;
    close $response_i;
    full_debug "Starting child task (id == ${task_id}) in process ${$}";
    my @out;
    if ($options{scalar}) {
      @out = scalar($sub->());
    } else {
      @out = $sub->();
    }
    my $serialized_out;
    {
      local $Data::Dumper::Indent = 0;
      local $Data::Dumper::Purity = 1;
      local $Data::Dumper::Sparseseen = 1;
      local $Data::Dumper::Varname = 'ARDUINOBUILDERVAR';
      $serialized_out = Dumper(\@out);
    }
    my $size = length($serialized_out);
    my $max_size = 4096;  # This is a very conservative estimates. On modern system the limit is 64kB.
    warning "Data returned by process ${$} for task ${task_id} is too large (%dB)", $size if $size > $max_size;
    # Nothing will be read before the process terminate, so the data
    print $response_o scalar(Dumper(\@out));
    # This is used to not finish the task before the children data-structure
    # was written by the parent (in which case our SIGCHLD handler could not
    # correctly track this task).
    # Ideally this should be done before running the sub, in case it never
    # returns (call exec) but, in practice it probably does not matter.
    scalar(<$tracker_i>);
    close $tracker_i;
    full_debug "Exiting child task (id == ${task_id}) in process ${$}";
    exit 0;
  }

  # Still in the parent task
  full_debug "Started child task (id == ${task_id}) with pid == ${pid}";
  close $tracker_i;
  close $response_o;
  my $task = App::ArduinoBuilder::CommandRunner::Task->new(
    untracked => $options{untracked},
    task_id => $task_id,
    runner => $this,
    running => 1,
    channel => $response_i,
    pid => $pid,
    catch_error => $options{catch_error},
  );
  $children{$pid} = $task;
  if (exists $options{SIG}) {
    my $ready = <$response_i>;
    die "Got unexpected data during ready check: $ready" unless $ready eq "ready\n";
  }
  print $tracker_o "ignored\n";
  close $tracker_o;
  if ($options{wait}) {
    full_debug "Waiting for child $pid to exit (task id == ${task_id})";
    $task->wait();
    full_debug "Ok, child $pid exited (task id == ${task_id})";
  }
  return $task;
}

# Same as execute but does not limit the parallelism and block until the command
# has executed.
sub run_forked {
  my ($this, $sub, %options) = @_;
  $options{scalar} = 1 unless exists $options{scalar} || wantarray;
  my $task = $this->_fork_and_run($sub, %options, untracked => 1, wait => 1);
  return $task->data();
}

sub execute {
  my ($this, $sub, %options) = @_;
  %options = (%{$this}, %options);
  if (!$options{forced}) {
    usleep(1000) until $this->{current_tasks} < $this->{max_parallel_tasks};
  }
  return $this->_fork_and_run($sub, %options);
}

sub wait {
  my ($this) = @_;
  my $c = $this->{current_tasks};
  return unless $c;
  debug "Waiting for ${c} running tasks...";
  usleep(1000) until $this->{current_tasks} == 0;
}

sub set_max_parallel_tasks {
  my ($this, $max_parallel_tasks) = @_;
  $this->{max_parallel_tasks} = $max_parallel_tasks;
}

1;
