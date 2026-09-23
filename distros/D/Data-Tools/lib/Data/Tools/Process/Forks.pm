##############################################################################
#
#  Data::Tools::Process::Forks fork process and control
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#
#  GPL
#
##############################################################################
package Data::Tools::Process::Forks;
use strict;
use Exporter;
use POSIX;
our $VERSION = '1.52';

our @ISA    = qw( Exporter );
our @EXPORT = qw(

                forks_set_max
                forks_get_max
                forks_set_start_wait_to

                forks_reset_state
                forks_setup_signals
                
                forks_start_one
                forks_wait_one
                forks_wait_all
                
                forks_count       
                forks_signal_all
                forks_stop_all
                forks_kill_all
                
                forks_pids
                forks_names
                
                );

# TODO: add on fork finish callback

my $__MAX_FORKS =  4;
my %__FORKS     = ();     # maps pid to name (name is '*' for no-named-ones)
my $__START_WAIT_TO = 0;  # wait timeout used when trying to start new fork

sub forks_set_max
{
  my $max = @_ == 0 ? __get_max_machine_core_count() : shift;
  
  $max = 4 if $max < 1; # no foreground option, do not fork in higher-level logic
  
  $__MAX_FORKS = $max;
}  

sub forks_get_max
{
  return $__MAX_FORKS;
}  

sub forks_set_start_wait_to
{
  my $to = shift;
  
  $to = 0 if $to < 0;
  
  $__START_WAIT_TO = $to;
}

sub __sig_handler_term
{
  forks_stop_all();
  forks_wait_all();
  exit 111;
};

sub forks_setup_signals
{
  $SIG{ 'INT'  } = \&__sig_handler_term;
  $SIG{ 'TERM' } = \&__sig_handler_term;
  # TODO: $SIG{ 'CHILD' }?
}

sub forks_reset_state
{
  $__MAX_FORKS =  4;
  %__FORKS     = ();
}

sub forks_signal_all
{
  my $sig = shift // return undef;
  # TODO: filter by NAMEs

  kill( $sig, keys %__FORKS );
}

sub forks_stop_all
{
  # TODO: filter by NAMEs
  return forks_signal_all( 'TERM' );
}

sub forks_kill_all
{
  # TODO: filter by NAMEs
  return forks_signal_all( 'KILL' );
}

sub forks_count
{
  # TODO: filter by NAMEs
  return scalar( keys %__FORKS );
}

sub __wait_count
{
  my $bar = shift; # wait until forks count fall below this bar (count)
  my $to  = shift; # timeout in seconds, if 0 wait will be blocking
  
  my $sc = 0; # stopped count
  
  my $xt = time() + $to if $to; # expire/timeout time
  while( forks_count() >= $bar ) # should reach below $bar
    {
    my $pid = forks_wait_one( $to ); # if $to, will be non-blocking
    $sc++, next if $pid;
    last unless forks_count(); # no more processes to wait for, return
    last if $xt and time() > $xt;
    sleep( 1 ); # wait 1 second
    }
  
  return $sc;
}

sub forks_wait_one
{
  my $nb = shift;
  
  my $nb = $nb ? WNOHANG : 0;
  
  my $pid = waitpid( -1, $nb );
  return () if $pid <= 0;
  
  my $status = $?;
  my $exit   = $status >> 8;       # exit code
  my $xsig   = $status & 127;      # exit signal
  my $name   = $__FORKS{ $pid };   # forked process name
  
  delete $__FORKS{ $pid };

  # print "    <-- exit ( $pid, $exit, $xsig, $name )\n";
  # TODO: callback with ( $pid, $exit, $xsig, $name )

  return wantarray ? ( $pid, $exit, $xsig, $name ) : $pid;
}

sub forks_wait_all
{
  return __wait_count( 1, @_ ); # wait all
}

sub forks_start_one
{
  my $name = shift || '*';
  my $sub  = shift;

  __wait_count( $__MAX_FORKS, $__START_WAIT_TO ); # wait count to fall below max
  return '0E0' if forks_count() >= $__MAX_FORKS; # __wait_count() was cancelled on timeout


  my $pid = fork();
  return '0E0' unless defined $pid; # error, but will still be in the parent

  if( $pid )
    {
    # print "--> forked [$pid]\n";
    # parent here
    $__FORKS{ $pid } = $name;
    return $pid;
    }
  else
    {
    # print "           [$$] here\n";
    }  

  # child here
  forks_reset_state(); # allow, forked child's own fork pools

  exit $sub->( @_ ) if $sub; # exec sub and exit with exit code
  
  return 0;
}

sub forks_pids
{
  # TODO: filter by NAMEs
  return keys %__FORKS;
}

sub forks_names
{
  my %n;
  $n{ $_ }++ for values %__FORKS;
  return keys %n;
}


sub __get_max_machine_core_count
{
  # only on Linux
  my $cc = 0;
  open my $fh, '<', '/proc/cpuinfo';
  $cc += /^processor\s*:/ for <$fh>;
  close $fh;
  return $cc || 8;
}

