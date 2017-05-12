package Class::Usul::IPC::Cmd;

use namespace::autoclean;

use Class::Null;
use Class::Usul::Constants    qw( EXCEPTION_CLASS FALSE NUL
                                  OK SPC TRUE UNDEFINED_RV );
use Class::Usul::Functions    qw( arg_list emit_to io is_arrayref
                                  is_coderef is_hashref is_member is_win32
                                  nonblocking_write_pipe_pair
                                  strip_leader throw );
use Class::Usul::Time         qw( nap );
use Class::Usul::Types        qw( ArrayRef Bool LoadableClass Logger
                                  NonEmptySimpleStr Num Object PositiveInt
                                  SimpleStr Str Undef );
use English                   qw( -no_match_vars );
use File::Basename            qw( basename );
use File::DataClass::Types    qw( Directory Path );
use File::Spec::Functions     qw( devnull rootdir tmpdir );
use IO::Handle;
use IO::Select;
use IPC::Open3;
use Module::Load::Conditional qw( can_load );
use POSIX                     qw( _exit setsid sysconf WIFEXITED WNOHANG );
use Scalar::Util              qw( blessed openhandle weaken );
use Socket                    qw( AF_UNIX SOCK_STREAM PF_UNSPEC );
use Sub::Install              qw( install_sub );
use Try::Tiny;
use Unexpected::Functions     qw( TimeOut Unspecified );

use Moo; use warnings NONFATAL => 'all';

our ($CHILD_ENUM, $CHILD_PID);

# Public attributes
has 'async'            => is => 'ro',   isa => Bool, default => FALSE;

has 'close_all_files'  => is => 'ro',   isa => Bool, default => FALSE;

has 'cmd'              => is => 'ro',   isa => ArrayRef | Str,
   required            => TRUE;

has 'detach'           => is => 'ro',   isa => Bool, default => FALSE;

has 'err'              => is => 'ro',   isa => Path | SimpleStr, default => NUL;

has 'expected_rv'      => is => 'ro',   isa => PositiveInt, default => 0;

has 'ignore_zombies'   => is => 'lazy', isa => Bool, builder => sub {
   ($_[ 0 ]->async || $_[ 0 ]->detach) ? TRUE : FALSE };

has 'in'               => is => 'ro',   isa => Path | SimpleStr, coerce => sub {
   (is_arrayref $_[ 0 ]) ? join $RS, @{ $_[ 0 ] } : $_[ 0 ] },
   default             => NUL;

has 'log'              => is => 'lazy', isa => Logger,
   builder             => sub { Class::Null->new };

has 'keep_fhs'         => is => 'lazy', isa => ArrayRef,
   builder             => sub {
      $_[ 0 ]->log->can( 'filehandle' ) ? [ $_[ 0 ]->log->filehandle ] : [] };

has 'max_pidfile_wait' => is => 'ro',   isa => PositiveInt, default => 15;

has 'nap_time'         => is => 'ro',   isa => Num, default => 0.3;

has 'out'              => is => 'ro',   isa => Path | SimpleStr, default => NUL;

has 'partition_cmd'    => is => 'ro',   isa => Bool, default => TRUE;

has 'pidfile'          => is => 'lazy', isa => Path, coerce => TRUE,
   builder             => sub { $_[ 0 ]->rundir->tempfile };

has 'response_class'   => is => 'lazy', isa => LoadableClass, coerce => TRUE,
   default             => 'Class::Usul::Response::IPC';

has 'rundir'           => is => 'lazy', isa => Directory, coerce => TRUE,
   builder             => sub { $_[ 0 ]->tempdir };

has 'tempdir'          => is => 'lazy', isa => Directory,
   builder             => sub { tmpdir }, coerce => TRUE,
   handles             => { _tempfile => 'tempfile' };

has 'timeout'          => is => 'ro',   isa => PositiveInt, default => 0;

has 'use_ipc_run'      => is => 'ro',   isa => Bool, default => FALSE;

has 'use_system'       => is => 'ro',   isa => Bool, default => FALSE;

has 'working_dir'      => is => 'lazy', isa => Directory | Undef,
   default             => sub { $_[ 0 ]->detach ? io rootdir : undef },
   coerce              => TRUE;

# Private functions
my $_child_handler; $_child_handler = sub {
   local $OS_ERROR; # So that waitpid does not step on existing value

   while ((my $child_pid = waitpid -1, WNOHANG) > 0) {
      if (WIFEXITED( $CHILD_ERROR ) and $child_pid > ($CHILD_PID || 0)) {
         $CHILD_PID = $child_pid; $CHILD_ENUM = $CHILD_ERROR;
      }
   }

   $SIG{CHLD} = $_child_handler; # In case of unreliable signals
   return;
};

