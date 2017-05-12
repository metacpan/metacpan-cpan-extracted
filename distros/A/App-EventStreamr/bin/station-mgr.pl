#!/usr/bin/perl

use strict;
use v5.10;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Proc::Daemon; # libproc-daemon-perl
use JSON; # libjson-perl
use Config::JSON; # libconfig-json-perl
use HTTP::Tiny; # libhttp-tiny-perl
use Log::Log4perl; # liblog-log4perl-perl
use POSIX;
use File::Path qw(make_path);
use File::Basename;
use experimental 'switch';
use Getopt::Long;
use Data::Dumper;

# PODNAME: station-mgr

# ABSTRACT: station-mgr - Core Station Manager script

our $VERSION = '0.5'; # VERSION


my $DEBUG  = 0;
my $DAEMON = 1;

my $getopts_rc = GetOptions(
    "debug!"        => \$DEBUG,
    "daemon!"       => \$DAEMON,

    "help|?"        => \&print_usage,
);

# setup signal handlers and daemon stuff
# POSIX unmasks the sigprocmask properly
$SIG{CHLD} = 'IGNORE';
my $sigset = POSIX::SigSet->new();
my $update = POSIX::SigAction->new( 'self_update',
                                    $sigset,
                                    &POSIX::SA_NODEFER);
my $exit = POSIX::SigAction->new(   'sig_exit',
                                    $sigset,
                                    &POSIX::SA_NODEFER);
my $pipe = POSIX::SigAction->new(   'sig_pipe',
                                    $sigset,
                                    &POSIX::SA_NODEFER);
my $get = POSIX::SigAction->new(   'get_config',
                                    $sigset,
                                    &POSIX::SA_NODEFER);
my $post = POSIX::SigAction->new(   'post_config',
                                    $sigset,
                                    &POSIX::SA_NODEFER);
# Handle INT/Term
POSIX::sigaction(&POSIX::SIGTERM, $exit);
POSIX::sigaction(&POSIX::SIGINT, $exit);

# SIGHUP updates and execs
POSIX::sigaction(&POSIX::SIGHUP, $update);
POSIX::sigaction(&POSIX::SIGPIPE, $pipe);

# USR1/2 for get/post config
POSIX::sigaction(&POSIX::SIGUSR1, $get);
POSIX::sigaction(&POSIX::SIGUSR2, $post);

our $daemon = Proc::Daemon->new(
  work_dir => "$Bin/../",
);

our $daemons;
if ( $DAEMON ) {
  $daemon->Init();
}

# set umask
umask 0027;

# EventStremr Modules
use App::EventStreamr::Devices;
our $devices = App::EventStreamr::Devices->new();
use App::EventStreamr::Utils;
our $utils = App::EventStreamr::Utils->new();

# Load/Build Local Config
my $localconfig;
if (-e "$Bin/../settings.json") {
  $localconfig = Config::JSON->new("$Bin/../settings.json");
  $localconfig = $localconfig->{config};
} else {
  $localconfig = Config::JSON->create("$Bin/../settings.json");
  $localconfig->{config} = blank_settings();
  $localconfig->write;
  $localconfig = $localconfig->{config};
}

# Station Config
our $stationconfig;
if (-e "$Bin/../station.json") {
  $stationconfig = Config::JSON->new("$Bin/../station.json");
} else {
  $stationconfig = Config::JSON->create("$Bin/../station.json");
  $stationconfig->{config} = blank_station();
  $stationconfig->write;
} 

# Commands
my $commands = Config::JSON->new("$Bin/../commands.json");

# Own data 
our $self;
$self->{config} = $stationconfig->{config};
$self->{config}{macaddress} = getmac();
$self->{devices} = $devices->all();
$self->{commands} = $commands->{config};
$self->{dvswitch}{check} = 1; # check until dvswitch is found
$self->{dvswitch}{running} = 0;
$self->{settings} = $localconfig;
$self->{date} = strftime "%Y%m%d", localtime;
if ($self->{config}{run} == 2) {$self->{config}{run} = 1;}

# Logging
unless ( $DEBUG ) {
  $self->{loglevel} = 'INFO, LOG1' ;
} else {
  $self->{loglevel} = 'DEBUG, LOG1, SCREEN' ;
}

unless (-d "$Bin/../logs/") {
 make_path("$Bin/../logs/"); 
}

my $log_conf = qq(
  log4perl.rootLogger              = $self->{loglevel}
  log4perl.appender.SCREEN         = Log::Log4perl::Appender::Screen
  log4perl.appender.SCREEN.stderr  = 0
  log4perl.appender.SCREEN.layout  = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.SCREEN.layout.ConversionPattern = %m %n
  log4perl.appender.LOG1           = Log::Log4perl::Appender::File
  log4perl.appender.LOG1.utf8      = 1
  log4perl.appender.LOG1.filename  = $Bin/../logs/station-mgr.log
  log4perl.appender.LOG1.mode      = append
  log4perl.appender.LOG1.layout    = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.LOG1.layout.ConversionPattern = %d %p %m %n
);

Log::Log4perl::init(\$log_conf);
our $logger = Log::Log4perl->get_logger();
$logger->info("manager starting: pid=$$, station_id=$self->{config}->{macaddress}");

$daemons->{main}{run} = 1;

# HTTP
our $http = HTTP::Tiny->new(timeout => 15);

# Start the API
api();

# Register with controller
$logger->info("Registering with controller $localconfig->{controller}/api/station/$self->{config}{macaddress}");
my $response =  $http->post("$localconfig->{controller}/api/station/$self->{config}{macaddress}");

# Controller responds with created 201, post our config 
if ($response->{status} == 201) {
  $logger->info("Posting config $localconfig->{controller}");
  
  # Status Post Data
  my $json = to_json($self->{config});
  my %headers = (
        'station-mgr' => 1,
        'Content-Type' => 'application/json', 
  );
  my %post_data = ( 
        content => $json, 
        headers => \%headers,
  );

  $response =  $http->post("$localconfig->{controller}/api/station", \%post_data);
  
  $logger->debug({filter => \&Data::Dumper::Dumper,
                  value  => $response}) if ($logger->is_debug());
}


if ($response->{status} == 200 ) {
  my $content = from_json($response->{content});
  $self->{controller}{running} = 1;
  $logger->debug({filter => \&Data::Dumper::Dumper,
                  value  => $content}) if ($logger->is_debug());

  if (defined $content && $content ne 'true') {
    $self->{config} = $content->{settings};
    write_config();
  } else {
    write_config();
  }

  # Run all connected devices - need to get devices to return an array
  if ($self->{config}{devices} eq 'all') {
    $self->{config}{devices} = $self->{devices}{array};
  }

  $self->{config}{manager}{pid} = $$;
  post_config();
} elsif ($response->{status} == 204){
  $self->{controller}{running} = 1;
  $self->{config}{manager}{pid} = $$;
  $logger->warn("Connected but not registered");
  $logger->info("Falling back to local config");
  $logger->debug({filter => \&Data::Dumper::Dumper,
                  value  => $response}) if ($logger->is_debug());

  # Run all connected devices - need to get devices to return an array
  if ($self->{config}{devices} eq 'all') {
    $self->{config}{devices} = $self->{devices}{array};
  }
  post_config();
} else {
  chomp $response->{content};
  $self->{controller}{running} = 0;
  $self->{config}{manager}{pid} = $$;
  $logger->warn("Failed to connect: $response->{content}");
  $logger->info("Falling back to local config");
  $logger->debug({filter => \&Data::Dumper::Dumper,
                  value  => $response}) if ($logger->is_debug());

  # Run all connected devices - need to get devices to return an array
  if ($self->{config}{devices} eq 'all') {
    $self->{config}{devices} = $self->{devices}{array};
  }
  post_config();
}

# Debug logging of data
$logger->debug({filter => \&Data::Dumper::Dumper,
                value  => $self}) if ($logger->is_debug());

# Log when started
if ($self->{config}{run}) {
  $logger->info("Manager started, starting devices");
} else {
  $logger->info("Manager started, configuration set to not start devices.");
}

# Post start clearing of data
$self->{device_control}{record}{recordpath} = 0;

# Main Daemon Loop
while ($daemons->{main}{run}) {
  # If we're restarting, we should trigger check for dvswitch
  if ($self->{config}{run} == 2) {
    $logger->info("Restart Trigged");
    $self->{dvswitch}{check} = 1;
  }

  # Process the internal commands
  api();
  devmon();

  # Process the roles
  foreach my $role (@{$self->{config}->{roles}}) {
    given ( $role ) {
      when ("mixer")    { mixer();  }
      when ("ingest")   { ingest(); }
      when ("stream")   { stream(); }
      when ("record")   { record(); }
    }
  }

  # 2 is the restart all processes trigger
  # $daemon->Kill_Daemon does a Kill -9, so if we get here they procs should be dead. 
  if ($self->{config}{run} == 2) {
    $self->{config}{run} = 1;
  }

  # Until found check for dvswitch - continuously hitting dvswitch with an unknown client caused high cpu load
  unless ( $self->{dvswitch}{running} && ! $self->{dvswitch}{check} ) {
    if ( $utils->port($self->{config}->{mixer}{host},$self->{config}->{mixer}{port}) ) {
      $logger->info("DVswitch found Running");
      $self->{dvswitch}{running} = 1;
      $self->{dvswitch}{check} = 0; # We can set this to 1 and it will check dvswitch again.
    }
  }

  # Uncomment to enable heartbeat
  ## Post a hearbeat to the controller/mixer
  #if ((time % 10) == 0) {
  #  $logger->debug("Heartbeat!") if ($logger->is_debug());
  #  $self->{heartbeat} = time;
  #  post_config();
  #}
  
  # Update date if it's changed - I wonder if there is a better way to trigger this? Cron (requires more OS config)?
  unless ( $self->{date} == strftime "%Y%m%d", localtime) {
    $self->{date} = strftime "%Y%m%d", localtime;
    $self->{device_control}{record}{recordpath} = 0;
    $self->{config}{device_control}{record}{run} = 2;
    $self->{config}{device_control}{sync}{run} = 2;
  }
  sleep 1;
}



