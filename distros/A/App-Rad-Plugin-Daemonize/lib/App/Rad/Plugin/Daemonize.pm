package App::Rad::Plugin::Daemonize;
use POSIX      ();
use File::Temp ();
use Carp       ();

########## POD Begin ###################

=head1 NAME
App::Rad::Plugin::Daemonize

It's just an awesome plugin for Rad, that allows you to turn your Rad applications into daemons! 

start | stop | restart your Rad Application!

=head1 VERSION
current version here

=cut

our $VERSION = '0.1.7';


=head1 SYNOPSIS

If you reached here you probably know Rad, but if  you don't, please take a quick look on App::Rad, it is the basis for this plugin, that helps you
to make daemons very quickly.

# TODO : get the example simpler than that (not passing configuration parameters and with sample code more simple 

Let us show you the first test daemon :

	#!/usr/bin/perl
	use App::Rad qw/Daemonize/;
	App::Rad->run;

	sub setup {
	   my $c = shift;
	   $c->daemonize(\&test, use_cmd_args => 1, stderr_logfile => "./test_err.log", stdout_logfile => "./test_out.log")
	}
	sub test {
	   while(sleep 1){
	      print "OUT: ", $count++, $/;
	      print { STDERR } "ERR: ", $count, $/;
	      warn "WARN: ", $count++, $/;
	   }
	}

That's it!! We have our first example

As you see, you have to care with the infinite repetition structure on your sub, it's just write the sub and daemonize it.

=head1 Configuring your daemon 

Here will be described the options you can change on your daemon, like PID file, and log files. 

You also can choose to configure it on the command line, like : #./mydaemon start --option1="value" Or you can configure inside your program.
The second one is recommended if suits best for you. Now you will learn to pass some parameters to your daemon, note that if you don't set them they will assume the standard value (files on the same dir of the binary) and user root :

=head2 Setup built in the code