my $_close_child_io = sub { # In the parent, close the child end of the pipes
   my $pipes = shift;

   close $pipes->[ 0 ]->[ 0 ]; undef $pipes->[ 0 ]->[ 0 ];
   close $pipes->[ 1 ]->[ 1 ]; undef $pipes->[ 1 ]->[ 1 ];
   close $pipes->[ 2 ]->[ 1 ]; undef $pipes->[ 2 ]->[ 1 ];
   close $pipes->[ 3 ]->[ 1 ]; undef $pipes->[ 3 ]->[ 1 ];
   return;
};

my $_drain = sub { # Suck up the output from the child process
   my (%hands, @ready); my $selector = IO::Select->new(); my $i = 0;

   while (defined (my $fh = $_[ $i ])) {
      $selector->add( $fh ); $hands{ fileno $fh } = $_[ $i + 1 ]; $i += 2;
   }

   while (@ready = $selector->can_read) {
      for my $fh (@ready) {
         my $buf; my $bytes_read = sysread $fh, $buf, 64 * 1024;

         if ($bytes_read) { $hands{ fileno $fh }->( "${buf}" ) }
         else { $selector->remove( $fh ); close $fh }
      }
   }

   return;
};

my $_err_handler = sub {
   my ($err, $filtered, $standard) = @_;

   return sub {
      my $buf = shift; defined $buf or return;

      blessed $err     and $err->append( $buf );
      $err eq 'out'    and ${ $filtered } .= $buf;
      $err ne 'null'   and ${ $standard } .= $buf;
      $err eq 'stderr' and emit_to \*STDERR, $buf;
      return;
   }
};

my $_filter_out = sub {
   return join "\n", map    { strip_leader $_ }
                     grep   { not m{ (?: Started | Finished ) }msx }
                     split m{ [\n] }msx, $_[ 0 ];
};

my $_four_nonblocking_pipe_pairs = sub {
   return [ nonblocking_write_pipe_pair, nonblocking_write_pipe_pair,
            nonblocking_write_pipe_pair, nonblocking_write_pipe_pair ];
};

my $_has_shell_meta = sub {
   return (is_arrayref $_[ 0 ] && is_member '|',  $_[ 0 ]) ? TRUE
        : (is_arrayref $_[ 0 ] && is_member '&&', $_[ 0 ]) ? TRUE
        : (                           is_arrayref $_[ 0 ]) ? FALSE
        : (                      $_[ 0 ] =~ m{ [|]    }mx) ? TRUE
        : (                      $_[ 0 ] =~ m{ [&][&] }mx) ? TRUE
                                                           : FALSE;
};