# ---- SUBROUTINES ----------------------------------------------------------

sub sig_exit {
      $logger->info("manager exiting...");
      $daemons->{main}{run} = 0;
      $daemon->Kill_Daemon($self->{device_control}{api}{pid}); 
      $daemon->Kill_Daemon($self->{device_control}{devmon}{pid}); 
      $daemon->Kill_Daemon($self->{device_control}{sync}{pid}); 
}

sub sig_pipe {
    $logger->debug( "caught SIGPIPE" ) if ( $logger->is_debug() );
}

sub self_update {
  $logger->info("Performing self update");
  $logger->debug("Update host: $Bin/../../baseimage/update-host.sh") if ($logger->is_debug());
  system("$Bin/../../baseimage/update-host.sh");
  sig_exit();
  my $options;
  $options = "--debug" if $DEBUG;
  $options = "$options --no-daemon" unless $DAEMON;
  my $script = File::Basename::basename($0);
  $logger->debug("Restart Manger: $Bin/$script $options") if ($logger->is_debug());
  exec("$Bin/$script $options") or $logger->logdie("Couldn't restart: $!");
}

sub print_usage {
  say "
Usage: station-mgr.pl [OPTIONS]

Options:
  --no-deaemon  disable daemon

  --debug       turn on debugging
  --help        this help text
";
  exit 0;
}

# Config triggers
sub post_config {
  # Refresh devices 
  $self->{devices} = $devices->all();

  # Post to manager api
  my $json = to_json($self);
  my %post_data = ( 
        content => $json, 
        'content-type' => 'application/json', 
        'content-length' => length($json),
  );

  my $post = $http->post("http://127.0.0.1:3000/internal/settings", \%post_data);
  $logger->info("Config Posted to API");
  $logger->debug({filter => \&Data::Dumper::Dumper,
                value  => $post}) if ($logger->is_debug());

  # Status information
  my $status;
  $status->{status} = $self->{status};
  $status->{macaddress} = $self->{config}{macaddress};
  $status->{nickname} = $self->{config}{nickname};
  # Uncomment for heartbeat
  #$status->{heartbeat} = $self->{heartbeat};

  # Post Headers
  my %headers = (
        'station-mgr' => 1,
        'Content-Type' => 'application/json',
  );

  $logger->debug({filter => \&Data::Dumper::Dumper,
                value  => $status}) if ($logger->is_debug());

  # Status Post Data
  $json = to_json($status);
  %post_data = ( 
        content => $json, 
        headers => \%headers, 
  );

  # Post Status to Mixer
  $post = $http->post("http://$self->{config}{mixer}{host}:3000/status/$self->{config}{macaddress}", \%post_data);
  $logger->info("Status Posted to Mixer API -> http://$self->{config}{mixer}{host}:3000/status/$self->{config}{macaddress}");
  $logger->debug({filter => \&Data::Dumper::Dumper,
                value  => $post}) if ($logger->is_debug());

  # Post Status + devices to Controller
  if ($self->{controller}{running}) {
    # Build post object
    my $data;
    $data->[0]{key} = "status";
    $data->[0]{value} = $status->{status};
    $data->[1]{key} = "devices";
    $data->[1]{value} = $self->{devices}{all};
    delete $data->[1]{value}{all};

    # Post data
    $json = to_json($data);
    # some bug and it's late this could cause hideous issues if 
    # a device id has a / in it, but this should be unlikely
    $json =~ s{/|\.}{}g;

    %post_data = ( 
          content => $json, 
          headers => \%headers, 
    );
    $logger->debug({filter => \&Data::Dumper::Dumper,
                  value  => $json}) if ($logger->is_debug());
    $post = $http->post("$localconfig->{controller}/api/stations/$self->{config}{macaddress}/partial", \%post_data);
    $logger->info("Status Posted to Controller API - $localconfig->{controller}/api/stations/$self->{config}{macaddress}/partial");
    $logger->debug({filter => \&Data::Dumper::Dumper,
                  value  => $post}) if ($logger->is_debug());
  }
  
  return;
}

