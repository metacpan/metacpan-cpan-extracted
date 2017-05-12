# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Asnmtap Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Asnmtap;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(carp cluck);
use Getopt::Long;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

no warnings 'deprecated';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::ISA         = qw(Exporter);

  %ASNMTAP::Asnmtap::EXPORT_TAGS = (ALL          => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO $TYPEMONITORING $RUNCMDONDEMAND
                                                         $CAPTUREOUTPUT
                                                         $PREFIXPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                         %ERRORS %STATE %TYPE

                                                         $CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND

                                                         &_checkAccObjRef
                                                         &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                         &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                         &_dumpValue
													 
                                                         $APPLICATIONPATH

                                                         $PLUGINPATH) ],

                                    ASNMTAP      => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO $TYPEMONITORING $RUNCMDONDEMAND
                                                         $CAPTUREOUTPUT
                                                         $PREFIXPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                         %ERRORS %STATE %TYPE) ],

                                    COMMANDS     => [ qw($CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND) ],

                                   _HIDDEN       => [ qw(&_checkAccObjRef
                                                         &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                         &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                         &_dumpValue) ],

                                    APPLICATIONS => [ qw($APPLICATIONPATH) ],

                                    PLUGINS      => [ qw($PLUGINPATH) ] );

  @ASNMTAP::Asnmtap::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::VERSION     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

# read config file  - - - - - - - - - - - - - - - - - - - - - - - - - -

my %_config;

our $PREFIXPATH = '/opt/asnmtap';
my $_configfile = "$PREFIXPATH/Asnmtap.cnf";

if ( -e $_configfile or ( exists $ENV{ASNMTAP_PATH} ) ) {
  if ( exists $ENV{ASNMTAP_PATH} ) {
    $PREFIXPATH  = $ENV{ASNMTAP_PATH};
    $_configfile = "$PREFIXPATH/Asnmtap.cnf";
  }

  die "ASNMTAP::Asnmtap: Config '$_configfile' doesn't exist." unless (-e $_configfile);

  use Config::General qw(ParseConfig);
  %_config = ParseConfig ( -ConfigFile => $_configfile, -InterPolateVars => 0 ) ;
  die "ASNMTAP::Asnmtap: Config '$_configfile' can't be loaded." unless (%_config);
  undef $_configfile;
}

# SET ENVIRONMENT VARIABLES = = = = = = = = = = = = = = = = = = = = = =

$ENV{PATH}           = ( exists $_config{ENV}{PATH} )     ? $_config{ENV}{PATH}     : '/opt/csw/bin:/usr/local/bin:/usr/bin:/bin:/opt/csw/sbin:/usr/local/sbin:/usr/sbin:/sbin';
$ENV{BASH_ENV}       = ( exists $_config{ENV}{BASH_ENV} ) ? $_config{ENV}{BASH_ENV} : '';
$ENV{ENV}            = ( exists $_config{ENV}{ENV} )      ? $_config{ENV}{ENV}      : '';

# SET ASNMTAP::Asnmtap VARIABLES  - - - - - - - - - - - - - - - - - - -

our $PERL5LIB        = $_config{SET}{PERL5LIB}        if ( exists $_config{SET}{PERL5LIB} );
our $MANPATH         = $_config{SET}{MANPATH}         if ( exists $_config{SET}{MANPATH} );
our $LD_LIBRARY_PATH = $_config{SET}{LD_LIBRARY_PATH} if ( exists $_config{SET}{LD_LIBRARY_PATH} );

our $APPLICATIONPATH = $PREFIXPATH .'/applications';
our $PLUGINPATH      = $PREFIXPATH .'/plugins';
our $LOGPATH         = $PREFIXPATH .'/log';
our $PIDPATH         = $PREFIXPATH .'/pid';

if ( exists $_config{SUBDIR} ) {
  $APPLICATIONPATH   = $PREFIXPATH .'/'. $_config{SUBDIR}{APPLICATIONS} if ( exists $_config{SUBDIR}{APPLICATIONS} );
  $PLUGINPATH        = $PREFIXPATH .'/'. $_config{SUBDIR}{PLUGINS}      if ( exists $_config{SUBDIR}{PLUGINS} );
  $LOGPATH           = $PREFIXPATH .'/'. $_config{SUBDIR}{LOG}          if ( exists $_config{SUBDIR}{LOG} );
  $PIDPATH           = $PREFIXPATH .'/'. $_config{SUBDIR}{PID}          if ( exists $_config{SUBDIR}{PID} );
}

