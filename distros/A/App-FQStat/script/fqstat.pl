#!/usr/bin/perl
use 5.008;
# fqstat.pl (version see FQStat.pm) is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
use strict;
use warnings;
use threads;
use threads::shared;

use IO::Handle;
use Time::HiRes qw/sleep time/;
use Term::ANSIScreen qw/RESET cls/;
use Term::ReadKey;
use Getopt::Long;

use constant DEBUG => 0;
use constant STARTTIME => Time::HiRes::time();

###################
# prepare for logging if in debug mode
BEGIN {
  use vars qw/*DEBUGFH/;
  my $DEBUGFH;
  sub debug ($) {
    require FileHandle;
    my $arg = shift;
    return if not DEBUG;
    if (not $DEBUGFH) {
      $DEBUGFH = FileHandle->new();
      $DEBUGFH->open('fqstat.debug', '>>') or die $!;
      $DEBUGFH->autoflush(1);
      *DEBUGFH = $DEBUGFH;
    }
    chomp $arg;
    print $DEBUGFH $arg."\n";
  }

  debug("Setting up debug mode");
  open(STDERR, ">&DEBUGFH");
}

######################
# Record key constants
use constant {
  F_id => 0,
  F_prio => 1,
  F_name => 2,
  F_user => 3,
  F_status => 4,
  F_date => 5,
  F_time => 6,
  F_queue => 7,
};

use constant RECORD_KEY_CONSTANT => {
  id => F_id, prio => F_prio, name => F_name,
  user => F_user, status => F_status, date => F_date,
  'time' => F_time, queue => F_queue,  
};
use constant RECORD_CONSTANT_KEY => [
  qw/ id prio name user status date time queue /
];



################
# load local modules
use App::FQStat;
our $VERSION = $App::FQStat::VERSION;
use App::FQStat::Input qw/get_input_key/;
use App::FQStat::Drawing qw/printline/;
use App::FQStat::Debug;

use vars qw/%SIG/;
autoflush STDIN 1;
ReadMode 3;
$|=1;

##############
# Declare globals

# action & key globals
use constant KEY_POLL_INTERVAL => 0.2;  # blocking time for keyboard polling
our %Keys;                              # hash of key => action for main loop
our %ControlKeys;                       # hash of control key id => action for main loop
our %MenuKeys;                          # hash of key => action for menu 
our %MenuControlKeys;                   # hash of control key id => action for menu
our %SummaryKeys;
our %SummaryControlKeys;

# twiddly globals
use constant PROGRESS_INDICATORS => ['-', '\\', '|', '/']; # progress indicator states
our $ProgressIndicator = 0;             # progress indicator current state number

# displaying globals
our $Initialized = 0;
our @Termsize : shared;                 # holds terminal size
our $DisplayOffset : shared = 0;        # Offset of the first displayed job
our $SortField : shared;                # may hold name of sort field

our $Interval : shared;                 # Effective data refreshing interval. Do not change. Is set to $UserInterval below
our $HighlightUser;
{
  my $curuser = $ENV{USER};
  if (defined $curuser) {
    $HighlightUser = quotemeta($curuser);
  }
}

# application mode globals
our $MenuMode            = 0; # in menu or not
our $SummaryMode :shared = App::FQStat::Config::get("summary_mode") || 0; # in summary mode or not

# menu globals
our $MenuNumber      = 0; # which menu (see @App::FQStat::Menu::Menus)
our $MenuEntryNumber = 0; # in which entry of that menu


# Displayed column descriptions
our %Columns =  (
  prio   => { format => '%.5f',  width => 7,  name => 'Prio',  key => 'prio',  'index' => F_prio,  order => 'num_highlow' },
  name   => { format => '%-10s', width => 10, name => 'Name',  key => 'name',  'index' => F_name,  order => 'alpha'       },
  user   => { format => '%-12s', width => 12, name => 'Owner', key => 'user',  'index' => F_user,  order => 'alpha'       },
  id     => { format => '%7u',   width => 7,  name => 'Id',    key => 'id',    'index' => F_id,    order => 'num'         },
  date   => { format => '%-10s', width => 10, name => 'Date',  key => 'date',  'index' => F_date,  order => 'date'        },
  'time' => { format => '%-8s',  width => 8,  name => 'Time',  key => 'time',  'index' => F_time,  order => 'time'        },
  queue  => { format => '%30s',  width => 30, name => 'Queue', key => 'queue', 'index' => F_queue, order => 'alpha'       },
);
# Column order
our @Columns = qw(id name prio user date time queue);

# Summary Mode: Displayed column descriptions
our %SummaryColumns =  (
  user    => { format => '%-12s', width => 12, name => 'Owner',       key => 'user',    'index' => 0, order => 'alpha'       },
  name    => { format => '%-12s', width => 12, name => 'Name-Like',   key => 'name',    'index' => 1, order => 'alpha'       },
  n_run   => { format => '%-5u',  width => 5,  name => 'NRun',        key => 'nrun',    'index' => 2, order => 'num'         },
  n_err   => { format => '%-5u',  width => 5,  name => 'NErr',        key => 'nerr',    'index' => 3, order => 'num'         },
  n_hld   => { format => '%-5u',  width => 5,  name => 'NHold',       key => 'nhold',   'index' => 4, order => 'num'         },
  n_wait  => { format => '%-5u',  width => 5,  name => 'NWait',       key => 'nwait',   'index' => 5, order => 'num'         },
  prio    => { format => '%.6f',  width => 8,  name => 'AvrgPrio',    key => 'prio',    'index' => 6, order => 'num_highlow' },
  'time'  => { format => '%-11s', width => 11, name => 'AvrgRunTime', key => 'time',    'index' => 7, order => 'time'        },
  maxtime => { format => '%-11s', width => 11, name => 'MaxRunTime',  key => 'maxtime', 'index' => 9, order => 'time'        },
);
# Summary Mode: Column order
our @SummaryColumns = qw(user name n_run n_err n_hld n_wait prio time maxtime);


# Data structure to hold information about the current state of affairs
our $Records = [];
our $RecordsChanged : shared = 0;
our $RecordsReversed : shared = 0;
our $NoActiveNodes = 0;
our $Summary = [];

# scanner thread globals, see below.

##############
# Get Command line arguments
our $User : shared;
our $UserInterval = 30;
our $SlowRedraw = 0;
my $SSHCommand;
our $ResetConfig;
Getopt::Long::Configure("no_ignore_case");
GetOptions(
  'u|user=s' => \$User,
  'H|highlight=s' => \$HighlightUser,
  'i|interval=f' => \$UserInterval,
  's|slow' => \$SlowRedraw,
  'ssh=s' => \$SSHCommand,
  'resetconfig' => \$ResetConfig,
  'h|help|?' => sub {
    ReadMode 1;
    print RESET;
    print usage();
    thread_cleanup();
    exit(1);
  },
);
$UserInterval ||= 30;
$Interval = $UserInterval; # start out with requested interval

##############
# Get/prepare configuration
if ($ResetConfig) {
  App::FQStat::Config::reset_configuration();
  App::FQStat::Config::save_configuration();
  cleanup_and_exit();
}

if (defined $SSHCommand) {
  App::FQStat::Config::set("sshcommand", $SSHCommand);
}

#################
# Default qstat paths
our $QStatCmd  = App::FQStat::Config::get("qstat") || 'qstat';
our $QDelCmd   = App::FQStat::Config::get("qdel") || 'qdel';
our $QAlterCmd = App::FQStat::Config::get("qalter") || 'qalter';
our $QModCmd   = App::FQStat::Config::get("qmod") || 'qmod';

###################
# Check that we can run qstat and friends

if (not App::FQStat::System::module_install_can_run($QStatCmd)) {
  print <<HERE;
ERROR!
You cannot run fqstat without having a working "qstat" command in your
application search path. Please add a "qstat" to \$PATH and retry.
(Or use the --ssh option correctly.)

HERE
  print RESET;
  thread_cleanup();
  ReadMode 1;
  exit(1);
}

# XXX Check for qdel and qalter too?

###################
# setup scanner thread
our $ScannerStartRun : shared = 0;
our $ScannerThread;# = threads->new(\&App::FQStat::Scanner::scanner_thread);

# thread exit handler
sub thread_cleanup {
  warnenter if ::DEBUG;
  if (defined $ScannerThread and $ScannerThread->is_running()) {
    print "Cleaning up polling threads...\n";
    $ScannerThread->kill('SIGKILL');
  }
}

# exit handler
sub cleanup_and_exit {
  warnenter if ::DEBUG;
  print RESET;
  Term::ANSIScreen::locate($Termsize[1],1);
  thread_cleanup();
  ReadMode 1;
  print "Have a nice day!\n" unless @_;
  exit();
}

$SIG{INT} = \&cleanup_and_exit;
$SIG{HUP} = \&cleanup_and_exit;
$SIG{TERM} = \&cleanup_and_exit;
$SIG{__DIE__} = sub{warn @_;ReadMode 1;exit(1);};

###########################
# RUN
GetTermSize();
cls();
App::FQStat::Drawing::update_display(1);

print_module_versions() if ::DEBUG;
%PAR::FileCache = %PAR::FileCache = () if exists $ENV{PAR_TEMP};
main_loop();
exit(0);

##############################
# Update @TermSize variable
sub GetTermSize {
  warnenter if ::DEBUG > 2;
  @Termsize = Term::ReadKey::GetTerminalSize();
  @Termsize = (80,25,0,0) if not @Termsize == 4;
}

####################
# MAIN LOOP

BEGIN {
  %ControlKeys = (
    'A'  => sub { App::FQStat::Actions::scroll_up(1); 1 },                # up
    'B'  => sub { App::FQStat::Actions::scroll_down(1); 1 },              # down
    '5'  => sub { App::FQStat::Actions::scroll_up($Termsize[1]-4); 1 },   # pgup
    '6'  => sub { App::FQStat::Actions::scroll_down($Termsize[1]-4); 1 }, # pgdown
    'H'  => sub { App::FQStat::Actions::scroll_up(1e9); 1 },              # pos1 (640kb ought to be enough for everyone!)
    'F'  => sub { App::FQStat::Actions::scroll_down(1e9); 1 },            # end (640kb ought to be enough for everyone!)
    '15' => sub { App::FQStat::Drawing::update_display(1) },              # F5
    '21' => sub { App::FQStat::Menu::toggle_menu() },                     # F10
  );

  %Keys = (
    'q' => \&cleanup_and_exit,
    'i' => \&App::FQStat::Actions::set_user_interval,
    'H' => \&App::FQStat::Actions::update_highlighted_user_name,
    'r' => \&App::FQStat::Actions::toggle_reverse_sort,
    's' => \&App::FQStat::Actions::select_sort_field,
    'u' => \&App::FQStat::Actions::update_user_name,
    'k' => \&App::FQStat::Actions::kill_jobs,
    'p' => \&App::FQStat::Actions::change_priority,
    'o' => \&App::FQStat::Actions::hold_jobs,
    'O' => \&App::FQStat::Actions::resume_jobs,
    'h' => \&App::FQStat::Actions::show_manual,
    '?' => \&App::FQStat::Actions::show_manual,
    'c' => \&App::FQStat::Actions::clear_job_error_state,
    'd' => \&App::FQStat::Actions::change_dependencies,
    ' ' => \&App::FQStat::Actions::show_job_details,
    "\n" => \&App::FQStat::Actions::show_job_details,
    'l' => \&App::FQStat::Actions::show_job_log,
    'S' => \&App::FQStat::Actions::toggle_summary_mode,
  );

  # copy of the key maps for the menu
  %MenuControlKeys = %ControlKeys;
  delete $MenuControlKeys{$_} foreach qw(5 6 H F); # pg-up, pg-down, home, end
  $MenuControlKeys{A}    = \&App::FQStat::Menu::menu_up,     # up-arrow
  $MenuControlKeys{B}    = \&App::FQStat::Menu::menu_down,   # down-arrow
  $MenuControlKeys{C}    = \&App::FQStat::Menu::menu_right,  # right-arrow
  $MenuControlKeys{D}    = \&App::FQStat::Menu::menu_left,   # left-arrow
  
  %MenuKeys = %Keys;
  $MenuKeys{"\n"} = \&App::FQStat::Menu::menu_select, # Enter
  $MenuKeys{" "}  = \&App::FQStat::Menu::menu_select, # space
  delete $MenuKeys{$_} foreach qw(S);

  %SummaryKeys = map {($_ => $Keys{$_})} qw(q i h S);
  $SummaryKeys{c} = \&App::FQStat::Actions::toggle_summary_name_clustering;
  $SummaryKeys{s} = $SummaryKeys{S};
  %SummaryControlKeys = map {($_ => $ControlKeys{$_})} qw(15 21);
}

my @OldTermSize = @Termsize;
sub main_loop {
  warnenter if ::DEBUG;
  my $Redraw = 1;
  my $RedrawTime = time();
  my $RedrawOffset = $DisplayOffset;
  while (1) {
    my $input = get_input_key();
    if (defined $input) {
      my ($KeysHash, $ControlKeysHash);
      if ($MenuMode) {
        $KeysHash = \%MenuKeys;
        $ControlKeysHash = \%MenuControlKeys;
      }
      elsif ($SummaryMode) {
        $KeysHash = \%SummaryKeys;
        $ControlKeysHash = \%SummaryControlKeys;
      }
      else {
        $KeysHash = \%Keys;
        $ControlKeysHash = \%ControlKeys;
      }

      #warn "-I->$input<---->".ord($input);
      if ($KeysHash->{$input}) {
        my $redraw = $KeysHash->{$input}->($input);
        $Redraw = 1 if $redraw;
      }
      
      elsif ($input eq '[') { # control-key!
        my $key = get_input_key(0.001);
        #warn "-K->$key<---->".ord($key);
        if (defined $key and exists $ControlKeysHash->{$key}) {
          my $redraw = $ControlKeysHash->{$key}->($key);
          $Redraw = 1 if $redraw;
        }
        elsif ($key eq '1' or $key eq '2') { # F-keys
          my $innerkey = get_input_key(0.001);
          #warn "-IK->$innerkey<---->".ord($innerkey);
          if (defined $innerkey and exists($ControlKeysHash->{"$key$innerkey"})) {
            my $redraw = $ControlKeysHash->{"$key$innerkey"}->("$key$innerkey");
            $Redraw = 1 if $redraw;
          }
        }
      } # end control keys
    } # end if defined input

    # Fetch new scanner results if applicable
    if (defined $ScannerThread and $ScannerThread->is_joinable()) {
      warnline "Scanner thread joinable in main loop. Joining" if ::DEBUG;
      my $return = $ScannerThread->join();
      ($Records, $NoActiveNodes) = @$return;
      $Initialized = 1;
      warnline "Scanner thread joined in main loop" if ::DEBUG;
      lock($RecordsChanged);
      $RecordsChanged = 1;
      $Summary = [];
    }

    my $startRun;
    {
      lock($ScannerStartRun);
      $startRun = $ScannerStartRun;
    }
    if ($startRun) {
      App::FQStat::Scanner::run_qstat();
    }

    {
      lock($RecordsChanged);
      lock($DisplayOffset);
      $Redraw = 1 if $RecordsChanged;
      $Redraw = 1 if $DisplayOffset != $RedrawOffset;
    }
    GetTermSize();
    $Redraw = 1 if !@OldTermSize or $OldTermSize[0] != $Termsize[0] or $OldTermSize[1] != $Termsize[1];

    @OldTermSize = @Termsize;
    $Redraw = 1 if time()-$RedrawTime > ($SlowRedraw ? 20.0 : 3.0); 

    if ($Redraw) {
      App::FQStat::Drawing::update_display();
      $RedrawOffset = $DisplayOffset;
      $Redraw = 0;
      lock($RecordsChanged);
      $RecordsChanged = 0;
      $RedrawTime = time();
      restart() if $RedrawTime - STARTTIME() > 4*60*60; # restart every four hours (wallclock)
    }
  } # end while(1)
}

sub print_module_versions {
  warnenter if ::DEBUG;
  foreach my $file (sort keys %INC) {
    my $path = $INC{$file};
    my $module = $file;
    $module =~ s/\.pm$//;
    $module =~ s/\//::/g;
    my $version;
    eval "\$version = $module->VERSION;";
    $version = 'undef' if not defined $version;
    debug("$module ($version): $path\n");
  }
}


sub restart {
  warnenter if ::DEBUG;
  my @args;
  push @args, '-u', $User
    if defined $User and $User ne '';
  push @args, '-H', $HighlightUser
    if defined $HighlightUser and $HighlightUser ne '';
  push @args, '-i', $UserInterval
    if defined $UserInterval and $UserInterval ne '';
  push @args, '--slow' if $SlowRedraw;
  push @args, '--ssh', $SSHCommand
    if defined $SSHCommand and $SSHCommand ne '';

  my @cmd;
  if (exists $INC{"PAR.pm"}) {
    @cmd = ($ENV{PAR_PROGNAME}, @args);
  }
  else {
    my @inc = map {('-I', $_)} @INC;
    @cmd = ($^X, @inc, $0, @args);
  }
  App::FQStat::System::exec_local(@cmd);
}


sub usage () {
  warnenter if ::DEBUG;
  <<'USAGE';

fqstat - Interactive front-end for qstat

  Valid options are: (defaults in parenthesis)
    -h or --help:      Print this short manual
    -u or --user:      Set the user whose jobs to display (all users)
    -i or --interval:  Set the data refresh interval (30)
    -H or --highlight: Highlight jobs of this user (none)
    -s or --slow:      Set slow connection, rare redrawing 
    --ssh='ssh user@host'  Runs 'qstat' and friends on a remote host
    --resetconfig      Resets the configuration file to initial state.

  You can get online help by hitting 'h' while running fqstat.

fqstat is (c) 2007-2009 Steffen Mueller.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

USAGE
}