sub get_config {
  my $get = $http->get("http://127.0.0.1:3000/internal/settings");
  my $content = from_json($get->{content});
  $self->{config} = $content->{config};
  $logger->debug({filter => \&Data::Dumper::Dumper,
                value  => $get}) if ($logger->is_debug());
  $logger->debug({filter => \&Data::Dumper::Dumper,
                value  => $self}) if ($logger->is_debug());
  $logger->info("Config recieved from API");
  write_config();
  return;
}

sub write_config {
  $stationconfig->{config} = $self->{config};
  $stationconfig->write;
  $logger->info("Config written to disk");
  return;
}

## api 
sub api {
  my $device;
  unless ($logger->is_debug()) {
    $self->{device_commands}{api}{command} = "/usr/bin/plackup -s Twiggy -p 3000 $Bin/station-api.pl --daemon --environment production";
  } else{
    $self->{device_commands}{api}{command} = "/usr/bin/plackup -s Twiggy -p 3000 $Bin/station-api.pl";
  }
  $device->{role} = "api";
  $device->{id} = "api";
  $device->{type} = "internal";
  run_stop($device);
  return;
}

## devmon 
sub devmon {
  my $device;
  $self->{device_commands}{devmon}{command} = "$Bin/station-devmon.pl";
  $device->{role} = "devmon";
  $device->{id} = "devmon";
  $device->{type} = "internal";
  run_stop($device);
  return;
}

## Ingest
sub ingest {
  if ($self->{dvswitch}{running} == 1) {
    foreach my $device (@{$self->{config}{devices}}) {
      # Set Role
      $device->{role} = "ingest";

      if ($device->{type} eq "dv") {
        # Check dv exists
        if (-e $self->{devices}{dv}{$device->{id}}{path}) {
          run_stop($device);
        # If we're restarting we should refresh the devices and try again
        } elsif ($self->{config}{device_control}{$device->{id}}{run} == 1) {
          $logger->warn("$device->{id} has been disconnected");
          # It's not ideal, but dvgrab hangs if no camera exist. devmon will restart it when it's plugged in again.
          $self->{config}{device_control}{$device->{id}}{run} = 0;
          run_stop($device);

          # Set status
          $self->{device_control}{$device->{id}}{timestamp} = time;
          $self->{status}{$device->{id}}{running} = 0;
          $self->{status}{$device->{id}}{status} = "disconnected";
          $self->{status}{$device->{id}}{state} = "hard";
          post_config();
        } elsif ($self->{config}{device_control}{$device->{id}}{run} == 2) {
          $logger->warn("$device->{id} has been restarted, refreshing devices");
          $self->{devices} = $devices->all();
          post_config();
          run_stop($device);
        } 
      } else {
        run_stop($device);
      }
    }
  }
  return;
}

## Mixer
sub mixer {
  my $device;
  $device->{role} = "mixer";
  $device->{id} = "dvswitch";
  $device->{type} = "mixer";
  run_stop($device);
  
  my $loop;
  if ($self->{config}{mixer}{loop} && $self->{dvswitch}{running}) {
    if (-e $self->{config}{mixer}{loop}) {
      $loop->{role} = "ingest";
      $loop->{id} = $self->{config}{mixer}{loop};
      $loop->{type} = "file";
      run_stop($loop);
    } else {
      # Set status
      $self->{device_control}{$loop->{id}}{timestamp} = time;
      $self->{status}{$loop->{id}}{running} = 0;
      $self->{status}{$loop->{id}}{status} = "file_not_found";
      $self->{status}{$loop->{id}}{state} = "hard";
      $self->{status}{$loop->{id}}{name} = "standby loop";
      post_config();
    }
  }
  return;
}

## Stream
sub stream {
  my $device;
  $device->{role} = "stream";
  $device->{id} = $self->{config}{stream}{stream};
  $device->{type} = "stream";
  run_stop($device);
  return;
}

## Record
sub record {
  my $device;
  $device->{role} = "record";
  $device->{id} = "record";
  $device->{type} = "record";

  # Get path (date + room)
  unless ($self->{device_control}{$device->{id}}{recordpath}) {
    $self->{device_control}{$device->{id}}{recordpath} = set_path($self->{config}{record_path});
    $logger->info("Path for $device->{id}: $self->{device_control}{$device->{id}}{recordpath}");
  }
  
  # Create the path if it doesn't exist
  unless(-d "$self->{device_control}{$device->{id}}{recordpath}") {
    my $result = eval { make_path("$self->{device_control}{$device->{id}}{recordpath}") };
    
    if ($result) {
      $logger->info("Path created for $device->{id}: $self->{device_control}{$device->{id}}{recordpath}");
      post_config();
    } else {

      # if above threshold then slow down attempts to every 10 seconds
      if ( $self->{device_control}{$device->{id}}{runcount} > 5 && (time % 10) != 0 ) {
        return;
      }

      $logger->error("Path creation failed for $device->{id}: $self->{device_control}{$device->{id}}{recordpath}");
      
      $self->{device_control}{$device->{id}}{runcount}++;
      # Set device status
      $self->{status}{$device->{id}}{type} = $device->{type};
      $self->{status}{$device->{id}}{timestamp} = time;
      $self->{status}{$device->{id}}{running} = 0;
      $self->{status}{$device->{id}}{status} = "not_writeable";
      $self->{status}{$device->{id}}{state} = "hard";
      post_config();
      
      return;
    }
  }

  if ($self->{dvswitch}{running} == 1) {
    run_stop($device);
  }
  sync();
  return;
}

## sync 
sub sync {
  my $device;
  $self->{device_commands}{sync}{command} = "$Bin/station-sync.sh $self->{device_control}{record}{recordpath} $self->{config}{sync}{host} $self->{config}{sync}{path} $self->{config}{room}";
  $device->{role} = "sync";
  $device->{id} = "sync";
  $device->{type} = "internal";
  if ($self->{config}{sync}{host} && $self->{config}{sync}{path}) {
    run_stop($device);
  } else {
    # set status
    $self->{status}{$device->{id}}{type} = $device->{type};
    $self->{status}{$device->{id}}{timestamp} = time;
    $self->{status}{$device->{id}}{running} = 0;
    $self->{status}{$device->{id}}{status} = "not_configured";
    $self->{status}{$device->{id}}{state} = "hard";
  }
  return;
}

