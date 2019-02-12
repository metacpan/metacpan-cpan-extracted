#!/usr/bin/perl -w

use lib qw(.);
use DTA::CAB;
use DTA::CAB::Server::HTTP;
use DTA::CAB::Server::HTTP::UNIX; ##-- debug
use DTA::CAB::Utils qw(:version);
use IO::Socket::INET;
use Encode qw(encode decode);
use File::Basename qw(basename);
use Getopt::Long qw(:config no_ignore_case);
use Cwd qw(getcwd abs_path);
use Pod::Usage;
use strict;

##==============================================================================
## Constants & Globals
##==============================================================================

##-- program identity
our $prog = basename($0);
our $VERSION = $DTA::CAB::VERSION;

##-- General Options
our ($help,$man,$version);
our $verbose = 'INFO';   ##-- default log level

#BEGIN {
#  binmode($DB::OUT,':utf8') if (defined($DB::OUT));
#  binmode(STDIN, ':utf8');
#  binmode(STDOUT,':utf8');
#  binmode(STDERR,':utf8');
#}
no warnings 'utf8';

##-- Server config
our $serverConfigFile = undef;
our $serverClass = 'DTA::CAB::Server::HTTP';
our $serverHost = undef;
our $serverPort = undef;
our $serverSocketPath = undef;
our $serverSocketUser = undef;
our $serverSocketGroup = undef;
our $serverSocketPerms = '0666';

##-- Daemon mode options
our $daemonMode = 0;       ##-- do a fork() ?
our $pidFile  = undef;     ##-- save PID to a file?
our $forceStart = undef;   ##-- force start (overwrite old PID file?)

##-- default log level
#$DTA::CAB::Logger::defaultLogOpts{level}='INFO';

##==============================================================================
## Command-line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'man|m'     => \$man,
	   'version|V' => \$version,
	   #'verbose|v=s' => \$verbose, ##-- see '-log-level' option

	   ##-- Server configuration
	   'config|c=s' => \$serverConfigFile,
	   'tcp'  => sub { $serverClass='DTA::CAB::Server::HTTP'; },
	   'unix' => sub { $serverClass='DTA::CAB::Server::HTTP::UNIX'; },
	   'tcp-addr|addr|a|bind|b=s' => \$serverHost,
	   'tcp-port|port|p=i'   => \$serverPort,
	   'unix-socket-path|unix-path|usp|us=s' => \$serverSocketPath,
	   'unix-perms|up=s' => \$serverSocketPerms,
	   'unix-user|uu=s' => \$serverSocketUser,
	   'unix-group|ug=s' => \$serverSocketGroup,

	   ##-- Daemon mode options
	   'daemon|d|fork!'            => \$daemonMode,
	   'pid-file|pidfile|pid|P=s'  => \$pidFile,
	   'force!' => \$forceStart,

	   ##-- Log4perl stuff
	   DTA::CAB::Logger->cabLogOptions('verbose'=>1),
	  );

if ($version) {
  print cab_version;
  exit(0);
}

pod2usage({-exitval=>0, -verbose=>1}) if ($man);
pod2usage({-exitval=>0, -verbose=>0}) if ($help);

##==============================================================================
## Subs
##==============================================================================

##--------------------------------------------------------------
## Subs: daemon-mode stuff

## CHLD_REAPER()
##  + lifted from perlipc(1) manpage
sub CHLD_REAPER {
  my $waitedpid = wait();

  ##-- remove pidfile if it contains the reaped process's PID
  if (defined($pidFile) && -r $pidFile) {
    if (open(PIDFILE,"<$pidFile")) {
      my $filepid = <PIDFILE>;
      close PIDFILE;
      chomp($filepid);
      unlink($pidFile) if ($filepid && $filepid == $waitedpid);
    }
  }

  # loathe sysV: it makes us not only reinstate
  # the handler, but place it after the wait
  $SIG{CHLD} = \&CHLD_REAPER;
}

##==============================================================================
## MAIN
##==============================================================================

##-- check for daemon mode

##-- log4perl initialization
DTA::CAB::Logger->logInit();

