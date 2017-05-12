package Bio::Grid::Run::SGE::Log::Analysis;

use Mouse;

use warnings;
use strict;
use Carp;
use File::Spec::Functions qw/catfile/;
use Bio::Gonzales::Util::File qw/slurpc open_on_demand/;
use Bio::Grid::Run::SGE::Util qw/my_glob MSG/;
use Bio::Grid::Run::SGE::Log::Worker;
use Bio::Grid::Run::SGE::Log::Notify::Jabber;
use Bio::Grid::Run::SGE::Log::Notify::Mail;
use Bio::Grid::Run::SGE::Config;
use Bio::Gonzales::Util::Cerial;
use Path::Tiny;

use Sys::Hostname;

our $VERSION = '0.042'; # VERSION

has config_file         => ( is => 'rw', required   => 1 );
has c                   => ( is => 'rw', required   => 1 );
has failed_restart_file => ( is => 'rw', lazy_build => 1 );
has failed_log_file     => ( is => 'rw', lazy_build => 1 );
has failed_update_file  => ( is => 'rw', lazy_build => 1 );
has attempts            => ( is => 'rw', lazy_build => 1 );
has _log                => ( is => 'rw', default    => sub { [] } );
has _node_log           => ( is => 'rw', default    => sub { [] } );
has _cmd_script         => ( is => 'rw', default    => sub { [] } );
has num_jobs            => ( is => 'rw', default    => 0 );
has num_jobs_skipped    => ( is => 'rw', default    => 0 );
has num_jobs_failed     => ( is => 'rw', default    => 0 );

sub _build_failed_update_file {
  my ($self) = @_;

  my ( $tmp_dir, $job_name, $job_id ) = @{ $self->c }{qw/tmp_dir job_name job_id/};
  my $update_log_file = catfile( $tmp_dir, "update.$job_name.j$job_id.sh" );
  return $update_log_file;
}

sub _build_failed_log_file {
  my ($self) = @_;

  my ( $tmp_dir, $job_name, $job_id ) = @{ $self->c }{qw/tmp_dir job_name job_id/};
  my $failed_log_file = catfile( $tmp_dir, "log.$job_name.j$job_id.txt" );

  return $failed_log_file;
}

sub _build_failed_restart_file {
  my ($self) = @_;

  my ( $tmp_dir, $job_name, $job_id ) = @{ $self->c }{qw/tmp_dir job_name job_id/};
  my $failed_restart_file = catfile( $tmp_dir, "restart.$job_name.j$job_id.sh" );

  return $failed_restart_file;
}

sub _build_attempts {
  my ($self) = @_;
  return $self->c->{notification_attempts} // 3;
}

sub _report_log {
  my $self = shift;
  push @{ $self->_log }, @_;
  return;
}

sub _report_node_log {
  my $self = shift;
  push @{ $self->_node_log }, @_;
  return;
}

sub _report_cmd {
  my $self = shift;
  push @{ $self->_cmd_script }, @_;
  return;
}