# run, stop or restart a process 
sub run_stop {
  my ($device) = @_;
  my $time = time;

  # Build command for execution and save it for future use
  unless ($self->{device_commands}{$device->{id}}{command}) {
    given ($device->{role}) {
      when ("ingest")   { 
        $self->{device_commands}{$device->{id}}{command} = ingest_commands($device->{id},$device->{type});
        $logger->info("Command for $device->{id} - $device->{type}: $self->{device_commands}{$device->{id}}{command}");
      }
      when ("mixer")    { 
        $self->{device_commands}{$device->{id}}{command} = mixer_command(); 
        $logger->info("Command for $device->{id} - $device->{type}: $self->{device_commands}{$device->{id}}{command}");
      }
      when ("stream")   { 
        $self->{device_commands}{$device->{id}}{command} = stream_command($device->{id},$device->{type}); 
        $logger->info("Command for $device->{id} - $device->{type}: $self->{device_commands}{$device->{id}}{command}");
      }
      when ("record")   { 
        $self->{device_commands}{$device->{id}}{command} = record_command($device->{id},$device->{type}); 
        $logger->info("Command for $device->{id} - $device->{type}: $self->{device_commands}{$device->{id}}{command}");
      }
    }
  }

  # If we're supposed to be running, run.
  if (($self->{config}{run} == 1 && 
  (! defined $self->{config}{device_control}{$device->{id}}{run} || $self->{config}{device_control}{$device->{id}}{run} == 1)) ||
  $device->{type} eq 'internal') {
    # The failed service check depends on a run flag being set, if we got here it should be 1.
    $self->{config}{device_control}{$device->{id}}{run} = 1;

    # Get the running state + pid if it exists
    my $state;
    if ($self->{device_control}{$device->{id}}{pid}) {
      $state = $utils->get_pid_state($self->{device_control}{$device->{id}}{pid}); 
    } else {
      $state = $utils->get_pid_command($device->{id},$self->{device_commands}{$device->{id}}{command},$device->{type}); 
    }

    unless ($state->{running}) {

      # notice process is down, record timestamp when it went down
      if ( ! defined $self->{device_control}{$device->{id}}{timestamp} ) {
        $self->{device_control}{$device->{id}}{timestamp} = $time;
        $self->{device_control}{$device->{id}}{runcount} = 0;

        $self->{status}{$device->{id}}{running} = 0;
        $self->{status}{$device->{id}}{status} = "starting";
        $self->{status}{$device->{id}}{state} = "soft";
        $self->{status}{$device->{id}}{type} = $device->{type};
        $self->{status}{$device->{id}}{timestamp} = $self->{device_control}{$device->{id}}{timestamp};

        $logger->debug("Timestamp and Run Count initialised for $device->{id}");
      }

      # if above restart threshold then slow down restarts to every 10 seconds
      if ( $self->{device_control}{$device->{id}}{runcount} > 5 && ($time % 10) != 0 ) {
        return;
      }

      # log dvswitch start or device connecting 
      if ($device->{type} eq "mixer") {
        $logger->info("Starting DVswitch");
      } elsif ($device->{type} eq "internal") {
        $logger->info("Starting $device->{id}");
      } else {
        $logger->info("Connect $device->{id} to DVswitch");
      }
      
      # build daemon option
      my %proc_opts;
      unless ($logger->is_debug()) {
        %proc_opts = (
           exec_command => $self->{device_commands}{$device->{id}}{command},
        );
      } else {
        %proc_opts = (
           child_STDOUT => "/tmp/$device->{id}-STDOUT.log",
           child_STDERR => "/tmp/$device->{id}-STDERR.log", 
           exec_command => $self->{device_commands}{$device->{id}}{command},
        );
      }       
      # run process
      my $proc = $daemon->Init( \%proc_opts );

      # give the process some time to settle
      sleep 1;
      # Set the running state + pid
      $state = $utils->get_pid_command($device->{id},$self->{device_commands}{$device->{id}}{command},$device->{type}); 
      $logger->debug({filter => \&Data::Dumper::Dumper,
                      value  => $state}) if ($logger->is_debug());
      
      # Increase runcount
      $self->{device_control}{$device->{id}}{runcount}++;
      my $age = $time - $self->{device_control}{$device->{id}}{timestamp};
      if ($age > 1 && ! $state->{running}) {
        # Log!
        $logger->warn("$device->{id} failed to start (count=$self->{device_control}{$device->{id}}{runcount}, died=$age secs ago)");

        # Refresh devices
        $self->{devices} = $devices->all();
        
        # Force command rebuild
        $self->{device_commands}{$device->{id}}{command} = undef;

        # post to the api/controller
        post_config();
      }
    }
    
    # If state has changed set it and post the config
    if (! defined $self->{device_control}{$device->{id}}{running} || 
      ($self->{device_control}{$device->{id}}{running} != $state->{running} ||
      $self->{device_control}{$device->{id}}{pid} != $state->{pid})) {
      # Log
      $logger->debug("$device->{id} has changed state");

      # Set state
      $self->{device_control}{$device->{id}}{pid} = $state->{pid};
      $self->{device_control}{$device->{id}}{running} = $state->{running};
      
      # Status Defaults
      $self->{status}{$device->{id}}{type} = $device->{type};
      $self->{status}{$device->{id}}{timestamp} = $time;

      # Status flag
      if ($state->{running}) {
        $self->{status}{$device->{id}}{running} = 1;
        $self->{status}{$device->{id}}{status} = "started";
        $self->{status}{$device->{id}}{state} = "hard";
        $self->{device_control}{$device->{id}}{timestamp} = $time;
      } else {
        $self->{status}{$device->{id}}{running} = 0;
        $self->{status}{$device->{id}}{status} = "stopped";
        $self->{status}{$device->{id}}{state} = "hard";
      }
      post_config();
    }

  } elsif (defined $self->{device_control}{$device->{id}}{pid}) {
    # Kill The Child
    if ($daemon->Kill_Daemon($self->{device_control}{$device->{id}}{pid})) { 
      # Log
      $logger->info("Stop $device->{id}");
      
      # Set device state
      $self->{device_control}{$device->{id}}{running} = 0;
      $self->{device_control}{$device->{id}}{pid} = undef; 
      
      # Set device status
      $self->{status}{$device->{id}}{running} = 0;
      $self->{status}{$device->{id}}{status} = "stopped";
      $self->{status}{$device->{id}}{state} = "hard";
      post_config();
    }

    # Restart Run count and timestamp
    $self->{device_control}{$device->{id}}{timestamp} = undef;
    $self->{device_control}{$device->{id}}{runcount} = 0;

  }

  # Set device back to running if a restart was triggered
  if ($self->{config}{device_control}{$device->{id}}{run} == 2 && ! $self->{device_control}{$device->{id}}{running}) {
    # Log
    $logger->info("Restarting $device->{id}");
    
    # Set run back to running
    $self->{config}{device_control}{$device->{id}}{run} = 1;

    # Reset Run Count and timestamp
    $self->{device_control}{$device->{id}}{timestamp} = $time;
    $self->{device_control}{$device->{id}}{runcount} = 0;
    
    # Force command rebuild
    $self->{device_commands}{$device->{id}}{command} = undef;
        
    # Refresh devices
    $self->{devices} = $devices->all();
        
    # Set device status
    $self->{status}{$device->{id}}{status} = "restarting";
    $self->{status}{$device->{id}}{state} = "hard";
    write_config();
    post_config();
  }

  return;
}

