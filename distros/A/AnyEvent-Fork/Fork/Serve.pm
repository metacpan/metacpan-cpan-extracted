package AnyEvent::Fork::Serve;

our $OWNER; # pid of process "owning" us

# commands understood:
# e_val perlcode string...
# f_ork
# h_andle + fd
# a_rgs string...
# r_un func

# the goal here is to keep this simple, small and efficient
sub serve {
   local $^W = 0; # avoid spurious warnings

   undef &me; # free a tiny bit of memory

   my $master = shift;

   my @arg;

   my ($cmd, $fd);

   my $error = sub {
      warn "[$0] ERROR: $_[0]\n";
      last;
   };

   local *run_args = sub () { # AnyEvent::Fork::Serve::run_args
      my (@ret, @arg) = @arg; # copy and clear @arg
      @ret
   };

   while () {
      # we manually reap child processes before we sleep, as local $SIG...
      # will destroy existing child handlers instead of restoring them.
      1 while 0 < waitpid -1, 1; # WNOHANG is portably 1. prove me wrong.

      # we must not ever read "too much" data, as we might accidentally read
      # an IO::FDPass::send request.

      my $len;
      sysread $master, $len, 5 - length $len, length $len or last
         while 5 > length $len;
      ($cmd, $len) = unpack "a L", $len;

      my $buf;
      sysread $master, $buf, $len - length $buf, length $buf or last
         while $len > length $buf;

      if ($cmd eq "h") {
         require IO::FDPass;
         $fd = IO::FDPass::recv (fileno $master);
         $fd >= 0 or $error->("AnyEvent::Fork::Serve: fd_recv() failed: $!");
         open my $fh, "+<&=$fd" or $error->("AnyEvent::Fork::Serve: open (fd_recv) failed: $!");
         push @arg, $fh;

      } elsif ($cmd eq "a") {
         push @arg, unpack "(w/a*)*", $buf;

      } elsif ($cmd eq "f") {
         my $pid = fork;

         if ($pid eq 0) {
            $0 = "$OWNER AnyEvent::Fork";
            $master = pop @arg;

         } else {
            pop @arg;

            $pid
               or $error->("AnyEvent::Fork::Serve: fork() failed: $!");
         }

      } elsif ($cmd eq "e") {
         ($cmd, @_) = unpack "(w/a*)*", $buf;

         # $cmd is allowed to access @_ and nothing else
         package main;
         eval $cmd;
         $error->("$@") if $@;
        
      } elsif ($cmd eq "r") {
         # we could free &serve etc., but this might just unshare
         # memory that could be shared otherwise.
         @_ = ($master, @arg);
         $0 = "$OWNER $buf";
         package main;
         goto &$buf;

      } else {
         $error->("AnyEvent::Fork::Serve received unknown request '$cmd' - stream corrupted?");
      }
   }

   shutdown $master, 1;
   exit; # work around broken win32 perls
}

# the entry point for new_exec
sub me {
   #$^F = 2; # should always be the case

   open my $fh, "+<&=$ARGV[0]"
      or die "AnyEvent::Fork::Serve::me unable to open communication socket: $!\n";

   $OWNER = $ARGV[1];

   $0 = "$OWNER AnyEvent::Fork/exec";

   @ARGV = ();
   @_ = $fh;
   goto &serve;
}

1