our $APPLICATION     = ( exists $_config{COMMON}{APPLICATION} )    ? $_config{COMMON}{APPLICATION}    : 'Application Monitoring';
our $BUSINESS        = ( exists $_config{COMMON}{BUSINESS} )       ? $_config{COMMON}{BUSINESS}       : 'CITAP';
our $DEPARTMENT      = ( exists $_config{COMMON}{DEPARTMENT} )     ? $_config{COMMON}{DEPARTMENT}     : 'Development';
our $COPYRIGHT       = ( exists $_config{COMMON}{COPYRIGHT} )      ? $_config{COMMON}{COPYRIGHT}      : '2000-2011';
our $SENDEMAILTO     = ( exists $_config{COMMON}{SENDEMAILTO} )    ? $_config{COMMON}{SENDEMAILTO}    : 'alex.peeters@citap.be';
our $TYPEMONITORING  = ( exists $_config{COMMON}{TYPEMONITORING} ) ? $_config{COMMON}{TYPEMONITORING} : 'central';
our $RUNCMDONDEMAND  = ( exists $_config{COMMON}{RUNCMDONDEMAND} ) ? $_config{COMMON}{RUNCMDONDEMAND} : 'localhost';

our $CAPTUREOUTPUT   = ( exists $_config{IO}{CAPTUREOUTPUT} )   ? $_config{IO}{CAPTUREOUTPUT}   : 1;

our $CHATCOMMAND     = '/usr/sbin/chat';
our $DIFFCOMMAND     = '/usr/bin/diff';
our $KILLALLCOMMAND  = '/usr/bin/killall';
our $PERLCOMMAND     = '/usr/bin/perl';
our $PPPDCOMMAND     = '/usr/sbin/pppd';
our $ROUTECOMMAND    = '/sbin/route';
our $RSYNCCOMMAND    = '/usr/bin/rsync';
our $SCPCOMMAND      = '/usr/bin/scp';
our $SSHCOMMAND      = '/usr/bin/ssh';

if ( exists $_config{COMMAND} ) {
  $CHATCOMMAND       = $_config{COMMAND}{CHAT}    if ( exists $_config{COMMAND}{CHAT} );
  $DIFFCOMMAND       = $_config{COMMAND}{DIFF}    if ( exists $_config{COMMAND}{DIFF} );
  $KILLALLCOMMAND    = $_config{COMMAND}{KILLALL} if ( exists $_config{COMMAND}{KILLALL} );
  $PERLCOMMAND       = $_config{COMMAND}{PERL}    if ( exists $_config{COMMAND}{PERL} );
  $PPPDCOMMAND       = $_config{COMMAND}{PPPD}    if ( exists $_config{COMMAND}{PPPD} );
  $ROUTECOMMAND      = $_config{COMMAND}{ROUTE}   if ( exists $_config{COMMAND}{ROUTE} );
  $RSYNCCOMMAND      = $_config{COMMAND}{RSYNC}   if ( exists $_config{COMMAND}{RSYNC} );
  $SCPCOMMAND        = $_config{COMMAND}{SCP}     if ( exists $_config{COMMAND}{SCP} );
  $SSHCOMMAND        = $_config{COMMAND}{SSH}     if ( exists $_config{COMMAND}{SSH} );
}

undef %_config;

# Plugin variables  - - - - - - - - - - - - - - - - - - - - - - - - - - -

our %ERRORS          = ('OK'=>'0','WARNING'=>'1','CRITICAL'=>'2','UNKNOWN'=>'3','DEPENDENT'=>'4','OFFLINE'=>'5','NO TEST'=>'6','NO DATA'=>'7','IN PROGRESS'=>'8','TRENDLINE'=>'9');
our %STATE           = ('0'=>'OK','1'=>'WARNING','2'=>'CRITICAL','3'=>'UNKNOWN','4'=>'DEPENDENT','5'=>'OFFLINE','6'=>'NO TEST','7'=>'NO DATA','8'=>'IN PROGRESS','9'=>'TRENDLINE');
our %TYPE            = ('REPLACE'=>'0','APPEND'=>'1','INSERT'=>'2','COMMA_REPLACE'=>'3','COMMA_APPEND'=>'4','COMMA_INSERT'=>'5');