my $_make_socket_pipe = sub {
   socketpair( $_[ 0 ], $_[ 1 ], AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or throw $EXTENDED_OS_ERROR;
   shutdown  ( $_[ 0 ], 1 );  # No more writing for reader
   shutdown  ( $_[ 1 ], 0 );  # No more reading for writer
   return;
};

my $_out_handler = sub {
   my ($out, $filtered, $standard) = @_;

   return sub {
      my $buf = shift; defined $buf or return;

      blessed $out     and $out->append( $buf );
      $out ne 'null'   and ${ $filtered } .= $buf;
      $out ne 'null'   and ${ $standard } .= $buf;
      $out eq 'stdout' and emit_to \*STDOUT, $buf;
      return;
   }
};

my $_partition_command = sub {
   my $cmd = shift; my $aref = []; my @command = ();

   for my $item (grep { defined && length } @{ $cmd }) {
      if ($item !~ m{ [^\\][\<\>\|\&] }mx) { push @{ $aref }, $item }
      else { push @command, $aref, $item; $aref = [] }
   }

   if ($aref->[ 0 ]) {
      if ($command[ 0 ]) { push @command, $aref }
      else { @command = @{ $aref } }
   }

   return \@command;
};

my $_pipe_handler; $_pipe_handler = sub {
   local $OS_ERROR; # So that wait does not step on existing value

   $CHILD_PID = wait; $CHILD_ENUM = (255 << 8) + 13;
   $SIG{PIPE} = $_pipe_handler;
   return;
};

my $_quote = sub {
   my $v = shift; return is_win32 ? '"'.$v.'"' : "'${v}'";
};

my $_quoted_join = sub {
   return join SPC, map { m{ [ ] }mx ? $_quote->( $_ ) : $_ } @_;
};

my $_recv_exec_failure = sub {
   my $fh = shift; my $to_read = 2 * length pack 'I', 0;

   read $fh, my $buf = NUL, $to_read or return FALSE;

   (my $errno, $to_read) = unpack 'II', $buf; $ERRNO = $errno;

   read $fh, my $error = NUL, $to_read; $error and utf8::decode $error;

   return $error || "${ERRNO}";
};

my $_redirect_stderr = sub {
   my $v  = shift; my $err = \*STDERR; close $err;

   my $op = openhandle $v ? '>&' : '>'; my $sink = $op eq '>' ? $v : fileno $v;

   open $err, $op, $sink
      or throw "Could not redirect STDERR to ${sink}: ${OS_ERROR}";
   return;
};

my $_redirect_stdin = sub {
   my $v  = shift; my $in = \*STDIN; close $in;

   my $op = openhandle $v ? '<&' : '<'; my $src = $op eq '<' ? $v : fileno $v;

   open $in,  $op, $src
      or throw "Could not redirect STDIN from ${src}: ${OS_ERROR}";
   return;
};

my $_redirect_stdout = sub {
   my $v  = shift; my $out = \*STDOUT; close $out;

   my $op = openhandle $v ? '>&' : '>'; my $sink = $op eq '>' ? $v : fileno $v;

   open $out, $op, $sink
      or throw "Could not redirect STDOUT to ${sink}: ${OS_ERROR}";
   return;
};

my $_send_exec_failure = sub {
   my ($fh, $error) = @_; utf8::encode $error;

   emit_to $fh, pack 'IIa*', 0+$ERRNO, length $error, $error; close $fh;
   _exit 255;
};

my $_send_in = sub {
   my ($fh, $in) = @_; $in or return;

   if    (blessed $in)                      { emit_to $fh, $in->slurp }
   elsif ($in ne 'null' and $in ne 'stdin') { emit_to $fh, $in }

   return;
};

my $_open3 = sub {
   local (*TO_CHLD_R,     *TO_CHLD_W);
   local (*FR_CHLD_R,     *FR_CHLD_W);
   local (*FR_CHLD_ERR_R, *FR_CHLD_ERR_W);

   $_make_socket_pipe->( *TO_CHLD_R,     *TO_CHLD_W     );
   $_make_socket_pipe->( *FR_CHLD_R,     *FR_CHLD_W     );
   $_make_socket_pipe->( *FR_CHLD_ERR_R, *FR_CHLD_ERR_W );

   my $pid = open3( '>&TO_CHLD_R', '<&FR_CHLD_W', '<&FR_CHLD_ERR_W', @_ );

   return ($pid, *TO_CHLD_W, *FR_CHLD_R, *FR_CHLD_ERR_R);
};

# Private methods
my $_detach_process = sub { # And this method came from MooseX::Daemonize
   my $self = shift;

   setsid or throw 'Cannot detach from controlling process';
   $SIG{HUP} = 'IGNORE'; fork and _exit OK;
#  Clearing file creation mask allows direct control of the access mode of
#  created files and directories in open, mkdir, and mkpath functions
   umask 0;

   if ($self->close_all_files) { # Close all fds except the ones we should keep
      my $openmax = sysconf( &POSIX::_SC_OPEN_MAX );

      (not defined $openmax or $openmax < 0) and $openmax = 64;

      for (grep { not is_member $_, $self->keep_fhs } 0 .. $openmax) {
         POSIX::close( $_ );
      }
   }

   $self->pidfile->println( $PID );
   return;
};

my $_ipc_run_harness = sub {
   my ($self, $cmd_ref, @cmd_args) = @_;

   if ($self->async) {
      is_coderef $cmd_ref->[ 0 ] and $cmd_ref = $cmd_ref->[ 0 ];

      my $pidfile = $self->pidfile; weaken( $pidfile );
      my $h = IPC::Run::harness( $cmd_ref, @cmd_args, init => sub {
         IPC::Run::close_terminal(); $pidfile->println( $PID ) }, '&' );

      $h->start; return ( 0, $h );
   }

   my $h  = IPC::Run::harness( $cmd_ref, @cmd_args ); $h->run;
   my $rv = $h->full_result || 0; $rv =~ m{ unknown }msx and throw $rv;

   return ( $rv, $h );
};

my $_new_async_response = sub {
   my ($self, $pid) = @_; my $prog = basename( $self->cmd->[ 0 ] );

   $self->log->debug( my $out = "Running ${prog}(${pid}) in the background" );

   return $self->response_class->new( out => $out, pid => $pid );
};

my $_redirect_child_io = sub {
   my ($self, $pipes) = @_;

   my $in = $self->in || 'null'; my $out = $self->out; my $err = $self->err;

   if ($self->async or $self->detach) { $out ||= 'null'; $err ||= 'null' }

   $in  eq 'stdin'
      or $_redirect_stdin-> ( ($in  eq 'null') ? devnull
                                               : $pipes->[ 0 ]->[ 0 ] );
   $out eq 'stdout'
      or $_redirect_stdout->( (  blessed $out) ? "${out}"
                            : ($out eq 'null') ? devnull
                                               : $pipes->[ 1 ]->[ 1 ] );
   $err eq 'stderr'
      or $_redirect_stderr->( (  blessed $err) ? "${err}"
                            : ($err eq 'null') ? devnull
                                               : $pipes->[ 2 ]->[ 1 ] );
   return;
};

my $_return_codes_or_throw = sub {
   my ($self, $cmd, $e_num, $e_str) = @_;

   $e_str ||= 'Unknown error'; chomp $e_str;

   if ($e_num == UNDEFINED_RV) {
      my $error = 'Program [_1] failed to start: [_2]';
      my $prog  = basename( (split SPC, $cmd)[ 0 ] );

      throw $error, [ $prog, $e_str ], level => 3, rv => UNDEFINED_RV;
   }

   my $rv = $e_num >> 8; my $core = $e_num & 128; my $sig = $e_num & 127;

   if ($rv > $self->expected_rv) {
      $self->log->debug( my $error = "${e_str} rv ${rv}" );
      throw $error, level => 3, rv => $rv;
   }

   return { core => $core, rv => $rv, sig => $sig, };
};

my $_shutdown = sub {
   my $self = shift; my $pidfile = $self->pidfile;

   $pidfile->exists and $pidfile->getline == $PID and $self->pidfile->unlink;

   _exit OK;
};

my $_wait_for_pidfile_and_read = sub {
   my $self = shift; my $pidfile = $self->pidfile; my $waited = 0;

   while (not $pidfile->exists or $pidfile->is_empty) {
      nap $self->nap_time; $waited += $self->nap_time;
      $waited > $self->max_pidfile_wait
         and throw 'File [_1] contains no process id', [ $pidfile ];
   }

   my $pid = $pidfile->chomp->getline || UNDEFINED_RV; $pidfile->close;

   return $pid;
};

my $_execute_coderef = sub {
   my $self = shift; my ($code, @args) = @{ $self->cmd }; my $rv;

   try {
      local $SIG{INT} = sub { $self->$_shutdown };

      $rv = $code->( $self, @args ); defined $rv and $rv = $rv << 8;

      $self->pidfile->exists and $self->pidfile->unlink;
   }
   catch {
      blessed $_ and $_->can( 'rv' ) and $rv = $_->rv; emit_to \*STDERR, $_;
   };

   _exit $rv // OK;
};

my $_wait_for_child = sub {
   my ($self, $pid, $pipes) = @_;

   my ($filtered, $stderr, $stdout) = (NUL, NUL, NUL);

   my $in_fh    = $pipes->[ 0 ]->[ 1 ];
   my $out_fh   = $pipes->[ 1 ]->[ 0 ];
   my $err_fh   = $pipes->[ 2 ]->[ 0 ];
   my $stat_fh  = $pipes->[ 3 ]->[ 0 ];
   my $err_hand = $_err_handler->( $self->err, \$filtered, \$stderr );
   my $out_hand = $_out_handler->( $self->out, \$filtered, \$stdout );
   my $prog     = basename( my $cmd = $self->cmd->[ 0 ] );

   try {
      my $tmout = $self->timeout; $tmout and local $SIG{ALRM} = sub {
         throw TimeOut, [ $prog, $tmout ];
      } and alarm $tmout;

      my $error = $_recv_exec_failure->( $stat_fh ); $error and throw $error;

      $_send_in->( $in_fh, $self->in ); close $in_fh;
      $_drain->( $out_fh, $out_hand, $err_fh, $err_hand );
      waitpid $pid, 0; alarm 0;
   }
   catch { alarm 0; throw $_ };

   my $e_num = $CHILD_PID > 0 ? $CHILD_ENUM : $CHILD_ERROR;
   my $codes = $self->$_return_codes_or_throw( $cmd, $e_num, $stderr );

   return $self->response_class->new
      (  core   => $codes->{core}, out    => $_filter_out->( $filtered ),
         rv     => $codes->{rv},   sig    => $codes->{sig},
         stderr => $stderr,        stdout => $stdout );
};

my $_run_cmd_using_fork_and_exec = sub {
   my $self    = shift;
   my $pipes   = $_four_nonblocking_pipe_pairs->();
   my $cmd_str = $_quoted_join->( @{ $self->cmd } );

   $self->log->debug( "Running ${cmd_str} using fork and exec" );

   {  local ($CHILD_ENUM, $CHILD_PID) = (0, 0);
      $self->ignore_zombies and local $SIG{CHLD} = 'IGNORE';

      if (my $pid = fork) { # Parent
         $_close_child_io->( $pipes );
         $self->detach and $pid = $self->$_wait_for_pidfile_and_read;

         return ($self->async || $self->detach)
              ?  $self->$_new_async_response( $pid )
              :  $self->$_wait_for_child( $pid, $pipes );
      }
   }

   try { # Child
      my $prog = basename( my $cmd = $self->cmd->[ 0 ] );

      $self->$_redirect_child_io( $pipes );
      $self->detach and $self->$_detach_process;
      $self->working_dir and chdir $self->working_dir;
      is_coderef $cmd and $self->$_execute_coderef; # Never returns

      exec @{ $self->cmd }
         or throw 'Program [_1] failed to exec: [_2]', [ $prog, $OS_ERROR ];
   }
   catch { $_send_exec_failure->( $pipes->[ 3 ]->[ 1 ], "${_}" ) };

   close $pipes->[ 3 ]->[ 1 ];
   return OK;
};

my $_run_cmd_using_ipc_run = sub {
   my $self = shift; my ($buf_err, $buf_out, $error, $h, $rv) = (NUL, NUL);

   my $cmd      = $self->cmd;
   my $cmd_ref  = $self->partition_cmd ? $_partition_command->( $cmd ) : $cmd;
   my $prog     = basename( $cmd->[ 0 ] );
   my $null     = devnull;
   my $in       = $self->in || 'null';
   my $out      = $self->out;
   my $err      = $self->err;
   my @cmd_args = ();

   if    (blessed $in)      { push @cmd_args, "0<${in}"       }
   elsif ($in  eq 'null')   { push @cmd_args, "0<${null}"     }
   elsif ($in  ne 'stdin')  { push @cmd_args, '0<', \$in      }

   if    (blessed $out)     { push @cmd_args, "1>${out}"      }
   elsif ($out eq 'null')   { push @cmd_args, "1>${null}"     }
   elsif ($out ne 'stdout') { push @cmd_args, '1>', \$buf_out }

   if    (blessed $err)     { push @cmd_args, "2>${err}"      }
   elsif ($err eq 'out')    { push @cmd_args, '2>&1'          }
   elsif ($err eq 'null')   { push @cmd_args, "2>${null}"     }
   elsif ($err ne 'stderr') { push @cmd_args, '2>', \$buf_err }

   my $cmd_str = $_quoted_join->( @{ $self->cmd }, @cmd_args );

   $self->async and $cmd_str .= ' &';
   $self->log->debug( "Running ${cmd_str} using ipc run" );

   try {
      my $tmout = $self->timeout; $tmout and local $SIG{ALRM} = sub {
         throw TimeOut, [ $cmd_str, $tmout ];
      } and alarm $tmout;

      ($rv, $h) = $_ipc_run_harness->( $self, $cmd_ref, @cmd_args ); alarm 0;
   }
   catch { alarm 0; throw $_ };

   my $sig = $rv & 127; my $core = $rv & 128; $rv = $rv >> 8;

   if ($self->async) {
      my $pid = $self->$_wait_for_pidfile_and_read;

      $out = "Started ${prog}(${pid}) in the background";

      return $self->response_class->new
         ( core => $core, harness => $h,  out => $out,
           pid  => $pid,  rv      => $rv, sig => $sig );
   }

   my ($stderr, $stdout) = (NUL, NUL);

   if ($out ne 'null' and $out ne 'stdout') {
       not blessed $out and $out = $_filter_out->( $stdout = $buf_out );
   }
   else { $out = $stdout = NUL }

   if    ($err eq 'out') { $stderr = $stdout; $error = $out; chomp $error }
   elsif (blessed $err)  { $stderr = $error = $err->all; chomp $error }
   elsif ($err ne 'null' and $err ne 'stderr') {
      $stderr = $error = $buf_err; chomp $error;
   }
   else { $stderr = $error = NUL }

   if ($rv > $self->expected_rv) {
      $error = $error ? "${error} rv ${rv}" : "Unknown error rv ${rv}";
      $self->log->debug( $error );
      throw $error, out => $out, rv => $rv;
   }

   return $self->response_class->new
      (  core => $core, out    => "${out}", rv     => $rv,
         sig  => $sig,  stderr => $stderr,  stdout => $stdout );
};

my $_run_cmd_using_open3 = sub { # Robbed in part from IPC::Cmd
   my ($self, $cmd) = @_; my ($filtered, $stderr, $stdout) = (NUL, NUL, NUL);

   my $err_hand = $_err_handler->( $self->err, \$filtered, \$stderr );

   my $out_hand = $_out_handler->( $self->out, \$filtered, \$stdout );

   $self->log->debug( "Running ${cmd} using open3" ); my $e_num;

   {  local ($CHILD_ENUM, $CHILD_PID) = (0, 0);

      try {
         local $SIG{PIPE} = $_pipe_handler;

         my $tmout = $self->timeout; $tmout and local $SIG{ALRM} = sub {
            throw TimeOut, [ $cmd, $tmout ];
         } and alarm $tmout;

         my ($pid, $in_fh, $out_fh, $err_fh) = $_open3->( $cmd );

         $_send_in->( $in_fh, $self->in ); close $in_fh;
         $_drain->( $out_fh, $out_hand, $err_fh, $err_hand );
         $pid and waitpid $pid, 0; alarm 0;
      }
      catch { alarm 0; throw $_ };

      $e_num = $CHILD_PID > 0 ? $CHILD_ENUM : $CHILD_ERROR;
   }

   my $codes = $self->$_return_codes_or_throw( $cmd, $e_num, $stderr );

   return $self->response_class->new
      (  core   => $codes->{core}, out    => $_filter_out->( $filtered ),
         rv     => $codes->{rv},   sig    => $codes->{sig},
         stderr => $stderr,        stdout => $stdout );
};

my $_run_cmd_using_system = sub {
   my ($self, $cmd) = @_; my ($error, $rv);

   my $prog = basename( (split SPC, $cmd)[ 0 ] ); my $null = devnull;

   my $in   = $self->in || 'stdin'; my $out = $self->out; my $err = $self->err;

   if ($in ne 'null' and $in ne 'stdin' and not blessed $in) {
      # Different semi-random file names in the temp directory
      my $tmp = $self->_tempfile; $tmp->print( $in ); $in = $tmp;
   }

   $out ne 'null' and $out ne 'stdout' and not blessed $out
      and $out = $self->_tempfile;
   $self->async and $err ||= 'out';
   $err ne 'null' and $err ne 'stderr' and not blessed $err and $err ne 'out'
      and $err = $self->_tempfile;

   $cmd .= $in  eq 'stdin'  ? NUL : $in  eq 'null' ? " 0<${null}" : " 0<${in}";
   $cmd .= $out eq 'stdout' ? NUL : $out eq 'null' ? " 1>${null}" : " 1>${out}";
   $cmd .= $err eq 'stderr' ? NUL : $err eq 'null' ? " 2>${null}"
                                  : $err ne 'out'  ? " 2>${err}"  : ' 2>&1';

   $self->async and $cmd .= ' & echo $! 1>'.$self->pidfile->pathname;
   $self->log->debug( "Running ${cmd} using system" );

   {  local ($CHILD_ENUM, $CHILD_PID) = (0, 0);

      try {
         local $SIG{CHLD} = $_child_handler;

         my $tmout = $self->timeout; $tmout and local $SIG{ALRM} = sub {
            throw TimeOut, [ $cmd, $tmout ];
         } and alarm $tmout;

         $rv = system $cmd; alarm 0;
      }
      catch { alarm 0; throw $_ };

      my $os_error = $OS_ERROR;

      $self->log->debug
         ( "System rv ${rv} child pid ${CHILD_PID} error ${CHILD_ENUM}" );
      # On some systems the child handler reaps the child process so the system
      # call returns -1 and sets $OS_ERROR to 'No child processes'. This line
      # and the child handler code fix the problem
      $rv == UNDEFINED_RV and $CHILD_PID > 0 and $rv = $CHILD_ENUM;
      $rv == UNDEFINED_RV and throw 'Program [_1] failed to start: [_2]',
                                    [ $prog, $os_error ], rv => $rv;
   }

   my $sig = $rv & 127; my $core = $rv & 128; $rv = $rv >> 8;

   my ($stderr, $stdout) = (NUL, NUL);

   if ($self->async) {
      $rv != 0 and throw 'Program [_1] failed to start', [ $prog ], rv => $rv;

      my $pid = $self->$_wait_for_pidfile_and_read;

      $out = "Started ${prog}(${pid}) in the background";

      return $self->response_class->new
         (  core => $core, out => $out, pid => $pid, rv => $rv, sig => $sig );
   }

   if ($out ne 'stdout' and $out ne 'null' and -f $out) {
      $out = $_filter_out->( $stdout = io( $out )->slurp );
   }
   else { $out = $stdout = NUL }

   if ($err eq 'out') { $stderr = $stdout; $error = $out; chomp $error }
   elsif ($err ne 'stderr' and $err ne 'null' and -f $err) {
      $stderr = $error = io( $err )->slurp; chomp $error;
   }
   else { $stderr = $error = NUL }

   if ($rv > $self->expected_rv) {
      $error = $error ? "${error} rv ${rv}" : "Unknown error rv ${rv}";
      $self->log->debug( $error );
      throw $error, out => $out, rv => $rv;
   }

   return $self->response_class->new
      (  core => $core, out    => "${out}", rv     => $rv,
         sig  => $sig,  stderr => $stderr,  stdout => $stdout );
};

my $_run_cmd = sub { # Select one of the implementations
   my $self = shift; my $has_meta = $_has_shell_meta->( my $cmd = $self->cmd );

   if (is_arrayref $cmd) {
      $cmd->[ 0 ] or throw Unspecified, [ 'command' ];

     (is_win32 or $has_meta or $self->use_ipc_run)
        and can_load( modules => { 'IPC::Run' => '0.84' } )
        and return $self->$_run_cmd_using_ipc_run;

      is_win32 or $has_meta or $self->use_system
         or return $self->$_run_cmd_using_fork_and_exec;

      $cmd = $_quoted_join->( @{ $cmd } );
   }

   not is_win32 and ($has_meta or $self->async or $self->use_system)
      and return $self->$_run_cmd_using_system( $cmd );

   return $self->$_run_cmd_using_open3( $cmd );
};

# Construction
around 'BUILDARGS' => sub { # Differentiate constructor method signatures
   my ($orig, $self, @args) = @_; my $n = 0; $n++ while (defined $args[ $n ]);

   return (              $n == 0) ? {}
        : (is_hashref $args[ 0 ]) ? { %{ $args[ 0 ] } }
        : (              $n == 1) ? { cmd => $args[ 0 ] }
        : (is_hashref $args[ 1 ]) ? { cmd => $args[ 0 ], %{ $args[ 1 ] } }
        : (          $n % 2 == 1) ? { cmd => @args }
                                  : { @args };
};

sub BUILD {
   $_[ 0 ]->pidfile->chomp->lock; return;
}

sub import { # Export run_cmd as a function on demand
   my $class  = shift;
   my $params = { (is_hashref $_[ 0 ]) ? %{+ shift } : () };
   my @wanted = @_;
   my $target = caller;

   is_member 'run_cmd', @wanted and install_sub {
       as => 'run_cmd', into => $target, code => sub {
          my $cmd = shift; my $attr = arg_list @_;

          $attr->{cmd} = $cmd or throw Unspecified, [ 'command' ];

          $attr->{ $_ } //= $params->{ $_ } for (keys %{ $params });

          return $_run_cmd->( __PACKAGE__->new( $attr ) );
       } };

   return;
}

# Public methods
sub run_cmd { # Either class or object method
   return $_run_cmd->( (blessed $_[ 0 ]) ? $_[ 0 ] : __PACKAGE__->new( @_ ) );
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Class::Usul::IPC::Cmd - Execute system commands

=head1 Synopsis

   use Class::Usul::IPC::Cmd;

   sub run_cmd {
      my ($self, $cmd, @args) = @_; my $attr = arg_list @args;

      $attr->{cmd    } = $cmd or throw Unspecified, [ 'command' ];
      $attr->{log    } = $self->log;
      $attr->{rundir } = $self->config->rundir;
      $attr->{tempdir} = $self->config->tempdir;

      return Class::Usul::IPC::Cmd->new( $attr )->run_cmd;
   }

   $self->run_cmd( [ 'perl', '-v' ], { async => 1 } );

   # Alternatively there is a functional interface

   use Class::Usul::IPC::Cmd { tempdir => ... }, 'run_cmd';

   run_cmd( [ 'perl', '-v' ], { async => 1 } );

=head1 Description

Refactored L<IPC::Cmd> with a consistent OO API

Would have used L<MooseX::Daemonize> but using L<Moo> not L<Moose> so
robbed some code from there instead

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<async>

Boolean defaults to false. If true the call to C<run_cmd> will return without
waiting for the child process to complete. If true the C<ignore_zombies>
attribute will default to true

=item C<close_all_files>

Boolean defaults to false. If true and the C<detach> attribute is also true
then all open file descriptors in the child are closed except those in the
C<keep_fhs> list attribute

=item C<cmd>

An array reference or a simple string. Required. The external command to
execute

=item C<detach>

Boolean defaults to false. If true the child process will double fork, set
the session id and ignore hangup signals

=item C<err>

A L<File::DataClass::IO> object reference or a simple str. Defaults to null.
Determines where the standard error of the command will be redirected to.
Values are the same as for C<out>. Additionally a value of 'out' will
redirect standard error to standard output

=item C<expected_rv>

Positive integer default to zero. The maximum return value which is
considered a success

=item C<ignore_zombies>

Boolean defaults to false unless the C<async> attribute is true in which case
this attribute also defaults to true. If true ignores child processes. If you
plan to call C<waitpid> to wait for the child process to finish you should
set this to false

=item C<in>

A L<File::DataClass::IO> object reference or a simple str. Defaults to null.
Determines where the standard input of the command will be redirected from.
Object references should stringify to the name of the file containing input.
A scalar is the input unless it is 'stdin' or 'null' which cause redirection
from standard input and the null device

=item C<keep_fhs>

An array reference of file handles that are to be left open in detached
children

=item C<log>

A log object defaults to an instance of L<Class::Null>. Calls are made to
it at the debug level

=item C<max_pidfile_wait>

Positive integer defaults to 15. The maximum number of seconds the parent
process should wait for the child's PID file to appear and be populated

=item C<nap_time>

Positive number defaults to 0.3. The number of seconds to wait between testing
for the existence of the child's PID file

=item C<out>

A L<File::DataClass::IO> object reference or a simple str. Defaults to null.
Determines where the standard output of the command will be redirected to.
Values include;

=over 3

=item C<null>

Redirect to the null device as defined by L<File::Spec>

=item C<stdout>

Output is not redirected to standard output

=item C<$object_ref>

The object reference should stringify to the name of a file to which standard
output will be redirected

=back

=item C<partition_cmd>

Boolean default to true. If the L<IPC::Run> implementation is selected the
command array reference will be partitioned on meta character boundaries
unless this attribute is set to false

=item C<pidfile>

A L<File::DataClass::IO> object reference. Defaults to a temporary file
in the configuration C<rundir> which will automatically unlink when closed

=item C<rundir>

A L<File::DataClass::IO> object reference. Defaults to the C<tempdir>
attribute. Directory in which the PID files a stored

=item C<tempdir>

A L<File::DataClasS::IO> object reference. Defaults to C<tmpdir> from
L<File::Spec>. The directory for storing temporary files

=item C<timeout>

Positive integer defaults to 0. If greater then zero an alarm will be raised
after this many seconds if the external command has not completed

=item C<use_ipc_run>

Boolean defaults to false. If true forces the use of the L<IPC::Rum>
implementation

=item C<use_system>

Boolean defaults to false. If true forces the use of the C<system>
implementation

=item C<working_dir>

A L<File::DataClass::IO> object reference. Defaults to null. If set the child
will C<chdir> to this directory before executing the external command

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

   $obj_ref = Class::Usul::IPC::Cmd->new( cmd => ..., out => ... );
   $obj_ref = Class::Usul::IPC::Cmd->new( { cmd => ..., out => ... } );
   $obj_ref = Class::Usul::IPC::Cmd->new( $cmd, out => ... );
   $obj_ref = Class::Usul::IPC::Cmd->new( $cmd, { out => ... } );
   $obj_ref = Class::Usul::IPC::Cmd->new( $cmd );

The constructor accepts a list of keys and values, a hash reference, the
command followed by a list of keys and values, the command followed by a
hash reference

=head2 C<BUILD>

Set chomp and lock on the C<pidfile>

=head2 C<run_cmd>

   $response_object = Class::Usul::IPC::Cmd->run_cmd( $cmd, @args );

Can be called as a class method or an object method

Runs a given external command. If the command argument is an array reference
the internal C<fork> and C<exec> implementation will be used, if a string is
passed the L<IPC::Open3> implementation will be use instead

Returns a L<Class::Ususl::Response::IPC> object reference

=head1 Diagnostics

Passing a logger object reference in with the C<log> attribute will cause
the C<run_cmd> method to log at the debug level

=head1 Dependencies

=over 3

=item L<Class::Null>

=item L<File::DataClass>

=item L<Module::Load::Conditional>

=item L<Moo>

=item L<Sub::Install>

=item L<Try::Tiny>

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Usul.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

L<MooseX::Daemonize> - Stole some code from that module

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