sub analyse {
  my ($self) = @_;

  MSG("Creating node log.");

  my $c           = $self->c;
  my $config_file = $self->config_file;
  my $job_name    = $c->{job_name};
  my $job_id      = $c->{job_id};

  my $log_dir = my_glob( $c->{log_dir} );

  my $something_crashed;
  my $num_skipped = 0;

  $self->_report_log( 'main log file: ' . $self->failed_log_file, '' );

  $self->_report_log( 'restart failed jobs: ' . $self->failed_restart_file );
  $self->_report_log( 'update job states: ' . $self->failed_update_file, '' );

  $self->_report_log( 'working dir: ' . $c->{working_dir} );
  $self->_report_log( 'result dir: ' . $c->{result_dir} );
  $self->_report_log( 'tmp dir: ' . $c->{tmp_dir}, '' );

  my %jobs_with_log;

  my $file_regex = qr/$job_name\.l$job_id\.\d+/;
  my @files      = path($log_dir)->children($file_regex);
  my $STD_JOB_CMD;
  my $STD_WORKER_WD;
  my %err_hosts;
  for my $log_file (@files) {
    my $log_data = Bio::Grid::Run::SGE::Log::Worker->new( log_file => $log_file )->log_data;

    # we cannot read the log file, skip report. these jobs will be taken care of further down
    unless ($log_data) {
      $self->_report_log("ERROR: could not parse log_file $log_file");
      next;
    }

    ( my $range = $log_data->{range} ) =~ s/[()]//g;

    # we cannot read the log file, skip report. these jobs will be taken care of further down
    unless ( $log_data->{job_cmd} && exists( $log_data->{id} ) ) {
      $self->_report_log("ERROR: could not parse log_file $log_file");
      next;
    }

    # collect jobs that have a basic log
    $jobs_with_log{ $log_data->{id} } = 1;

    ( my $job_cmd = $log_data->{job_cmd} ) =~ s/-t\s+\d+-\d+\s+//;
    $STD_JOB_CMD   = $job_cmd         unless defined $STD_JOB_CMD;
    $STD_WORKER_WD = $log_data->{cwd} unless defined $STD_WORKER_WD;

    #check for successful excecution message at the last line of the worker log
    unless ( $log_data->{'comp.end'} ) {
      #this node crashed, no end msg
      #restart the whole thing
      $something_crashed++;
      $self->_report_crashed_job(
        $log_data,
        {
          log_file => catfile( $log_dir, $log_file ),
          job_cmd  => $job_cmd,
          range    => $range,
          job_id   => $job_id,
          err_file => $log_data->{err},
          out_file => $log_data->{out},
        }
      );
      # track which nodes broke, often one specific node always breaks
      $err_hosts{ $log_data->{hostname} }++;
    } elsif ( exists( $log_data->{'comp.task.exit.error'} ) ) {
      #at least one task had an error but the worker itself survived
      $something_crashed++;
      $self->_report_error_job(
        $log_data,
        {
          log_file => catfile( $log_dir, $log_file ),
          job_cmd  => $job_cmd,
          job_id   => $job_id,
          err_file => $log_data->{err},
          out_file => $log_data->{out},
        }
      );
      # track which nodes broke, often one specific node always breaks
      $err_hosts{ $log_data->{hostname} }++;
    } elsif ( exists( $log_data->{'comp.task.exit.skip'} ) ) {
      $num_skipped++;
    }
  }

  my $no_jobs_ran_at_all;
  my $num_jobs = 'n/a';
  if ( exists( $c->{range} ) ) {
    $num_jobs = $c->{range}[1] - $c->{range}[0] + 1;
  MISSING_JOBS:
    for ( my $i = $c->{range}[0]; $i <= $c->{range}[1]; $i++ ) {
      unless ( exists( $jobs_with_log{$i} ) ) {
        $something_crashed++;
        if ( $STD_JOB_CMD && $STD_WORKER_WD ) {
          $self->_report_missing_job(
            {
              job_cmd => $STD_JOB_CMD,
              job_id  => $job_id,
              id      => $i,
              cwd     => $STD_WORKER_WD,
            }
          );
          $err_hosts{NA}++;
        } else {
          $no_jobs_ran_at_all = 1;
          $err_hosts{NA} = $num_jobs;
          last MISSING_JOBS;
        }
      }
    }
  }

  $self->num_jobs($num_jobs);
  $self->num_jobs_skipped($num_skipped);

  $self->_report_log( ( $num_jobs || 'n/a' ) . " jobs in total" );
  $self->_report_log( '(' . $num_skipped . " jobs did not need to run again)" ) if ($num_skipped);
  if ($no_jobs_ran_at_all) {
    $self->_report_log("obviously, no jobs were run at all");
    $self->num_jobs_failed($num_jobs);
  } elsif ($something_crashed) {
    # create a log entry with the hostnames and the number of times crashed.
    # often one node has all crashes and with this you can spot it easily in the log file.
    my @err_host_names = keys %err_hosts;

    @err_host_names = sort { $err_hosts{$b} <=> $err_hosts{$a} } @err_host_names;
    my @log_entries     = ("Failed hosts:");
    my $num_jobs_failed = 0;
    for my $h (@err_host_names) {
      $num_jobs_failed += $err_hosts{$h};
      push @log_entries, sprintf( "   %3d %s", $err_hosts{$h}, $h );
    }

    $self->_report_log( sprintf( "Jobs failed: %s of %s", $num_jobs_failed, $num_jobs ) );
    $self->num_jobs_failed($num_jobs_failed);

    $self->_report_log(@log_entries);
  } else {
    $self->_report_log('all nodes finished successfully');
  }

  return;
}