# Constructor & initialisation  - - - - - - - - - - - - - - - - - - - - -

sub new (@) {
  my $classname = shift;

  unless ( defined $classname ) { my @c = caller; die "Syntax error: Class name expected after new at $c[1] line $c[2]\n" }
  if ( ref $classname) { my @c = caller; die "Syntax error: Can't construct new ".ref($classname)." from another object at $c[1] line $c[2]\n" }

  my $self = {};

  my @parameters = (_programName        => 'NOT DEFINED', 
                    _programDescription => 'NOT DEFINED', 
                    _programVersion     => '0.000.000', 
                    _programUsagePrefix => undef, 
                    _programUsageSuffix => undef, 
                    _programHelpPrefix  => undef, 
                    _programHelpSuffix  => undef, 
                    _programGetOptions  => undef, 
                    _debug              => 0);

  if ( $] < 5.010000 ) {
    eval "use fields";
    $self = fields::phash (@parameters);
  } else {
    use ASNMTAP::PseudoHash;

    $self = do {
      my @array = undef;

      while (my ($k, $v) = splice(@parameters, 0, 2)) {
        $array[$array[0]{$k} = @array] = $v;
      }

      bless(\@array, $classname);
    };
  }

  my %args = @_;
 
  $self->{_programName}        = $args{_programName}        if ( exists $args{_programName} );
  $self->{_programDescription} = $args{_programDescription} if ( exists $args{_programDescription} );
  $self->{_programVersion}     = $args{_programVersion}     if ( exists $args{_programVersion} );
  $self->{_programUsagePrefix} = $args{_programUsagePrefix} if ( exists $args{_programUsagePrefix} );
  $self->{_programHelpPrefix}  = $args{_programHelpPrefix}  if ( exists $args{_programHelpPrefix} );
  $self->{_programUsageSuffix} = $args{_programUsageSuffix} if ( exists $args{_programUsageSuffix} );
  $self->{_programHelpSuffix}  = $args{_programHelpSuffix}  if ( exists $args{_programHelpSuffix} );
  $self->{_programGetOptions}  = $args{_programGetOptions}  if ( exists $args{_programGetOptions} );
  $self->{_debug}              = $args{_debug}              if ( exists $args{_debug} );

  if ( defined $self->{_programVersion} ) {
    $self->{_programVersion} =~ s/^\$Revision: //;
    $self->{_programVersion} =~ s/ \$\s*$//;
  }

  bless ($self, $classname);
  $self->_init(\%args);
  $self->_getOptions();
  return ($self);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _init {
  carp ('ASNMTAP::Asnmtap: _init') if ( $_[0]->{_debug} );

  $_[0]->{_programUsageSuffix} = ' [-v|--verbose <LEVEL>] [-V|--version] [-h|--help] [--usage] [--dumpData]';

  $_[0]->{_programHelpSuffix} = "
-v, --verbose=<LEVEL>
   0: single line, minimal output
   1: single line, additional information
   2: multi line, configuration debug output
   3: lots of detail for problem diagnosis
-V, --version
   Report version
-h, --help
   Display the help message
--usage
   Display the short usage statement
--dumpData
   Display the stringified data structures from the current object
";

  push (@{ $_[0]->{_programGetOptions} }, 'verbose|v:i', 'version|V', 'help|h', 'usage', 'dumpData');

  $_[0]->[ $_[0]->[0]{_getOptionsType} = @{$_[0]} ] = {};
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _getOptions {
  carp ('ASNMTAP::Asnmtap: _getOptions') if ( $_[0]->{_debug} );

  Getopt::Long::Configure ('bundling', 'pass_through');

  my %getOptionsArgv;
  my $programGetOptions = $_[0]->{_programGetOptions};
  my $resultGetOptions = GetOptions ( \%getOptionsArgv, @$programGetOptions );
  carp ('ASNMTAP::Asnmtap: _getOptions '. "Unknown option(s): @ARGV") if ( ref $_[0] !~ /ASNMTAP::Asnmtap::Plugins/ );
  $_[0]->[ $_[0]->[0]{_getOptionsArgv} = @{$_[0]} ] = {%getOptionsArgv};
  $_[0]->printRevision () if ( exists $_[0]->{_getOptionsArgv}->{version} );
  $_[0]->printHelp () if ( exists $_[0]->{_getOptionsArgv}->{help} );
  $_[0]->printUsage ('.') if ( exists $_[0]->{_getOptionsArgv}->{usage} );

  my $verbose = (exists $_[0]->{_getOptionsArgv}->{verbose}) ? $_[0]->{_getOptionsArgv}->{verbose} : 0;
  $_[0]->printUsage ('Invalid verbose option: '. $verbose) unless ($verbose =~ /^[0123]$/);

  $_[0]->[ $_[0]->[0]{_getOptionsValues} = @{$_[0]} ] = {};
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub _checkAccObjRef    { unless ( ref $_[0] ) { cluck 'Syntax error: Access object reference expected'; exit $ERRORS{UNKNOWN} } }

sub _checkSubArgs0     { if ( @_ > 1 ) { cluck "Syntax error: To many arguments ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }
sub _checkSubArgs1     { if ( @_ > 2 ) { cluck "Syntax error: To many arguments ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }
sub _checkSubArgs2     { if ( @_ > 3 ) { cluck "Syntax error: To many arguments ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }

sub _checkReadOnly0    { if ( @_ > 1 ) { cluck "Syntax error: Can't change value of read-only attribute ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }
sub _checkReadOnly1    { if ( @_ > 2 ) { cluck "Syntax error: Can't change value of read-only attribute ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }
sub _checkReadOnly2    { if ( @_ > 3 ) { cluck "Syntax error: Can't change value of read-only attribute ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _dumpValue {
  require Dumpvalue;
  my $dumper = Dumpvalue->new ();
  print "\n->ASNMTAP::Asnmtap: Dump debug data\n\n";
  $dumper->dumpValue ( $_[0] );
  print "\n\n";
  cluck $_[1];
  exit $ERRORS{UNKNOWN};
}

# Object accessor methods - - - - - - - - - - - - - - - - - - - - - - - -

sub programName        { &_checkAccObjRef ( $_[0] ); &_checkSubArgs1;  $_[0]->{_programName} = $_[1] if ( defined $_[1] ); $_[0]->{_programName}; }

sub programDescription { &_checkAccObjRef ( $_[0] ); &_checkSubArgs1;  $_[0]->{_programDescription} = $_[1] if ( defined $_[1] ); $_[0]->{_programDescription}; }

sub programVersion     { &_checkAccObjRef ( $_[0] ); &_checkSubArgs1;  $_[0]->{_programVersion} = $_[1] if ( defined $_[1] ); $_[0]->{_programVersion}; }

sub getOptionsArgv     { &_checkAccObjRef ( $_[0] ); &_checkReadOnly1; ( defined $_[1] and defined $_[0]->{_getOptionsArgv}->{$_[1]} ) ? $_[0]->{_getOptionsArgv}->{$_[1]} : undef; }

sub getOptionsValue    { &_checkAccObjRef ( $_[0] ); &_checkReadOnly1; ( defined $_[1] and defined $_[0]->{_getOptionsValues}->{$_[1]} ) ? $_[0]->{_getOptionsValues}->{$_[1]} : undef; }

sub getOptionsType     { &_checkAccObjRef ( $_[0] ); &_checkReadOnly1; ( defined $_[1] and defined $_[0]->{_getOptionsType}->{$_[1]} ) ? $_[0]->{_getOptionsType}->{$_[1]} : undef; }

sub debug              { &_checkAccObjRef ( $_[0] ); &_checkSubArgs1;  $_[0]->{_debug} = $_[1] if ( defined $_[1] and $_[1] =~ /^[01]$/ ); $_[0]->{_debug}; }

# Class accessor methods  - - - - - - - - - - - - - - - - - - - - - - - -

sub dumpData {
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs1;

  if ( defined $_[1] or $_[0]->{_debug} ) {
    use Data::Dumper;
    print "\n". ref ($_[0]) .": Now we'll dump data\n\n", Dumper ( $_[0] ), "\n\n";
  }
}

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printRevision {
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs1;

  print "\nThis is program: ", $_[0]->{_programName}, " (", $_[0]->{_programDescription}, ") v", $_[0]->{_programVersion}, "

Copyright (c) $COPYRIGHT ASNMTAP, Author: Alex Peeters [alex.peeters\@citap.be]

";

  exit ( (ref $_[0]) =~ /^ASNMTAP::Asnmtap::Plugins/ ? $ERRORS{UNKNOWN} : 0 ) unless ( defined $_[1] );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printUsage {
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs1;

  print 'Usage: ', $_[0]->{_programName};
  print (' ', $_[0]->{_programUsagePrefix}) if ( defined $_[0]->{_programUsagePrefix} );
  print (' ', $_[0]->{_programUsageSuffix}) if ( defined $_[0]->{_programUsageSuffix} );
  print "\n\n";

  if ( defined $_[1] ) {
    print ($_[1], "\n") unless ($_[1] eq '.');
    exit ( (ref $_[0]) =~ /^ASNMTAP::Asnmtap::Plugins/ ? $ERRORS{UNKNOWN} : 0 );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHelp {
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs0;

  $_[0]->printRevision(1);

  $_[0]->printUsage();

  print $_[0]->{_programHelpPrefix}, "\n" if ( defined $_[0]->{_programHelpPrefix} );
  print $_[0]->{_programHelpSuffix}, "\n" if ( defined $_[0]->{_programHelpSuffix} );

  print "Send email to $SENDEMAILTO if you have questions regarding\nuse of this software. To submit patches or suggest improvements, send\nemail to $SENDEMAILTO\n\n";

  exit ( (ref $_[0]) =~ /^ASNMTAP::Asnmtap::Plugins/ ? $ERRORS{UNKNOWN} : 0 );
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub call_system {
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs1;

  my ($stdout, $stderr);

  if ( $CAPTUREOUTPUT ) {
    use IO::CaptureOutput qw(capture_exec);
    ($stdout, $stderr) = capture_exec ( $_[1] );
    chomp($stdout); chomp($stderr);
  } else {
    $stdout = $stderr = ''; system ( $_[1] );
  }

  my $exit_value  = $? >> 8;
  my $signal_num  = $? & 127;
  my $dumped_core = $? & 128;
  my $status = ( $exit_value == 0 && $signal_num == 0 && $dumped_core == 0 && $stderr eq '' ) ? 1 : 0;

  if ( $_[0]->{_debug} ) {
    print ref $_[0], ": command      : $_[1]\n",
          ref $_[0], ": exit value   : $exit_value\n",
          ref $_[0], ": signal number: $signal_num\n",
          ref $_[0], ": dumped core  : $dumped_core\n",
          ref $_[0], ": status       : $status\n",
          ref $_[0], ": stdout       : '$stdout'\n",
          ref $_[0], ": stderr       : '$stderr'\n";
  }

  return ( $status, $stdout, $stderr );
}

# Destructor  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub DESTROY { print (ref ($_[0]), "::DESTROY: ()\n") if ( $_[0]->{_debug} ); }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap is an object-oriented Base Class to build modules that provides a nice object oriented interface for ASNMTAP.

=head1 SEE ALSO

ASNMTAP::Asnmtap::Applications, ASNMTAP::Asnmtap::Applications::CGI, ASNMTAP::Asnmtap::Applications::Collector, ASNMTAP::Asnmtap::Applications::Display

ASNMTAP::Asnmtap::Plugins, ASNMTAP::Asnmtap::Plugins::Nagios

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

ASNMTAP is based on 'Process System daemons v1.60.17-01', Alex Peeters [alex.peeters@citap.be]

 Purpose: CronTab (CT, sysdCT),
          Disk Filesystem monitoring (DF, sysdDF),
          Intrusion Detection for FW-1 (ID, sysdID)
          Process System daemons (PS, sysdPS),
          Reachability of Remote Hosts on a network (RH, sysdRH),
          Rotate Logfiles (system activity files) (RL),
          Remote Socket monitoring (RS, sysdRS),
          System Activity monitoring (SA, sysdSA).

'Process System daemons' is based on 'sysdaemon 1.60' written by Trans-Euro I.T Ltd

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut