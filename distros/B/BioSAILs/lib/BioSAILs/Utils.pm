package BioSAILs::Utils;

use Moose::Role;
use namespace::autoclean;

use IPC::Cmd qw[can_run run run_forked];

=head3 run_short_command

This function is for running quick running commands that we don't need to buffer
the output for.

A long running command is given in
HPC::Runner::Command::submit_jobs::Utils::Scheduler::Submit

=cut

##TODO I have this function all over the place

sub run_short_command {
    my $self = shift;
    my $cmd  = shift;

    my( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
        run( command => $cmd, verbose => 0 );

    return {
      exit_code => $success,
      error_message => $error_message,
      full_buffer => $full_buf,
      stdout_buffer => $stdout_buf,
      stderr_buffer => $stderr_buf,
    };
}

1;