sub _report_crashed_job {
  my ( $self, $log_data, $s ) = @_;

  $self->_report_cmd("#NODE: $log_data->{id}; LOG: $s->{log_file}");
  #replace job array numbers with worker id, to emulate the environment of the original array job

  $self->_report_cmd(
    "cd '$log_data->{cwd}' && $s->{job_cmd} --range $s->{range} --job_id $s->{job_id} --id $log_data->{id}");
  $self->_report_node_log( "Node " . $log_data->{id} . " crashed" );
  $self->_report_node_log("    log: $s->{log_file}");
  $self->_report_node_log("    err: $s->{err_file}");
  $self->_report_node_log("    out: $s->{out_file}");

  return;
}

sub _report_missing_job {
  my ( $self, $s ) = @_;

  $self->_report_cmd("#NODE: $s->{id}; NO_LOG");
  #replace job array numbers with worker id, to emulate the environment of the original array job

  $self->_report_cmd("cd '$s->{cwd}' && $s->{job_cmd} --job_id $s->{job_id} --id $s->{id}");
  $self->_report_node_log( "Node " . $s->{id} . " crashed, NO_LOG NO_ERR NO_OUT" );

  return;
}

sub _report_error_job {
  my ( $self, $log_data, $s ) = @_;

  $self->_report_cmd("#NODE: $log_data->{id}; LOG: $s->{log_file}");

  for my $t ( @{ $log_data->{'comp.task.exit.error'} } ) {
    my ( $task_id, $files ) = split /\s/, $t, 2;

    $self->_report_cmd(
      "cd '$log_data->{cwd}' && $s->{job_cmd} --range $task_id --job_id $s->{job_id} --id $log_data->{id}");
    $self->_report_node_log( "Node " . $log_data->{id} . " had error(s)" );
    $self->_report_node_log("    log: $s->{log_file}");
    $self->_report_node_log("    err: $s->{err_file}");
    $self->_report_node_log("    out: $s->{out_file}");
  }
  return;
}

sub notify {
  my ($self) = @_;
  my $c = $self->c;

  # reread config and merge it to get the passwords for the notify stuff
  $c = { %{ Bio::Grid::Run::SGE::Config->new->config }, %$c };
  return unless ( $c->{notify} );

  my %info = (
    subject => '[LOG]' . $self->subject(),
    message => $self->gen_report,
    from    => $self->from_address(),
  );

  if ( $c->{notify}{mail} ) {
    $c->{notify}{mail} = [ $c->{notify}{mail} ] unless ( ref $c->{notify}{mail} );
    for my $mail ( @{ $c->{notify}{mail} } ) {
      my $n = Bio::Grid::Run::SGE::Log::Notify::Mail->new($mail);
      for ( my $i = 0; $i < $self->attempts; $i++ ) {
        # notify function returns 1 on error. If this happens, try more times
        last unless ( $n->notify( \%info ) );
      }
    }
  }
  if ( $c->{notify}{jabber} ) {
    $c->{notify}{jabber} = [ $c->{notify}{jabber} ] unless ( ref $c->{notify}{jabber} );
    for my $jid ( @{ $c->{notify}{jabber} } ) {
      my $n = Bio::Grid::Run::SGE::Log::Notify::Jabber->new($jid);
      for ( my $i = 0; $i < $self->attempts; $i++ ) {
        # notify function returns 1 on error. If this happens, try more times
        last unless ( $n->notify( \%info ) );
      }
    }
  }
  if ( $c->{notify}{script} ) {
    my $bin = $c->{notify}{script};
    if ( -x $bin ) {
      open my $fh, '|-', $bin or die "Can't pipe to script >> $bin <<: $!";
      say $fh jfreeze( \%info );
      close $fh;
    }
  }

  return;
}

