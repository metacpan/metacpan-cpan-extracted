#!/usr/bin/perl -w

use lib qw(.);
use DTA::CAB;
use DTA::CAB::Server::XmlRpc;
use DTA::CAB::Utils qw(:version);
use Encode qw(encode decode);
use File::Basename qw(basename);
use Getopt::Long qw(:config no_ignore_case);
use Cwd qw(getcwd abs_path);
use Pod::Usage;

##==============================================================================
## DEBUG
##==============================================================================
#do "storable-debug.pl" if (-f "storable-debug.pl");

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
our $serverHost = undef;
our $serverPort = undef;
our $serverEncoding = undef;

##-- Daemon mode options
our $daemonMode = 0;       ##-- do a fork() ?
our $pidFile  = undef;     ##-- save PID to a file?

##==============================================================================
## Command-line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'man|m'     => \$man,
	   'version|V' => \$version,
	   #'verbose|v=s' => \$verbose, ##-- see '-log-level' option

	   ##-- Server configuration
	   'config|c=s' => \$serverConfigFile,
	   'bind|b=s'   => \$serverHost,
	   'port|p=i'   => \$serverPort,
	   'encoding|e=s' => \$serverEncoding,

	   ##-- Daemon mode options
	   'daemon|d!'                 => \$daemonMode,
	   'pid-file|pidfile|pid|P=s'  => \$pidFile,

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

  ##-- remove pidfile if defined
  unlink($pidFile) if (defined($pidFile) && -r $pidFile);

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
our $srv = DTA::CAB::Server::XmlRpc->new(pidfile=>$pidFile);
$srv     = $srv->loadFile($serverConfigFile) if (defined($serverConfigFile));
$srv->{xopt}{host} = $serverHost if (defined($serverHost));
$srv->{xopt}{port} = $serverPort if (defined($serverPort));
$srv->{encoding}   = $serverEncoding if (defined($serverEncoding));


##-- serverMain(): main post-preparation code; run in subprocess if we're in daemon mode
sub serverMain {
  ##-- prepare & run server
  $srv->info("serverMain(): initializing server");
  $srv->info("serverMain(): using DTA::CAB version $DTA::CAB::VERSION");
  $srv->info("serverMain(): CWD ", abs_path(getcwd));
  $srv->prepare()
    or $srv->logdie("prepare() failed!");
  $srv->run();
  $srv->finish();
  $srv->info("exiting");
}

##-- check for daemon mode
if ($daemonMode) {
  $SIG{CHLD} = \&CHLD_REAPER; ##-- set handler

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

dta-cab-xmlrpc-server.perl - XML-RPC server for DTA::CAB queries

=head1 SYNOPSIS

 dta-cab-xmlrpc-server.perl [OPTIONS...]

 General Options:
  -help                           ##-- show short usage summary
  -man                            ##-- show longer help message
  -version                        ##-- show version & exit
  -verbose LEVEL                  ##-- really just an alias for -log-level=LEVEL

 Server Configuration Options:
  -config PLFILE                  ##-- load server config from PLFILE
  -bind   HOST                    ##-- override host to bind (default=all)
  -port   PORT                    ##-- override port to bind (default=8088)
  -encoding ENCODING              ##-- override server encoding (default=UTF-8)

 Daemon Mode Options:
  -daemon , -nodaemon             ##-- do/don't fork() a server subprocess
  -pidfile FILE                   ##-- save server PID to FILE

 Logging Options:                 ##-- see Log::Log4perl(3pm)
  -log-level LEVEL                ##-- set minimum log level (internal config only)
  -log-file LOGFILE               ##-- log to file LOGFILE (default: none)
  -log-stserr , -nolog-stderr     ##-- do/don't log to stderr (default: do)
  -log-rotate , -no-rotate        ##-- do/don't auto-rotate logs (default: if available)
  -log-syslog , -no-syslog        ##-- do/don't log to syslog (default: don't)
  -log-config L4PFILE             ##-- override log4perl config file
  -log-watch SECONDS_OR_SIGNAL    ##-- watch log4perl config file (delay SECONDS or on SIGNAL)
  -nolog-nowatch                  ##-- override: don't watch L4PFILE

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

dta-cab-xmlrpc-server.perl is a command-line utility for starting
an XML-RPC server to perform L<DTA::CAB|DTA::CAB> token-, sentence-, and/or document-analysis
using the L<DTA::CAB::Server::XmlRpc|DTA::CAB::Server::XmlRpc>
module.

See L<dta-cab-xmlrpc-client.perl(1)|dta-cab-xmlrpc-client.perl> for a
command-line client using the L<DTA::CAB::Client::XmlRpc|DTA::CAB::Client::XmlRpc> module.

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
as a L<DTA::CAB::Server::XmlRpc|DTA::CAB::Server::XmlRpc> object.

=item -bind HOST

Override host on which to bind server socket.
Default is to bind on all interfaces of the current host.

=item -port PORT

Override port number to which to bind the server socket.
Default is whatever
L<DTA::CAB::Server::XmlRpc|DTA::CAB::Server::XmlRpc>
defaults to (usually 8088).

=item -encoding ENCODING

Override server encoding.
Default=UTF-8.

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

=item -log-watch SECONDS

=item -log-watch SIGNAL

=item -nolog-watch

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

Copyright (C) 2009-2019 by Bryan Jurish. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<dta-cab-cachegen.perl(1)|dta-cab-cachegen.perl>,
L<dta-cab-xmlrpc-server.perl(1)|dta-cab-xmlrpc-server.perl>,
L<dta-cab-xmlrpc-client.perl(1)|dta-cab-xmlrpc-client.perl>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<RPC::XML(3pm)|RPC::XML>,
L<perl(1)|perl>,
...

=cut