##-- create / load server object
my $module = $serverClass;
$module =~ s{::}{/}g;
require "$module.pm"
  or DTA::CAB->logdie("failed to load server module $module.pm: $@");

our $srv = $serverClass->new(pidfile=>$pidFile);
$srv     = $srv->loadFile($serverConfigFile) if (defined($serverConfigFile));
$srv->{daemonArgs}{LocalHost} = $serverHost if (defined($serverHost));
$srv->{daemonArgs}{LocalPort} = $serverPort if (defined($serverPort));
$srv->{daemonArgs}{Local}     = $serverSocketPath if (defined($serverSocketPath));
$srv->{socketUser}            = $serverSocketUser if (($serverSocketUser//'') ne '');
$srv->{socketGroup}           = $serverSocketGroup if (($serverSocketGroup//'') ne '');
$srv->{socketPerms}           = $serverSocketPerms if (($serverSocketPerms//'') ne '');

##-- serverMain(): main post-preparation code; run in subprocess if we're in daemon mode
sub serverMain {
  ##-- prepare & run server
  $srv->info("serverMain(): initializing ", ref($srv), " on ", $srv->socketLabel);
  $srv->info("serverMain(): using DTA::CAB version $DTA::CAB::VERSION");
  $srv->info("serverMain(): CWD ", abs_path(getcwd));
  $srv->prepare()
    or $srv->logdie("prepare() failed!");
  $srv->run();
  $srv->finish();
  $srv->info("exiting");
}

##-- check whether we can really bind the socket
DTA::CAB->logdie("cannot bind socket ", $srv->socketLabel, ": $!")
  if (!$srv->canBindSocket);

##-- check for existing PID file (don't overrwrite)
if (defined($pidFile) && -e $pidFile) {
  if ($forceStart) {
    $srv->logwarn("serverMain(): PID-file '$pidFile' exists but -force specified: clobbering as requested");
  } else {
    $srv->logdie("serverMain(): PID-file '$pidFile' exists: NOT starting a new server (use -force to override)");
  }
}

##-- check for daemon mode
if ($daemonMode) {
  $SIG{CHLD} = \&CHLD_REAPER; ##-- set handler

  my ($pid);
  if ( ($pid=fork()) ) {
    ##-- parent
    DTA::CAB->info("spawned daemon subprocess with PID=$pid\n");
  } else {
    ##-- daemon-child
    DTA::CAB->logdie("$prog: fork() failed: $!") if (!defined($pid));
    serverMain();
  }
} else {
  ##-- just run server
  serverMain();
}

__END__
=pod

=head1 NAME

dta-cab-http-server.perl - standalone HTTP server for DTA::CAB queries

=head1 SYNOPSIS

 dta-cab-http-server.perl [OPTIONS...]

 General Options:
  -help                           ##-- show short usage summary
  -man                            ##-- show longer help message
  -version                        ##-- show version & exit
  -verbose LEVEL                  ##-- really just an alias for -log-level=LEVEL

 Server Configuration Options:
  -config PLFILE                  ##-- load server config from PLFILE
  -tcp , -unix                    ##-- set socket type (default=-tcp)
  -bind   HOST                    ##-- override TCP host to bind or relay (default=all)
  -port   PORT                    ##-- override TCP port to bind or relay (default=8088)
  -unix-socket PATH               ##-- override UNIX socket path to bind (default=none)
  -unix-user USER                 ##-- override UNIX socket ownershiip (default=current)
  -unix-group GROUP               ##-- override UNIX socket group (default=current)
  -unix-perms PERMS               ##-- override UNIX socket permissions (default=0666)

 Daemon Mode Options:
  -pidfile PIDFILE                ##-- save server PID to PIDFILE
  -daemon , -nodaemon             ##-- do/don't fork() a server subprocess
  -force  , -noforce              ##-- do/don't overwrite existing PIDFILE (default=don't)

 Logging Options:                 ##-- see Log::Log4perl(3pm)
  -log-level LEVEL                ##-- set minimum log level (internal config only)
  -log-file LOGFILE               ##-- log to file LOGFILE (default: none)
  -log-stderr , -nolog-stderr     ##-- do/don't log to stderr (default: do)
  -log-rotate , -no-rotate        ##-- do/don't auto-rotate logs (default: if available)
  -log-syslog , -no-syslog        ##-- do/don't log to syslog (default: don't)
  -log-config L4PFILE             ##-- override log4perl config file
  -log-watch SECONDS_OR_SIGNAL    ##-- override: watch L4PFILE (delay SECONDS or on SIGNAL)
  -nolog-watch                    ##-- override: don't watch L4PFILE
  -log-option OPT=VALUE           ##-- set any logging option (e.g. -log-option twlevel=trace)

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

dta-cab-http-server.perl is a command-line utility for starting
a standalone HTTP server to perform L<DTA::CAB|DTA::CAB> token-, sentence-, and/or document-analysis
using the L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP>
module.

See L<dta-cab-http-client.perl(1)|dta-cab-http-client.perl> for a
command-line client using the L<DTA::CAB::Client::HTTP|DTA::CAB::Client::HTTP> module.

=cut

##==============================================================================
## Options and Arguments
##==============================================================================
=pod

=head1 OPTIONS AND ARGUMENTS

=cut

##==============================================================================
## Options: General Options
=pod

=head2 General Options

=over 4

=item -help

Display a short help message and exit.

=item -man

Display a longer help message and exit.

=item -version

Display program and module version information and exit.

=item -verbose LEVEL

Alias for L<-log-level LEVEL>.

=back

=cut

##==============================================================================
## Options: Server Configuration Options
=pod

=head2 Server Configuration Options

=over 4

=item -config PLFILE

Load server configuration from PLFILE,
which should be a perl source file parseable
by L<DTA::CAB::Persistent::loadFile()|DTA::CAB::Persistent/item_loadFile>
as a L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP> object.

=item -bind HOST

Override host on which to bind server socket.
Default is to bind on all interfaces of the current host.

=item -port PORT

Override port number to which to bind the server socket.
Default is whatever
L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP>
defaults to (usually 8088).

=back

=cut

##==============================================================================
## Options: Daemon Mode Options
=pod

=head2 Daemon Mode Options

=over 4

=item -daemon , -nodaemon

Do/don't fork() a server subprocess (default: don't).
If running in daemon mode, the program should simply spawn
a single server subprocess and exit, reporting the PID
of the child process.

Useful for starting persistent servers from system-wide
init scripts.  See also L</"-pidfile FILE">.

=item -pidfile FILE

Writes PID of the server process to FILE before running the
server.  Useful for system init scripts.

=back

=cut

##==============================================================================
## Options: Logging Options
=pod

=head2 Logging Options

The L<DTA::CAB|DTA::CAB> family of modules uses
the Log::Log4perl logging mechanism.
See L<Log::Log4perl(3pm)|Log::Log4perl> for details
on the general logging mechanism.

=over 4

=item -log-level LEVEL

Set minimum log level.  Has no effect if you also specify L</-log-config>.
Known levels: (trace|debug|info|warn|error|fatal).

=item -log-config L4PFILE

User log4perl config file L4PFILE.
Default behavior uses the log configuration
string returned by L<DTA::CAB::Logger-E<gt>defaultLogConf()|DTA::CAB::Logger/item_defaultLogConf>.

=item -log-watch , -nowatch

Do/don't watch log4perl config file (default=don't).
Only sensible if you also specify L</-log-config>.

=back

=cut


##======================================================================
## Footer
##======================================================================

=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

RPC::XML by Randy J. Ray.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2019 by Bryan Jurish. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<dta-cab-http-server.perl(1)|dta-cab-http-server.perl>,
L<dta-cab-http-client.perl(1)|dta-cab-http-client.perl>,
L<dta-cab-xmlrpc-server.perl(1)|dta-cab-xmlrpc-server.perl>,
L<dta-cab-xmlrpc-client.perl(1)|dta-cab-xmlrpc-client.perl>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<HTTP::Daemon(3pm)|HTTP::Daemon>,
L<perl(1)|perl>,
...

=cut