Let us take the first deamon example setup (the only line that matters is the $c->daemonize, so let's analyze it):

$c->daemonize(\&test, use_cmd_args => 1, stderr_logfile => "./test_err.log", stdout_logfile => "./test_out.log")

 * First parameter -> Reference to the sub you want to daemonize. Remember that you have to care about the infinite repetition of the sub on your code.
All your daemon's code should be there.

 * The rest of the parameters will be listed here one by one, as you can use them in any order, as they're keys/values of a hash

  - use_cmd_args - This sub isnt here, so i dont remember <revise before CPAN> it sets how your parameters will be set, on the daemonize method directly or on the command line (ex: $./mydaemon.pl start --pid_file="/tmp/mydaemon.pid") : If set to true, it will listen to the method's parameters, if set to one, command-line parameters

  - pid_file - where will be located the file containing the PID of the running daemon.

	WARNING! If you want to do a coherent logging system for your daemon read carefully these two paremeters :

  - stdout_logfile - Obviously sets where it will be > all that would be printed on the STDOUT of your daemon goes to that file

  - stderr_logfile - Analog to stdout_logfile but for STDERR, you're free to put both together on the same file.

  - proc_name - Yes! We thought about you doing a `ps aux | grep mydaemon` and getting the whole ugly command line you gave, so this sets the name of the running daemon, for example, just "mydaemon" (yes, you will see it on ps aux, and just that)

  - user - The user that will run your daemon; If you care about security you will want to avoid exploits that run as root, so setting this you set the user that will own the running process

=head2 Setup on the command-line

This is more simpler than the before, and will be useful if you wanna do something that the user won't need to open the source files to configure your daemon.

The options are the same as the listed above. Just that you have to specify as command-line options :

	#./mydaemon.pl start --pid_file="/tmp/mydaemon.pid" --user="foo" --proc_name="mydaemon"

## continue on the next push


=cut

sub after_detach {
   my $c    = shift;
   #my %pars = @_;
   my %pars = $c->get_daemonize_pars;

   $c->write_pidfile($pars{pid_file});
   $c->change_procname($pars{proc_name}) if $c->check_root;
   $c->chroot($pars{chroot_dir}) if $^O ne "MSWin32" and $c->check_root; # TODO: Make it work on windows
   $c->change_user($pars{user}) if exists $pars{user};
   $c->signal_handlers($pars{signal_handlers});
   if(exists $pars{stdout_logfile}) {
     open STDOUT, '>>', $pars{stdout_logfile};
   } else {
      close STDOUT;
   }
   if(exists $pars{stderr_logfile}) {
      open STDERR, '>>', $pars{stderr_logfile};
   } else {
      close STDERR;
   }
}

sub set_daemonize_pars {
   my $c = shift;
   $c->stash->{daemonize_pars} = {@_};
}
sub get_daemonize_pars {
   my $c    = shift;
   my %pars = %{ $c->stash->{daemonize_pars} };
   if(exists $pars{use_cmd_args} and $pars{use_cmd_args}) {
      my %options = %{ $c->options };
      for my $opt (keys %options) {
         next if exists $pars{$opt};
         $pars{$opt} = $options{$opt};
      }
   }
   %pars;
}

sub daemonize {
   my $c    = shift;
   my $func = shift;
   my %pars = @_;
   $c->set_daemonize_pars(%pars);
   $c->register("Win32_Daemon", sub {
                                     my $c = shift;
                                     my %pars = $c->get_daemonize_pars;
                                     $c->after_detach(%pars);
                                     $func->($c);
                                    }) if $^O eq "MSWin32";
   $c->register("stop"   , sub{
                              my $c = shift;
                              my %pars = $c->get_daemonize_pars;
                              Carp::croak "You are not root" 
                                 if ($pars{check_root} and exists $pars{check_root})
                                    and not $c->check_root;
                              Carp::carp "$0 is not running" unless $c->is_running($pars{pid_file});
                              "Stopping $0 (" . $c->read_pidfile . "): " . ($c->stop ? "OK$/" : "Failed$/")
                           });
   $c->register("restart", sub{
                              my $c = shift;
                              my %pars = $c->get_daemonize_pars;
                              Carp::croak "You are not root" 
                                 if ($pars{check_root} and exists $pars{check_root})
                                    and not $c->check_root;
                              $c->execute("stop");
                              sleep 2;
                              $c->execute("start");
                           });
   $c->register("status" , sub{
                              my $c = shift;
                              my %pars = $c->get_daemonize_pars;
                              Carp::croak "You are not root" 
                                 if ($pars{check_root} and exists $pars{check_root})
                                    and not $c->check_root;
                              $c->is_running($pars{pid_file}) ? "$0 is running (PID: "
                                . $c->read_pidfile . ")" : "$0 is not running"
                           });
   $c->register("start"  , sub{
                              my $c = shift;
                              my %pars = $c->get_daemonize_pars;
                              Carp::croak "You are not root" 
                                 if ($pars{check_root} and exists $pars{check_root})
                                    and not $c->check_root;
                              if ($c->is_running($pars{pid_file})) {
                                 Carp::carp "$0 is already running (PID: " . $c->read_pidfile . ")";
                                 "Starting $0 (PID: " . $c->read_pidfile . "): Failed$/";
                              }
                              else {
                                 my $daemon_pid = $c->detach unless $pars{no_detach};
                                 print "Starting $0 (PID: $daemon_pid): OK$/";
                                 if($^O ne "MSWin36") {
                                    $c->after_detach(%pars);
                                    $func->($c);
                                 }
                              }
                           });
   1
}

sub detach {
   my $c = shift;

   if($^O ne "MSWin32"){
      umask(0);
      $SIG{'HUP'} = 'IGNORE';
      my $child = fork();

      if($child < 0) {
          Carp::croak "Fork failed ($!)";
      }

      if( $child ) {
          exit 0;
      }

      close(STDIN);
      POSIX::setsid || Carp::croak "Can't start a new session: $!";
      return $$
   } else {
      require Win32::Process;
      my $proc;
      Win32::Process::Create(
                             $proc,
                             qq{$^X},
                             "perl $0 Win32_Daemon "
                                . (
                                   join " ", @ARGV
                                  ),
                             0,
                             Win32::Process->DETACHED_PROCESS,
                             ".",
                            );
      return $proc->GetProcessID
   }
}

sub chroot {
   my $c   = shift;
   my $dir = shift;

   $dir = File::Temp::tmpnam unless defined $dir;
   mkdir $dir and $c->stash->{chroot_dir} = $dir;

   chroot $dir;
}

sub change_user {
   my $c    = shift;
   my $user = shift;
   my $uid;

   if($user =~ /^\d+$/){
      $uid = $user;
   } else {
      $uid = getpwnam($user);
   }
   defined $uid or die "User \"$user\" do not exists";
   POSIX::setuid($uid);
}

sub check_root {
   my $c = shift;
   $< == 0;
}

sub change_procname {
   my $c    = shift;
   my $name = shift;
   ($name = $0) =~ s{^.*/}{} unless defined $name;
   $0 = $name;
}

sub get_pidfile_name {
   my $c = shift;
   my $file;
   if(not exists $c->stash->{pid_file}) {
      ($file = $0) =~ s{^.*/}{};
      $file =~ s/\./_/g;
      $file = ".$file.pid";
      $file = $c->path . "/$file";
   } else {
      $file = $c->stash->{pid_file};
   }
   $file
}

sub set_pidfile_name {
   my $c    = shift;
   my $file = shift;
   $c->stash->{pid_file} = $file if defined $file;
}

sub write_pidfile {
   my $c    = shift;
   my $file = shift;

   $c->set_pidfile_name($file);
   $file = $c->get_pidfile_name;
   open my $PIDFILE, ">", $file;
   my $ret = print {$PIDFILE} $$, $/;
   close $PIDFILE;
   return unless -f $file;
   $ret
}

sub read_pidfile {
   my $c    = shift;
   my $file = shift;
   $c->set_pidfile_name($file);
   $file = $c->get_pidfile_name;
   return unless -f $file;
   open my $PIDFILE, "<", $file;
   my $ret = scalar <$PIDFILE>;
   close $PIDFILE;
   chomp $ret;
   $ret
}

sub stop {
   my $c    = shift;
   my $file = shift;

   my $ret;
   if($^O ne "MSWin32") {
      $ret = $c->kill(15, $file);
   } else {
      require Win32::Process;
      $ret = Win32::Process::KillProcess($c->read_pidfile($file), 0);
   }
   $ret
}

sub kill {
   my $c      = shift;
   my $signal = shift;
   my $file   = shift;

   my $pid = $c->read_pidfile($file);
   return unless defined $pid and $pid;
   kill $signal => $pid;
}

sub is_running {
   my $c    = shift;
   my $file = shift;

   my $ret;
   if($^O ne "MSWin32") {
      $ret = $c->kill(0, $file);
   } else {
      require Win32::Process;
      $ret = Win32::Process::Open(my $obj, $c->read_pidfile($file), my $flags);
   }
   $ret
}

sub signal_handlers {
   my $c = shift;
   my $funcs;
   my $count;
   if(ref $_[0] eq "HASH") {
      $funcs = shift;
   } else {
      $funcs = { @_ };
   }

   for my $sig (keys %$funcs) {
      my $func = $funcs->{ $sig };
      $SIG{ $sig } = sub{$func->($c)} and $count++;
   }
   $count
}

42
