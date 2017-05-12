package App::CSE::Command::Unwatch;
$App::CSE::Command::Unwatch::VERSION = '0.012';
use Moose;
extends qw/App::CSE::Command/;
with qw/App::CSE::Role::DirIndex/;

use File::MimeInfo::Magic;


use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();


sub execute{
  my ($self) = @_;

  my $colorizer = $self->cse()->colorizer();
  my $colored = sub{ $colorizer->colored(@_);};

  my $cse = $self->cse();


  my $previous_pid = $cse->index_meta()->{'watcher.pid'};
  unless( $previous_pid ){
    $LOGGER->warn("No watcher PID in ".$cse->index_meta_file()." - nothing to do");
    return 1;
  }

  # A previous pid should be a number.
  ( $previous_pid ) = ( $previous_pid =~ /(\d+)/ );
  unless( kill(0, $previous_pid ) ){
    $LOGGER->warn(&$colored("Previous watcher (PID=".$previous_pid.") is already dead. Nothing to do",
                            "yellow bold"));
    delete $self->cse->index_meta()->{'watcher.pid'};
    delete $self->cse->index_meta()->{'watcher.start'};
    $self->cse->save_index_meta();
    return 1;
  }


  kill 15, $previous_pid;
  my $n_attempts = 4;
  my $wait_time = 1;
  while( $n_attempts-- ){
    sleep($wait_time);
    unless( kill(0 , $previous_pid ) ){
      $LOGGER->info(&$colored("Watcher PID=$previous_pid has terminated gracefully" , "green bold"));
      delete $self->cse->index_meta()->{'watcher.pid'};
      delete $self->cse->index_meta()->{'watcher.start'};
      $self->cse->save_index_meta();
      return 0;
    }
    $wait_time <<= 1;
  }

  $LOGGER->error(&$colored("PID=$previous_pid refuses to terminate gracefully. Attempting to kill 9 it", "red bold"));
  kill 9 , $previous_pid;
  return 1;
}

__PACKAGE__->meta->make_immutable();