1;


=pod

=head1 NAME

Data::Tools::Process::Forks - Fork process creation and control

=head1 SYNOPSIS

  use Data::Tools::Process::Forks;

  # set up signal handlers for graceful shutdown (optional)
  forks_setup_signals();

  # configure maximum concurrent forks (default is 8)
  forks_set_max( 18 );

  # case A: start simple worker processes
  for my $task ( @tasks )
    {
    # this is the parent process, fork and continue
    forks_start_one( 'THINKER' ) and next; 
    
    # here is the forked child process, do some work and exit:
    # ...
    exit 111;
    # exit here is mandatory and omitting it would be a problem, 
    # since it will start forking more processes from the child one!
    # however it is the most simple use case.
    }

  # wait for all children to finish
  forks_wait_all();



  # case B: start worker processes with sub reference or closure
  for my $task ( @tasks )
    {
    forks_start_one( 'GOPHER', \&fetch_things ); 
    forks_start_one( 'PARSER', sub { call_parser(); cleanup(); } ); 
    forks_start_one( undef, sub { print "Testing :)\n; return 222 " } ); 
    }

  # wait for all children to finish
  forks_wait_all();


=head1 DESCRIPTION

Data::Tools::Process::Forks provides a simple interface for managing multiple
forked child processes. It handles the common patterns of limiting concurrent
processes, tracking active children by name, and graceful shutdown via signals.

The module keeps track of running and completed children when the maximum fork 
count is reached, allowing new processes to start or wait for new open slot.

=head1 FUNCTIONS

All functions are exported by default.

=head2 Signal Handling

=head3 forks_setup_signals()

Installs signal handlers for C<INT> and C<TERM> signals. When either signal is
received, the handler will send C<TERM> to all child processes, wait for them
to exit, then terminate the parent process with exit code 111.

  forks_setup_signals();

This is optional and should typically be called early in the parent process 
before forking any children.

=head2 Process Creation and Waiting

=head3 forks_start_one( $name, $coderef, @args )

Forks a new child process to execute the given subroutine.

  my $pid = forks_start_one( 'worker', \&do_work, @work_args );

B<Parameters:>

=over 4

=item C<$name>

Optional name for the forked process, used for identification. Defaults to
C<'*'> if not provided or undefined.

=item C<$coderef>

Optional code reference to execute in the child. If provided, the child will
execute this subroutine and exit with its return value as the exit code.
If not provided, the function returns 0 in the child, allowing inline child
code (see SYNOPSIS).

=item C<@args>

Optional arguments passed to C<$coderef> when executed in the child.

=back

B<Returns:>

=over 4

=item *

In the parent: the child's PID on success, or C<'0E0'> (true but zero) on
fork failure. On fork failure and inline child prcesses, the parent will simply
skip the child code and try to fork again. To avoid high load, save the result
code and do something like:


  my $fr = forks_start_one();
  if( $fr eq '0E0' )
    {
    print "fork error [$!] sleeping\n";
    sleep 3;
    }
  next if $fr;  
  
  # forked child here
  exit 1;

=item *

In the child (when no C<$coderef> provided): 0

To be sure code runs in the forked child process, return value must be checked
like this:

  if( ! forks_start_one() )
    {
    # child here
    # must finish with exit!
    exit 2;
    }

WARNING: return value should never be compared to 0, otherwise on fork errors, 
child code will be executed in the parent process!

  if( forks_start_one() == 0 )
    {
    # WRONG! this will execute in the parent
    # must finish with exit!
    exit 2;
    }
  

=back

B<Note:> If the current number of active forks equals or exceeds the maximum
(see C<forks_set_max()>), this function blocks until a child exits before
forking the new process.

=head3 forks_wait_one( $non_blocking )

Waits for one child process to exit.

  # blocking, return all child attributes (list context)
  my ( $pid, $exit_code, $signal, $name ) = forks_wait_one();
  
  # Non-blocking check, got pid only (scalar context)
  my $pid = forks_wait_one( 1 );

B<Parameters:>

=over 4

=item C<$non_blocking>

If true, returns immediately if no child has exited (uses C<WNOHANG>).
If false or omitted, blocks until a child exits.

=back

B<Returns:>

In list context: C<( $pid, $exit_code, $signal, $name )>

=over 4

=item C<$pid>

The process ID of the exited child.

=item C<$exit_code>

The exit code returned by the child (high 8 bits of C<$?>).

=item C<$signal>

The signal that terminated the child, if any (low 7 bits of C<$?>).

=item C<$name>

The name assigned to the child when it was forked.

=back

In scalar context: returns only C<$pid>.

Returns an empty list if no children have exited (non-blocking mode) or if
there are no active children.

=head3 forks_wait_all( $timeout )

Blocks until all active child processes have exited. Optional timeout in
seconds can be specified to avoid blocking. Avoiding blocking may give control
to the parent process when forked one has blocked for some reason.

  # block until all forks finished
  forks_wait_all(); 
  
  # or
  
  # wait 4 seconds for finished forks and return finished count
  my $c = forks_wait_all( 4 ); 
  