sub subject {
  my $self = shift;
  my $c    = $self->c;

  return
      '['
    . localtime . ']['
    . $c->{job_id} . ']['
    . $self->log_status . '] '
    . $c->{job_name} . ' ('
    . $self->from_address() . ')';
}

sub log_status {
  my ($self) = @_;

  my $status;
  if ( !$self->num_jobs || $self->num_jobs_failed == $self->num_jobs ) {
    $status = 'ALL ERR';
  } elsif ( $self->num_jobs_failed ) {
    $status = $self->num_jobs_failed . '/' . $self->num_jobs . ' ERR';
  } else {
    $status = 'ALL OK';
  }

  return $status;
}

sub from_address {
  return $ENV{SGE_O_LOGNAME} && $ENV{SGE_O_HOST}
    ? join( '@', $ENV{SGE_O_LOGNAME}, $ENV{SGE_O_HOST} )
    : join( '@', $ENV{USER}, ( $ENV{HOSTNAME} || hostname() ) );
}

sub gen_report {
  my ( $self, $full ) = @_;
  my @node_report = @{ $self->_node_log };
  @node_report = ( @node_report[ 0 .. 13 ], '...' ) if ( @node_report > 17 && !$full );
  return join( "\n", $self->subject(), '', @{ $self->_log }, '', @node_report ) . "\n";
}

sub restart_script {
  my ($self) = @_;
  return join( "\n", @{ $self->_cmd_script } ) . "\n";
}

sub write {
  my ($self) = @_;

  my $cmd_f = $self->failed_restart_file;

  open my $cmd_fh, '>', $cmd_f or confess "Can't open filehandle: $!";
  print $cmd_fh $self->restart_script;
  $cmd_fh->close;

  chmod 0755, $cmd_f;

  my $log_f = $self->failed_log_file;

  open my $log_fh, '>', $log_f or confess "Can't open filehandle: $!";

  print $log_fh $self->gen_report(1);
  $log_fh->close;

  #CREATE SCRIPT TO UPDATE RERUN JOBS
  $self->_write_update_script;

}

sub _write_update_script {
  my ($self) = @_;

  my $c = $self->c;

  my @post_log_cmd = ( $c->{submit_bin} );
  push @post_log_cmd, '-S', $c->{perl_bin};
  push @post_log_cmd, '-N', join( '_', 'ERRpost', $c->{job_id}, $c->{job_name} );
  push @post_log_cmd, '-e', $c->{stderr_dir};
  push @post_log_cmd, '-o', $c->{stdout_dir};
  push @post_log_cmd, @{ $c->{cmd} }, '--node_log', $c->{job_id}, $self->config_file;

  my $update_log_file = $self->failed_update_file;

  open my $update_log_fh, '>', $update_log_file or confess "Can't open filehandle: $!";
  print $update_log_fh join( " ", "cd", "'" . $c->{working_dir} . "'", '&&', @post_log_cmd ), "\n";
  $update_log_fh->close;

  chmod 0755, $update_log_file;

  return;
}

__PACKAGE__->meta->make_immutable();