## Commands
sub ingest_commands {
  my ($id,$type) = @_;
  my $command = $self->{commands}{$type};
  my $did;

  # Some device types require different details
  if ($type eq "file") {
    $did = $id;
  } elsif ($type eq "alsa") {
    $self->{devices} = $devices->all();
    $did = $self->{devices}{$type}{$id}{alsa};
  } else {
    $did = $self->{devices}{$type}{$id}{device};
  }

  my %cmd_vars =  ( 
                    device  => $did,
                    bin     => $Bin,
                    host    => $self->{config}{mixer}{host},
                    port    => $self->{config}{mixer}{port},
                  );

  $command =~ s/\$(\w+)/$cmd_vars{$1}/g;

  return $command;
} 

sub mixer_command {
  my ($id,$type) = @_;
  my $command = $self->{commands}{dvswitch};
  my %cmd_vars =  ( 
                    port    => $self->{config}{mixer}{port},
                  );

  $command =~ s/\$(\w+)/$cmd_vars{$1}/g;

  return $command;
} 

sub record_command {
  my ($id,$type) = @_;
  my $command = $self->{commands}{record};
  my %cmd_vars =  ( 
                    host      => $self->{config}{mixer}{host},
                    port      => $self->{config}{mixer}{port},
                    room      => $self->{config}{room},
                    path      => $self->{device_control}{$id}{recordpath},
                  );

  $command =~ s/\$(\w+)/$cmd_vars{$1}/g;

  return $command;
} 

sub stream_command {
  my ($id,$type) = @_;
  my $command = $self->{commands}{stream};
  my %cmd_vars =  ( 
                    host      => $self->{config}{mixer}{host},
                    port      => $self->{config}{mixer}{port},
                    id        => $id,
                    shost     => $self->{config}{stream}{host},
                    sport     => $self->{config}{stream}{port},
                    spassword => $self->{config}{stream}{password},
                    stream    => $self->{config}{stream}{stream},
                  );

  $command =~ s/\$(\w+)/$cmd_vars{$1}/g;

  return $command;
} 

sub set_path {
  my ($path) = @_;
  my %path_vars =  ( 
                    room    => $self->{config}{room},
                    date    => $self->{date},
                  );

  $path =~ s/\$(\w+)/$path_vars{$1}/g;

  return $path;
} 

# Get Mac Address
sub getmac {
  # This is better, but can break if no eth0. We are only using it as a UID - think of something better.
  my $macaddress = `ifdata -ph eth0`;
  chomp $macaddress;
  return $macaddress;
}

sub blank_station {
  my $mixer_ipaddr = `ifdata -pa eth0`;
  chomp $mixer_ipaddr;
  $mixer_ipaddr =~ s/.$/1/;
  my $hostname = `hostname`;
  chomp $hostname;
  my $room = $hostname;
  $room =~ s/-\d+$//;
  my $json = <<CONFIG;
{
  "roles" :
    [
    ],
  "nickname" : "$hostname",
  "room" : "$room",
  "record_path" : "/localbackup/\$room/\$date",
  "mixer" :
    {
      "port":"1234",
      "host":"$mixer_ipaddr",
      "loop":"/home/av/eventstreamr/baseimage/video/standby.dv"
    },
  "sync" :
    {
      "host":"storage.local",
      "path":"/storage"
    },
  "devices" : "all",
  "device_control" :
    {
    },
  "run" : "0",
  "stream" :
    {
      "host" : "",
      "port" : "",
      "password" : "",
      "stream" : ""
    }
}
CONFIG

  my $config = from_json($json);
  return $config;
}

sub blank_settings {
  my $json = <<CONFIG;
{
     "controller" : "http://10.4.4.10:5001"
}
CONFIG

  my $config = from_json($json);
  return $config;
}

=pod

=encoding UTF-8

=head1 NAME

station-mgr - station-mgr - Core Station Manager script

=head1 VERSION

version 0.5

=head1 SYNOPSIS

Usage:

    station-mgr.pl

=head1 AUTHOR

Leon Wright < techman@cpan.org >

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Leon Wright.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

__END__

(dev) bofh-sider:~/git/eventstreamr/station $ ps waux|grep dv
leon     19898  2.5  0.1 850956 24560 pts/12   Sl+  11:35   1:21 dvswitch -h localhost -p 1234
leon     20723  0.0  0.0   4404   612 ?        S    12:27   0:00 sh -c ffmpeg -f video4linux2 -s vga -r 25 -i /dev/video0 -target pal-dv - | dvsource-file /dev/stdin -h localhost -p 1234
leon     20724  8.0  0.1 130680 24884 ?        S    12:27   0:01 ffmpeg -f video4linux2 -s vga -r 25 -i /dev/video0 -target pal-dv -
leon     20725  0.1  0.0  10796   860 ?        S    12:27   0:00 dvsource-file /dev/stdin -h localhost -p 1234
leon     20735  0.0  0.0   9396   920 pts/16   S+   12:28   0:00 grep --color=auto dv