internally it calls forks_wait_one() until internal forked processes
count reached 0 or timeout reached.

=head2 Process Signalling

=head3 forks_signal_all( $signal )

Sends the specified signal to all active child processes.

  forks_signal_all( 'HUP' );
  forks_signal_all( 15 );      # SIGTERM by number

if signal is undef or empty parameter list, will do nothing and exit.

B<Parameters:>

=over 4

=item C<$signal>

The signal name or number to send.

=back

B<Returns:> C<undef> if no signal specified, otherwise the result of C<kill()>.

=head3 forks_stop_all()

Sends C<TERM> signal to all active child processes.

  forks_stop_all();

Equivalent to C<forks_signal_all( 'TERM' )>.

=head3 forks_kill_all()

Sends C<KILL> signal to all active child processes.

  forks_kill_all();

Equivalent to C<forks_signal_all( 'KILL' )>. Use this for forceful termination
when children do not respond to C<TERM>.

=head2 Configuration

=head3 forks_set_max( $max )

Sets the maximum number of concurrent child processes (slots).

  forks_set_max( 16 );
  
B<Parameters:>

=over 4

=item C<$max>

Maximum number of concurrent forks. Values less than 1 are clamped to 4.

=back

When C<forks_start_one()> is called and the current fork count (slots) equals 
or exceeds this maximum, it will wait until a child exits before forking.

Default value is 4.

If called without parameters, will try to figure machine core count and set
it the same. Note that this works only on machines with /proc file system 
(i.e. Linux). if not Linux, /proc not mounted or other error will set to 8.

=head3 forks_get_max()

Returns the current maximum fork limit.

  my $max = forks_get_max();

=head2 Inspection

=head3 forks_count()

Returns the number of currently active child processes.

  my $active = forks_count();
  print "Running $active workers\n";

=head3 forks_pids()

Returns a list of PIDs for all active child processes.

  my @pids = forks_pids();

=head3 forks_names()

Returns a list of unique names assigned to active child processes.

  my @names = forks_names();

Note that multiple processes may share the same name; this returns only
unique names in use.

=head3 forks_set_start_wait_to( $timeout )

This sets timeout for waiting for free slot when trying to start new fork but
maximum count has been reached. Setting $timeout to 0 will enable blocking,
i.e. forks_start_one() will wait until slot freed. If timeout reached
forks_start_one() will return '0E0' (zero but true) which is same as fork 
error.

=head1 EXAMPLES

=head2 Parallel Task Processing

  use Data::Tools::Process::Forks;

  forks_setup_signals();
  forks_set_max( 6 );

  my @files = glob( '*.dat' );

  for my $file ( @files )
    {
    forks_start_one( 
                     'processor', 
                     sub 
                        {
                        process_file( $file );
                        return 0;
                        }
                   );
    }

  forks_wait_all();
  print "All files processed\n";

=head2 Worker Pool with Status Monitoring

  use Data::Tools::Process::Forks;

  forks_setup_signals();
  forks_set_max( 11 );

  # Start workers
  for my $id ( 1 .. 20 )
    {
    forks_start_one( "worker-$id", \&worker_task, $id );
    }

  # Monitor progress
  while( forks_count() > 0 )
    {
    my ( $pid, $exit, $sig, $name ) = forks_wait_one();
    if( $exit == 0 )
      {
      print "$name completed successfully\n";
      }
    else
      {
      print "$name failed with exit code $exit\n";
      }
    }

=head2 Graceful Shutdown

  use Data::Tools::Process::Forks;

  forks_setup_signals();  # Handles INT/TERM automatically

  # Or manual shutdown:
  END
    {
    if( forks_count() > 0 )
      {
      print "Shutting down workers...\n";
      forks_stop_all();
      forks_wait_all();
      }
    }

=head1 NOTES

=over 4

=item *

The module uses package-level variables to track state. Only one fork pool
can be managed per process but fork names can represent separate fork pools.

This is really a design choice. This module was meant to be simple with
minimum dependencies (only Perl core Exporter and POSIX). 

For, possibly, more complex things you may check B<Parralel::ForkManager> 
on B<CPAN>.

=item *

Child processes reset the parent fork pool state so they can have own
fork process pool and use this module themselves.

=item *

The C<forks_start_one()> function may block indefinitely if child processes
do not exit and the maximum fork count is reached. To avoid this situation
C<forks_set_start_wait_to()> can be used to set timeout for waiting for a free
slot to be available while trying to start new one:

    forks_set_start_wait_to( 4 );
    my $fr = forks_start_one();
    if( $fr eq '0E0' )
      {
      # either fork error occured
      # or timeout waiting for free slot reached
      ...
      }

=back

=head1 SEE ALSO

L<Parallel::ForkManager>, L<fork(2)>, L<waitpid(2)>, L<POSIX>

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/  

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=cut