$VAR1 = {
          'commands' => {
                          'alsa' => 'dvsource-alsa -h $host -p $port hw:$device',
                          'dv' => 'dvsource-firewire -h $host -p $port -c $device',
                          'record' => 'dvsink-files $device',
                          'v4l' => 'ffmpeg -f video4linux2 -s vga -r 25 -i $device -target pal-dv - | dvsource-file /dev/stdin -h $host -p $port',
                          'stream' => 'dvsink-command -- ffmpeg2theora - -f dv -F 25:2 --speedlevel 0 -v 4  --optimize -V 420 --soft-target -a 4 -c 1 -H 44100 -o - | oggfwd $host $port 8000 $password /$stream',
                          'file' => 'dvsource-file -l $device',
                          'dvswitch' => 'dvswitch -h 0.0.0.0 -p $port'
                        },
          'config' => {
                        'roles' => [
                                     {
                                       'role' => 'ingest'
                                     },
                                     {
                                       'role' => 'mixer'
                                     },
                                     {
                                       'role' => 'stream'
                                     }
                                   ],
                        'nickname' => 'test',
                        'room' => 'room1',
                        'devices' => [
                                       {
                                         'name' => 'Chicony Electronics Co.  Ltd. ASUS USB2.0 Webcam',
                                         'id' => 'video0',
                                         'type' => 'v4l',
                                         'device' => '/dev/video0'
                                       },
                                       {
                                         'name' => 'C-Media Electronics, Inc. ',
                                         'usbid' => '0d8c:0008',
                                         'id' => '2',
                                         'type' => 'alsa',
                                         'device' => '2'
                                       }
                                     ],
                        'device_control' => {
                                              'video0' => {
                                                            'run' => '0'
                                                          }
                                            },
                        'run' => '0',
                        'macaddress' => '00:15:58:d8:85:c7',
                        'mixer' => {
                                     'port' => '1234',
                                     'host' => 'localhost'
                                   }
                      },
          'dvswitch' => {
                          'check' => 1
                        },
          'devices' => {
                         'array' => [
                                      {
                                        'name' => 'Chicony Electronics Co.  Ltd. ASUS USB2.0 Webcam',
                                        'id' => 'video0',
                                        'type' => 'v4l',
                                        'device' => '/dev/video0'
                                      },
                                      {
                                        'name' => 'C-Media Electronics, Inc. ',
                                        'usbid' => '0d8c:0008',
                                        'id' => '2',
                                        'type' => 'alsa',
                                        'device' => '2'
                                      }
                                    ],
                         'dv' => {
                                   'all' => []
                                 },
                         'alsa' => {
                                     '2' => {
                                              'name' => 'C-Media Electronics, Inc. ',
                                              'usbid' => '0d8c:0008',
                                              'id' => '2',
                                              'type' => 'alsa',
                                              'device' => '2'
                                            },
                                     'all' => [
                                                {
                                                  'name' => 'C-Media Electronics, Inc. ',
                                                  'usbid' => '0d8c:0008',
                                                  'id' => '2',
                                                  'type' => 'alsa',
                                                  'device' => '2'
                                                }
                                              ]
                                   },
                         'v4l' => {
                                    'video0' => {
                                                  'name' => 'Chicony Electronics Co.  Ltd. ASUS USB2.0 Webcam',
                                                  'id' => 'video0',
                                                  'type' => 'v4l',
                                                  'device' => '/dev/video0'
                                                },
                                    'all' => [
                                               {
                                                 'name' => 'Chicony Electronics Co.  Ltd. ASUS USB2.0 Webcam',
                                                 'id' => 'video0',
                                                 'type' => 'v4l',
                                                 'device' => '/dev/video0'
                                               }
                                             ]
                                  },
                         'all' => {
                                    'video0' => {
                                                  'name' => 'Chicony Electronics Co.  Ltd. ASUS USB2.0 Webcam',
                                                  'id' => 'video0',
                                                  'type' => 'v4l',
                                                  'device' => '/dev/video0'
                                                },
                                    'all' => [
                                               {
                                                 'name' => 'C-Media Electronics, Inc. ',
                                                 'usbid' => '0d8c:0008',
                                                 'id' => '2',
                                                 'type' => 'alsa',
                                                 'device' => '2'
                                               }
                                             ],
                                    '2' => {
                                             'name' => 'C-Media Electronics, Inc. ',
                                             'usbid' => '0d8c:0008',
                                             'id' => '2',
                                             'type' => 'alsa',
                                             'device' => '2'
                                           }
                                  }
                       }
        };
