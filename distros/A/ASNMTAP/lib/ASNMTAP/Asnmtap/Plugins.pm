# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Asnmtap::Plugins Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Asnmtap::Plugins;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

no warnings 'deprecated';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(carp);
use Time::HiRes qw(gettimeofday tv_interval);

# include the class files - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(:ASNMTAP :COMMANDS :_HIDDEN :PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Plugins::ISA         = qw(Exporter ASNMTAP::Asnmtap);

  %ASNMTAP::Asnmtap::Plugins::EXPORT_TAGS = (ALL      => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO
                                                              $CAPTUREOUTPUT
                                                              $PREFIXPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                              $ALARM_OFF %ERRORS %STATE %TYPE

                                                              $CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND

                                                              &_checkAccObjRef
                                                              &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                              &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                              &_dumpValue

                                                              $PLUGINPATH) ],

                                             PLUGINS  => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO
                                                              $CAPTUREOUTPUT
                                                              $PREFIXPATH $PLUGINPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                              %ERRORS %STATE %TYPE) ],

                                             COMMANDS => [ qw($CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND) ],

                                            _HIDDEN   => [ qw(&_checkAccObjRef
                                                              &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                              &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                              &_dumpValue) ] );

  @ASNMTAP::Asnmtap::Plugins::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Plugins::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Plugins::VERSION     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

our $ALARM_OFF = 0;

# Constructor & initialisation  - - - - - - - - - - - - - - - - - - - - -

sub _init {
  $_[0]->SUPER::_init($_[1]);
  carp ('ASNMTAP::Asnmtap::Plugins: _init') if ( $_[0]->{_debug} );

  # --httpdump & --dumphttp tijdelijk voor backwards compatibiliteit !!!

  $_[0]->{_programUsageSuffix} = ' [-S|--status N] [-A|asnmtapEnv [F|T]|[F|T]|[F|T]] [-O|onDemand F|T|N|Y] [-L|--logging <LOGGING>] [-D|--debugfile|--httpdump|--dumphttp <DEBUGFILE>] [-d|--debug F|T|L|M|A|S] '. $_[0]->{_programUsageSuffix};

  $_[0]->{_programHelpSuffix}  = "
-S, --status=N
   N(agios)      : Nagios custom plugin output (default)
-A, --asnmtapEnv=[F|T]|[F|T]|[F|T]
   F(alse)       : all screendebugging off (default)
   T(true)       : all screendebugging on
   |
   F(alse)       : all file debugging off (default)
   T(true)       : all file debugging on
   |
   F(alse)       : nok file debugging off (default)
   T(true)       : nok file debugging on
-O, --onDemand=F|T|N|Y
   F(alse)/N(o)  : normal plugin execution (default)
   T(true)/Y(es) : plugin launched on demand
-L, --logging=LOGGING
   write logging to file LOGGING
-D, --debugfile, --httpdump, --dumphttp=DEBUGFILE
   write debug to file DEBUGFILE
-d, --debug=F|T|L|M|A|S
   F(alse)       : screendebugging off (default)
   T(true)       : normal screendebugging on
   L(ong)        : long screendebugging on
   M(oderator)   : long screendebugging on for Moderators
   A(dmin)       : long screendebugging on for Admins
   S(erver Admin): long screendebugging on for Server Admins
" . $_[0]->{_programHelpSuffix};

  push ( @{ $_[0]->{_programGetOptions} }, 'status|S:s', 'asnmtapEnv|A:s', 'onDemand|O:s', 'logging|L:s', 'debugfile|D|dumphttp|httpdump:s', 'debug|d:s' );

  my ($_programUsageSuffix, $_programHelpSuffix);

  foreach ( @{ $_[0]->{_programGetOptions} } ) {
    for ($_) {
      /^trendline\|T([:=])i$/           && do { $_[0]->{_getOptionsType}->{trendline}   = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-T|--trendline <TRENDLINE>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-T, --trendline <TRENDLINE>\n   trendline threshold (seconds) from which a TRENDLINE status will result for the plugin response time\n"; last; };
      /^timeout\|t([:=])i$/             && do { $_[0]->{_getOptionsType}->{timeout}     = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-t|--timeout <TIMEOUT>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-t, --timeout=<TIMEOUT>\n   timeout threshold (seconds) from which a UNKNOWN status will result for the plugin execution time\n"; last; };
      /^environment\|e([:=])s$/         && do { $_[0]->{_getOptionsType}->{environment} = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-e|--environment <ENVIRONMENT>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-e, --environment=<ENVIRONMENT>\n   P(roduction)\n   S(imulation)\n   A(cceptation)\n   T(est)\n   D(evelopment)\n   L(ocal)\n"; last; };
      /^proxy([:=])s$/                  && do { $_[0]->{_getOptionsType}->{proxy}       = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'--proxy <username:password@proxy:port&domain[,domain]>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "--proxy=<username:password\@proxy:port&domain[,domain]>\n"; last; };
      /^host\|H([:=])s$/                && do { $_[0]->{_getOptionsType}->{host}        = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-H|--host <HOST>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-H, --host=<HOST>\n   hostname or ip address\n"; last; };
      /^url\|U([:=])s$/                 && do { $_[0]->{_getOptionsType}->{url}         = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-U|--url <URL>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-U, --url=<URL>\n"; last; };
      /^port\|P([:=])i$/                && do { $_[0]->{_getOptionsType}->{port}        = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-P|--port <PORT>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-P, --port=<PORT>\n"; last; };
      /^community\|C([:=])s$/           && do { $_[0]->{_getOptionsType}->{community}   = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-C|--community <SNMP COMMUNITY>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-C, --community=<SNMP COMMUNITY>\n"; last; };      
      /^username\|u\|loginname([:=])s$/ && do { $_[0]->{_getOptionsType}->{username}    = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-u|--username|--loginname <USERNAME>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-u, --username/--loginname=<USERNAME>\n"; last; };
      /^password\|p\|passwd([:=])s$/    && do { $_[0]->{_getOptionsType}->{password}    = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-p|--password|--passwd <PASSWORD>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-p, --password/--passwd=<PASSWORD>\n"; last; };
      /^filename\|F([:=])s$/            && do { $_[0]->{_getOptionsType}->{filename}    = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-F|--filename <FILENAME>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-F, --filename=<FILENAME>\n   XML filename with the ASNMTAP/Nagios compatible test results\n"; last; };
      /^interval\|i([:=])i$/            && do { $_[0]->{_getOptionsType}->{interval}    = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-i|--interval <SECONDS>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-i, --interval=<SECONDS>\n   interval threshold (seconds) from which a CRITICAL (2x) or WARNING (1x) status will result when XML fingerprint out of time\n"; last; };
      /^loglevel\|l([:=])s$/            && do { $_[0]->{_getOptionsType}->{loglevel}    = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-l|--loglevel <LOGLEVEL>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-l, --loglevel=<LOGLEVEL>\n   loglevel, one of (order of decrescent verbosity): debug, verbose, notice, info, warning, err, crit, alert, emerg\n"; last; };
      /^year\|Y([:=])i$/                && do { $_[0]->{_getOptionsType}->{year}        = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-Y|--year <YEAR>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-Y, --year=<YEAR>\n   year, format: [19|20|21]yy\n"; last; };
      /^quarter\|Q([:=])i$/             && do { $_[0]->{_getOptionsType}->{quarter}     = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-Q|--quarter <QUARTER>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-Q, --quarter=<QUARTER>\n   quarter, where value 0..4\n"; last; };
      /^month\|M([:=])i$/               && do { $_[0]->{_getOptionsType}->{month}       = $1; $_programUsageSuffix .= ($1 eq ':' ? ' [' : ' ') .'-M|--month <MONTH>'. ($1 eq ':' ? ']' : ''); $_programHelpSuffix .= "-M, --month=<MONTH>\n   month, where value 1..12\n"; last; };

      /^warning\|w([:=])s$/             && do { $_[0]->{_getOptionsType}->{warning}     = $1; last; };
      /^critical\|c([:=])s$/            && do { $_[0]->{_getOptionsType}->{critical}    = $1; last; };
    }
  }

  $_[0]->{_programUsageSuffix} = $_programUsageSuffix .' '. $_[0]->{_programUsageSuffix} if (defined $_programUsageSuffix);

  $_[0]->{_programHelpSuffix} = "\n". $_programHelpSuffix . $_[0]->{_programHelpSuffix} if (defined $_programHelpSuffix);

  $_[0]->[ $_[0]->[0]{_exit_} = @{$_[0]} ] = 0;

  $_[0]->[ $_[0]->[0]{_plugins} = @{$_[0]} ] = (defined $_[1]->{_plugins}) ? $_[1]->{_plugins} : 1;

  $_[0]->[ $_[0]->[0]{_timeout} = @{$_[0]} ] = (defined $_[1]->{_timeout}) ? $_[1]->{_timeout} : 10;

  $_[0]->[ $_[0]->[0]{_browseragent} = @{$_[0]} ] = (defined $_[1]->{_browseragent}) ? $_[1]->{_browseragent} : 'Mozilla/5.0 (compatible; ASNMTAP; U; ASNMTAP 3.002.003 postfix; nl-BE; rv:3.002.003) Gecko/yyyymmdd libwww-perl/5.813';

  $_[0]->[ $_[0]->[0]{_SSLversion} = @{$_[0]} ] = (defined $_[1]->{_SSLversion} and $_[1]->{_SSLversion} =~ /^(?:2|3|23)$/) ? $_[1]->{_SSLversion} : 3;

  $_[0]->[ $_[0]->[0]{_clientCertificate} = @{$_[0]} ] = $_[1]->{_clientCertificate} if (defined $_[1]->{_clientCertificate});
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _getOptions {
  $_[0]->SUPER::_getOptions();
  carp ('ASNMTAP::Asnmtap::Plugins: _getOptions') if ( $_[0]->{_debug} );

  # Default _pluginValues - - - - - - - - - - - - - - - - - - - - - - - -

  $_[0]->[ $_[0]->[0]{_pluginValues}   = @{$_[0]} ] = {};

  $_[0]->{_pluginValues}->{stateValue} = $ERRORS{DEPENDENT};
  $_[0]->{_pluginValues}->{stateError} = $STATE{$_[0]->{_pluginValues}->{stateValue}};

  $_[0]->{_pluginValues}->{message}    = $_[0]->{_programDescription};

  $_[0]->{_pluginValues}->{alert}      = undef;
  $_[0]->{_pluginValues}->{error}      = undef;
  $_[0]->{_pluginValues}->{result}     = undef;

  $_[0]->{_pluginValues}->{performanceData} = undef;

  my ($startTimeSeconds, $startTimeMicroseconds) = gettimeofday();
  $_[0]->{_pluginValues}->{startTime}  = $startTimeSeconds .'.'. $startTimeMicroseconds;
  $_[0]->{_pluginValues}->{endTime}    = $_[0]->{_pluginValues}->{startTime};

  # Options that are unknown, ambiguous or supplied with an invalid option value are passed through in @ARGV

  if ( @ARGV ) {
    $_[0]->{_pluginValues}->{error} = "Unknown option(s) @ARGV";
    $_[0]->{_exit_} = 2;
    $_[0]->exit(0);
  }

  # Default command line options  - - - - - - - - - - - - - - - - - - - -

  my $status = (exists $_[0]->{_getOptionsArgv}->{status}) ? $_[0]->{_getOptionsArgv}->{status} : 'N';
  $_[0]->printUsage ('Invalid status option: '. $status) unless ($status =~ /^[N]$/);

  if (exists $_[0]->{_getOptionsArgv}->{asnmtapEnv}) {
    my $asnmtapEnv = $_[0]->{_getOptionsArgv}->{asnmtapEnv};

    my ($boolean_screenDebug, $boolean_debug_all, $boolean_debug_NOK) = split (/\|/, $asnmtapEnv);
    $_[0]->printUsage ('Wrong ASNMTAP environment options: '. $asnmtapEnv) unless (defined $boolean_screenDebug and defined $boolean_debug_all and defined $boolean_debug_NOK);
    $_[0]->printUsage ('Invalid ASNMTAP environment options: '. $asnmtapEnv) unless ($boolean_screenDebug =~ /^[TF]$/ and $boolean_debug_all =~ /^[TF]$/ and $boolean_debug_NOK =~ /^[TF]$/);

    $_[0]->{_getOptionsValues}->{boolean_screenDebug} = ($boolean_screenDebug eq 'T') ? 1 : 0;
    $_[0]->{_getOptionsValues}->{boolean_debug_all}   = ($boolean_debug_all eq 'T')   ? 1 : 0;
    $_[0]->{_getOptionsValues}->{boolean_debug_NOK}   = ($boolean_debug_NOK eq 'T')   ? 1 : 0;
  } else {
    $_[0]->{_getOptionsValues}->{boolean_screenDebug} = 0;
    $_[0]->{_getOptionsValues}->{boolean_debug_all}   = 0;
    $_[0]->{_getOptionsValues}->{boolean_debug_NOK}   = 0;
  }

  my $onDemand = (exists $_[0]->{_getOptionsArgv}->{onDemand}) ? $_[0]->{_getOptionsArgv}->{onDemand} : 'F';
  $_[0]->printUsage ('Invalid on demand option: '. $onDemand) unless ($onDemand =~ /^[FTNY]$/);
  $_[0]->{_getOptionsValues}->{onDemand} = ($onDemand =~ /^[TY]$/) ? 1 : 0;

  # exists $_[0]->{_getOptionsArgv}->{logging}

  if ( defined $_[0]->{_getOptionsArgv}->{debugfile} ) {
    unlink $_[0]->{_getOptionsArgv}->{debugfile} if ( -s $_[0]->{_getOptionsArgv}->{debugfile} );
  }

  my $debug = (exists $_[0]->{_getOptionsArgv}->{debug}) ? $_[0]->{_getOptionsArgv}->{debug} : 'F';
  $_[0]->printUsage ('Invalid debug option: '. $debug) unless ($debug =~ /^[FTLMAS]$/);
  $_[0]->{_getOptionsValues}->{debug} = ($debug eq 'T') ? 1 : (($debug eq 'L') ? 2 : (($debug eq 'M') ? 3 : (($debug eq 'A') ? 4 : ((($debug eq 'S') ? 5 : 0)))));

  # Reserved command line options - - - - - - - - - - - - - - - - - - - -

  if ( exists $_[0]->{_getOptionsArgv}->{timeout} ) {
    my $timeout = $1 if ( $_[0]->{_getOptionsArgv}->{timeout} =~ m/^([1-9]?(?:\d*))$/ );
    $_[0]->printUsage ('Invalid timeout: '. $_[0]->{_getOptionsArgv}->{timeout}) unless (defined $timeout);
  } elsif ( exists $_[0]->{_getOptionsType}->{timeout} and $_[0]->{_getOptionsType}->{timeout} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument timeout');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{trendline} ) {
    my $trendline = $1 if ( $_[0]->{_getOptionsArgv}->{trendline} =~ m/^([1-9]?(?:\d*))$/ );
    $_[0]->printUsage ('Invalid trendline: '. $_[0]->{_getOptionsArgv}->{trendline}) unless (defined $trendline);
  } elsif ( exists $_[0]->{_getOptionsType}->{trendline} and $_[0]->{_getOptionsType}->{trendline} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument trendline');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{environment} ) {
    $_[0]->printUsage ('Invalid environment option: '. $_[0]->{_getOptionsArgv}->{environment}) unless ($_[0]->{_getOptionsArgv}->{environment} =~ /^[PSATDL]$/);

    for ($_[0]->{_getOptionsArgv}->{environment}) {
      /P/ && do { $_[0]->{_getOptionsValues}->{environment} = "Production";  last; };
      /S/ && do { $_[0]->{_getOptionsValues}->{environment} = "Simulation";  last; };
      /A/ && do { $_[0]->{_getOptionsValues}->{environment} = "Acceptation"; last; };
      /T/ && do { $_[0]->{_getOptionsValues}->{environment} = "Test";        last; };
      /D/ && do { $_[0]->{_getOptionsValues}->{environment} = "Development"; last; };
      /L/ && do { $_[0]->{_getOptionsValues}->{environment} = "Local";       last; };
      $_[0]->{_getOptionsValues}->{environment} = undef;
    }
  } elsif ( exists $_[0]->{_getOptionsType}->{environment} and $_[0]->{_getOptionsType}->{environment} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument environment');
  }

  $_[0]->_init_proxy_and_client_certificate ();

  if ( exists $_[0]->{_getOptionsArgv}->{host} ) {
    my $host = $1 if ( $_[0]->{_getOptionsArgv}->{host} =~ m/^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[a-zA-Z][-a-zA-Z0-9]+(\.[a-zA-Z][-a-zA-Z0-9]+)*)$/ );
    $_[0]->printUsage ('Invalid hostname or ip address: '. $_[0]->{_getOptionsArgv}->{host}) unless (defined $host);
  } elsif ( exists $_[0]->{_getOptionsType}->{host} and $_[0]->{_getOptionsType}->{host} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument host');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{url} ) {
    # ... TODO ...
  } elsif ( exists $_[0]->{_getOptionsType}->{url} and $_[0]->{_getOptionsType}->{url} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument url');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{port} ) {
    my $port = $1 if ( $_[0]->{_getOptionsArgv}->{port} =~ m/^([1-9]?(?:\d*))$/ );
    $_[0]->printUsage ('Invalid port: '. $_[0]->{_getOptionsArgv}->{port}) unless (defined $port);
  } elsif ( exists $_[0]->{_getOptionsType}->{port} and $_[0]->{_getOptionsType}->{port} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument port');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{community} ) {
    # ... TODO ...
  } elsif ( exists $_[0]->{_getOptionsType}->{community} and $_[0]->{_getOptionsType}->{community} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument community');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{username} ) {
    # ... TODO ...
  } elsif ( exists $_[0]->{_getOptionsType}->{username} and $_[0]->{_getOptionsType}->{username} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument username');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{password} ) {
    # ... TODO ...
  } elsif ( exists $_[0]->{_getOptionsType}->{password} and $_[0]->{_getOptionsType}->{password} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument password');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{filename} ) {
    # ... TODO ...
  } elsif ( exists $_[0]->{_getOptionsType}->{filename} and $_[0]->{_getOptionsType}->{filename} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument filename');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{interval} ) {
    my $interval = $1 if ( $_[0]->{_getOptionsArgv}->{interval} =~ m/^([1-9]?(?:\d*))$/ );
    $_[0]->printUsage ('Invalid interval: '. $_[0]->{_getOptionsArgv}->{interval}) unless (defined $interval);
  } elsif ( exists $_[0]->{_getOptionsType}->{interval} and $_[0]->{_getOptionsType}->{interval} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument interval');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{loglevel} ) {
    my $loglevel = $1 if ( $_[0]->{_getOptionsArgv}->{loglevel} =~ m/^(debug|verbose|notice|info|warning|err|crit|alert|emerg)$/ );
    $_[0]->printUsage ('Invalid loglevel: '. $_[0]->{_getOptionsArgv}->{loglevel}) unless (defined $loglevel);
  } elsif ( exists $_[0]->{_getOptionsType}->{loglevel} and $_[0]->{_getOptionsType}->{loglevel} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument loglevel');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{year} ) {
    my $year = $1 if ( $_[0]->{_getOptionsArgv}->{year} =~ m/^((?:19|20|21)\d{2,2})$/ );
    $_[0]->printUsage ('Invalid year: '. $_[0]->{_getOptionsArgv}->{year}) unless (defined $year);
  } elsif ( exists $_[0]->{_getOptionsType}->{year} and $_[0]->{_getOptionsType}->{year} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument year');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{quarter} ) {
    my $quarter = $1 if ( $_[0]->{_getOptionsArgv}->{quarter} =~ m/^([1-4])$/ );
    $_[0]->printUsage ('Invalid quarter: '. $_[0]->{_getOptionsArgv}->{quarter}) unless (defined $quarter);
  } elsif ( exists $_[0]->{_getOptionsType}->{quarter} and $_[0]->{_getOptionsType}->{quarter} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument quarter');
  }

  if ( exists $_[0]->{_getOptionsArgv}->{month} ) {
    my $month = $1 if ( $_[0]->{_getOptionsArgv}->{month} =~ m/^([1-9]|1[0-2])$/ );
    $_[0]->printUsage ('Invalid month: '. $_[0]->{_getOptionsArgv}->{month}) unless (defined $month);
  } elsif ( exists $_[0]->{_getOptionsType}->{month} and $_[0]->{_getOptionsType}->{month} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument month');
  }

  # Reserved command line options - - - - - - - - - - - - - - - - - - - -

  if (exists $_[0]->{_getOptionsArgv}->{warning}) {
    my $warning = $1 if ( $_[0]->{_getOptionsArgv}->{warning} =~ /^([1-9]?(?:\d*))$/ );
    $_[0]->printUsage ('Invalid warning threshold ranges '. $_[0]->{_getOptionsArgv}->{warning}) unless (defined $warning);
  } elsif ( exists $_[0]->{_getOptionsType}->{warning} and $_[0]->{_getOptionsType}->{warning} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument warning');
  }

  if (exists $_[0]->{_getOptionsArgv}->{critical}) {
    my $critical = $1 if ($_[0]->{_getOptionsArgv}->{critical} =~ /^([1-9]?(?:\d*))$/ );
    $_[0]->printUsage ('Invalid critical threshold range: '. $_[0]->{_getOptionsArgv}->{critical}) unless (defined $critical);
  } elsif ( exists $_[0]->{_getOptionsType}->{critical} and $_[0]->{_getOptionsType}->{critical} eq '=' ) {
    $_[0]->printUsage ('Missing command line argument critical');
  }

  # Default _pluginValues - - - - - - - - - - - - - - - - - - - - - - - -

  $_[0]->{_pluginValues}->{message}  .= ' ('. $_[0]->{_getOptionsValues}->{environment} .')' if ( defined $_[0]->{_getOptionsValues}->{environment} );

  ($startTimeSeconds, $startTimeMicroseconds) = gettimeofday();
  $_[0]->{_pluginValues}->{startTime} = $startTimeSeconds .'.'. $startTimeMicroseconds;
  $_[0]->{_pluginValues}->{endTime}   = $_[0]->{_pluginValues}->{startTime};

  # Timing Out Slow Plugins - part 1/2 - - - - - - - - - - - - - - - - - -

  if ( exists $_[0]->{_getOptionsArgv}->{timeout} ) {
    $_[0]->{_pluginValues}->{_alarm_} = alarm (0);

    if ( $_[0]->{_pluginValues}->{_alarm_} && $_[0]->{_getOptionsArgv}->{timeout} > $_[0]->{_pluginValues}->{_alarm_} ) {
      $_[0]->{_getOptionsArgv}->{timeout} = $_[0]->{_pluginValues}->{_alarm_};
    }

    $_[0]->{_pluginValues}->{_handler_} = $SIG{ALRM};
    $SIG{ALRM} = sub { $ALARM_OFF = 1; die "ASNMTAP::Asnmtap::Plugins::ALARM_OFF = 1\n" };
    alarm ( $_[0]->{_getOptionsArgv}->{timeout} );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _init_proxy_and_client_certificate {
  my $proxy = ( exists $ENV{ASNMTAP_PROXY} ? $ENV{ASNMTAP_PROXY} : ( exists $_[0]->{_getOptionsArgv}->{proxy} and defined $_[0]->{_getOptionsArgv}->{proxy} ? $_[0]->{_getOptionsArgv}->{proxy} : undef ) );

  if ( defined $proxy and $proxy ne '' ) {
    my ($proxyServer, $proxyNo, $proxyServerNo, $proxyUsername, $proxyPassword, $proxyUsernamePassword);
    ($proxyUsernamePassword, $proxyServerNo) = split(/\@/, $proxy );

    if ( defined $proxyServerNo ) {
      ($proxyUsername, $proxyPassword) = split(/\:/, $proxyUsernamePassword, 2);
      $_[0]->printUsage ('Username and/or Password missing: : '. $proxy) unless (defined $proxyUsername and defined $proxyPassword);
      ($proxyServer, $proxyNo) = split(/\&/, $proxyServerNo );
    } else {
      ($proxyServer, $proxyNo) = split(/\&/, $proxy );
    }

    $_[0]->[ $_[0]->[0]{_proxy} = @{$_[0]} ] = {} unless ( exists $_[0]->{_proxy} );

    $_[0]->{_proxy}->{server}   = "http://" . $proxyServer;
    $_[0]->{_proxy}->{username} = $proxyUsername;
    $_[0]->{_proxy}->{password} = $proxyPassword;

    $_[0]->{_proxy}->{no} = ( defined $proxyNo ? [ split (/,/, $proxyNo) ] : undef );
    $ENV{NO_PROXY} = ( defined $_[0]->{_proxy}->{no} ? join (', ', @{ $_[0]->{_proxy}->{no} }) : '' );
  }

  # HTTPS: DEFAULT SSL VERSION
  $ENV{HTTPS_VERSION} = $_[0]->{_SSLversion};

  # HTTPS: DEBUGGING SWITCH / LOW LEVEL SSL DIAGNOSTICS
  $ENV{HTTPS_DEBUG} = $_[0]->{_getOptionsValues}->{debug};

  if ( defined $proxy and $proxy ne '' ) {
    # HTTPS: PROXY SUPPORT
    $ENV{HTTPS_PROXY} = $_[0]->{_proxy}->{server};

    # HTTPS: PROXY BASIC_AUTH
    $ENV{HTTPS_PROXY_USERNAME} = $_[0]->{_proxy}->{username} if (defined $_[0]->{_proxy}->{username});
    $ENV{HTTPS_PROXY_PASSWORD} = $_[0]->{_proxy}->{password} if (defined $_[0]->{_proxy}->{password});
  }

  if (exists $_[0]->{_clientCertificate}) {
    if (defined $_[0]->{_clientCertificate}->{certFile} and defined $_[0]->{_clientCertificate}->{keyFile}) {
      # CLIENT CERT SUPPORT, PEM encoded certificate and private key files.
      $ENV{HTTPS_CERT_FILE} = $_[0]->{_clientCertificate}->{certFile};
      $ENV{HTTPS_KEY_FILE}  = $_[0]->{_clientCertificate}->{keyFile};

      if (defined $_[0]->{_clientCertificate}->{caFile} and defined $_[0]->{_clientCertificate}->{caDir}) {
        # CA CERT PEER VERIFICATION, Additionally, if you would like to tell the client where the CA file is.
        $ENV{HTTPS_CA_FILE} = $_[0]->{_clientCertificate}->{caFile};
        $ENV{HTTPS_CA_DIR}  = $_[0]->{_clientCertificate}->{caDir};
      }
    }

    if (defined $_[0]->{_clientCertificate}->{pkcs12File} and defined $_[0]->{_clientCertificate}->{pkcs12Password}) {
      # CLIENT PKCS12 CERT SUPPORT, Use of this type of certificate will take precedence over previous certificate settings described.
      $ENV{HTTPS_PKCS12_FILE}     = $_[0]->{_clientCertificate}->{pkcs12File};
      $ENV{HTTPS_PKCS12_PASSWORD} = $_[0]->{_clientCertificate}->{pkcs12Password};
    }
  }
}

# Object accessor methods - - - - - - - - - - - - - - - - - - - - - - - -

sub appendPerformanceData { &_checkAccObjRef ( $_[0] ); &_checkSubArgs1; $_[0]->{_pluginValues}->{performanceData} .= ' '. $_[1] if ( defined $_[1] ); }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub browseragent { &_checkAccObjRef ( $_[0] ); &_checkSubArgs1; $_[0]->{_browseragent} = $_[1] if ( defined $_[1] ); $_[0]->{_browseragent}; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub SSLversion { 
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs1;

  if ( defined $_[1] ) {
    $_[0]->{_SSLversion} = ($_[1] =~ /^(?:2|3|23)$/ ? $_[1] : 3);
  }

  $_[0]->{_SSLversion}; 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub clientCertificate {
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs2;

  if ( defined $_[1] ) {
    if ( defined $_[2] ) {
      $_[0]->{_clientCertificate}->{$_[1]} = $_[2] if ( exists $_[0]->{_clientCertificate}->{$_[1]} );
    }

    ( defined $_[0]->{_clientCertificate}->{$_[1]} ) ? $_[0]->{_clientCertificate}->{$_[1]} : undef;
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub pluginValue {
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs2;

  if ( defined $_[1] and exists $_[0]->{_pluginValues}->{$_[1]}) {
    if ( exists $_[2] ) {
      if ( $_[1] eq 'stateValue' ) {
        &_dumpValue ( $_[2], 'Wrong value!' ) unless ( defined $_[2] && $_[2] =~ /^[0-3]$/ );
        my $stateValue = $_[0]->{_pluginValues}->{stateValue} == $ERRORS{DEPENDENT} ? $_[2] : ( $_[0]->{_pluginValues}->{stateValue} > $_[2] ? $_[0]->{_pluginValues}->{stateValue} : $_[2] );
        $_[0]->{_pluginValues}->{stateValue} = $stateValue;
        $_[0]->{_pluginValues}->{stateError} = $STATE{$stateValue};
      } elsif ( $_[1] eq 'stateError' ) {
        &_dumpValue ( $_[2], 'Wrong value!' ) unless ( defined $_[2] && $_[2] =~ /^(?:OK|WARNING|CRITICAL|UNKNOWN)$/ );
        my $stateValue = $_[0]->{_pluginValues}->{stateValue} == $ERRORS{DEPENDENT} ? $ERRORS{$_[2]} : ( $_[0]->{_pluginValues}->{stateValue} > $ERRORS{$_[2]} ? $_[0]->{_pluginValues}->{stateValue} : $ERRORS{$_[2]} );
        $_[0]->{_pluginValues}->{stateValue} = $stateValue;
        $_[0]->{_pluginValues}->{stateError} = $STATE{$stateValue};
      } else {
        $_[0]->{_pluginValues}->{$_[1]} = $_[2] if ( defined $_[2] );
      }
    }

    ( defined $_[0]->{_pluginValues}->{$_[1]} ) ? $_[0]->{_pluginValues}->{$_[1]} : undef;
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub pluginValues {
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs2;
  &_dumpValue ( $_[1], 'Request parameter is not a hash.' ) if ( ref $_[1] ne 'HASH' );
  &_dumpValue ( $_[1], 'Replace/Append value missing!' ) unless (defined $_[2]);

  if ( exists $_[1]->{stateValue} ) {
    &_dumpValue ( $_[1]->{stateValue}, 'Wrong value!' ) unless ( defined $_[1]->{stateValue} && $_[1]->{stateValue} =~ /^[0-3]$/ );
    my $stateValue = $_[0]->{_pluginValues}->{stateValue} == $ERRORS{DEPENDENT} ? $_[1]->{stateValue} : ( $_[0]->{_pluginValues}->{stateValue} > $_[1]->{stateValue} ? $_[0]->{_pluginValues}->{stateValue} : $_[1]->{stateValue} );
    $_[0]->{_pluginValues}->{stateValue} = $stateValue;
    $_[0]->{_pluginValues}->{stateError} = $STATE{$stateValue};
  } elsif ( exists $_[1]->{stateError} ) {
    &_dumpValue ( $_[1]->{stateError}, 'Wrong value!' ) unless ( defined $_[1]->{stateError} && $_[1]->{stateError} =~ /^(?:OK|WARNING|CRITICAL|UNKNOWN)$/ );
    my $stateValue = $_[0]->{_pluginValues}->{stateValue} == $ERRORS{DEPENDENT} ? $ERRORS{$_[1]->{stateError}} : ( $_[0]->{_pluginValues}->{stateValue} > $ERRORS{$_[1]->{stateError}} ? $_[0]->{_pluginValues}->{stateValue} : $ERRORS{$_[1]->{stateError}} );
    $_[0]->{_pluginValues}->{stateValue} = $stateValue;
    $_[0]->{_pluginValues}->{stateError} = $STATE{$stateValue};
  }

  if ( $_[2] == $TYPE{REPLACE} ) {
    $_[0]->{_pluginValues}->{alert} = $_[1]->{alert} if ( defined $_[1]->{alert} );
    $_[0]->{_pluginValues}->{error} = $_[1]->{error} if ( defined $_[1]->{error} );
  } elsif ( $_[2] == $TYPE{APPEND} ) {
    $_[0]->{_pluginValues}->{alert} .= ( ( defined $_[0]->{_pluginValues}->{alert} ? ' - ' : '' ) .$_[1]->{alert} ) if ( defined $_[1]->{alert} );
    $_[0]->{_pluginValues}->{error} .= ( ( defined $_[0]->{_pluginValues}->{error} ? ' - ' : '' ) .$_[1]->{error} ) if ( defined $_[1]->{error} );
  } elsif ( $_[2] == $TYPE{INSERT} ) {
    $_[0]->{_pluginValues}->{alert} = ( $_[1]->{alert} . ( defined $_[0]->{_pluginValues}->{alert} ? ' - '. $_[0]->{_pluginValues}->{alert} : '' ) ) if ( defined $_[1]->{alert} );
    $_[0]->{_pluginValues}->{error} = ( $_[1]->{error} . ( defined $_[0]->{_pluginValues}->{error} ? ' - '. $_[0]->{_pluginValues}->{error} : '' ) ) if ( defined $_[1]->{error} );
  } elsif ( $_[2] == $TYPE{COMMA_REPLACE} ) {
    # reserved !!!
  } elsif ( $_[2] == $TYPE{COMMA_APPEND} ) {
    $_[0]->{_pluginValues}->{alert} .= ( ( defined $_[0]->{_pluginValues}->{alert} ? ', ' : '' ) .$_[1]->{alert} ) if ( defined $_[1]->{alert} );
    $_[0]->{_pluginValues}->{error} .= ( ( defined $_[0]->{_pluginValues}->{error} ? ', ' : '' ) .$_[1]->{error} ) if ( defined $_[1]->{error} );
  } elsif ( $_[2] == $TYPE{COMMA_INSERT} ) {
    $_[0]->{_pluginValues}->{alert} = ( $_[1]->{alert} . ( defined $_[0]->{_pluginValues}->{alert} ? ', '. $_[0]->{_pluginValues}->{alert} : '' ) ) if ( defined $_[1]->{alert} );
    $_[0]->{_pluginValues}->{error} = ( $_[1]->{error} . ( defined $_[0]->{_pluginValues}->{alert} ? ', '. $_[0]->{_pluginValues}->{error} : '' ) ) if ( defined $_[1]->{error} );
  }

  $_[0]->{_pluginValues}->{result} = $_[1]->{result} if ( defined $_[1]->{result} );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub proxy {
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs2;

  if ( defined $_[1] ) {
    if ( exists $_[0]->{_proxy} ) {
      if ( defined $_[2] ) {
        $_[0]->{_proxy}->{$_[1]} = $_[2] if ( exists $_[0]->{_proxy}->{$_[1]} );
      }

      ( defined $_[0]->{_proxy}->{$_[1]} ) ? $_[0]->{_proxy}->{$_[1]} : undef;
    } else {
      undef;
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub timeout { &_checkAccObjRef ( $_[0] ); &_checkSubArgs1; $_[0]->{_timeout} = $_[1] if ( defined $_[1] ); $_[0]->{_timeout}; }

# Class accessor methods  - - - - - - - - - - - - - - - - - - - - - - - -

sub setEndTime_and_getResponsTime {
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs1;

  my ($endTimeSeconds, $endTimeMicroseconds) = gettimeofday();
  $_[0]->{_pluginValues}->{endTime} = "$endTimeSeconds.$endTimeMicroseconds";

  my ($startTimeSeconds, $startTimeMicroseconds) = split (/\./, $_[1]);
  $startTimeMicroseconds = 0 unless ( defined $startTimeMicroseconds );
  return ( defined $startTimeSeconds ? int ( ( ( $endTimeSeconds >= $startTimeSeconds ) ? tv_interval ( [$startTimeSeconds, $startTimeMicroseconds], [$endTimeSeconds, $endTimeMicroseconds] ) : tv_interval ( [$endTimeSeconds, $endTimeMicroseconds], [$startTimeSeconds, $startTimeMicroseconds] ) ) * 1000 ) : -1 );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub write_debugfile {
  &_checkAccObjRef ( $_[0] ); &_checkReadOnly2;

  my $debugfile = $_[0]->{_getOptionsArgv}->{debugfile};

  if ( defined $debugfile ) {
    my $openAppend = ( defined $_[2] and $_[2] =~ /^1$/ ) ? 1 : 0;
    my $rvOpen = open (DEBUGFILE, ($openAppend ? '>>' : '>') .$debugfile);

    if ($rvOpen) {
      print DEBUGFILE ${$_[1]}, "\n";
      close(DEBUGFILE);
    } else {
      print ref ($_[0]) .": Cannot open $debugfile to print debug information\n";
    }
  }
}

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printUsage {
  $_[0]->_getOptions () if ( exists $_[0]->{_getOptionsArgv}->{usage} );
  $_[0]->SUPER::printUsage ($_[1]);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHelp {
  $_[0]->_getOptions ();
  $_[0]->SUPER::printHelp ();
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub call_system {
  &_checkAccObjRef ( $_[0] ); &_checkReadOnly2;

  return ( $ERRORS{DEPENDENT} ) unless ( defined $_[1] );
  my ($status, $stdout, $stderr) = $_[0]->SUPER::call_system ( $_[1] );

  if ( $status ) {
    if ( $_[0]->{_getOptionsValues}->{debug} ) {
      $_[0]->pluginValues ( { stateValue => $ERRORS{OK}, alert => $_[1] .': OK', result => ( defined $stdout ? $stdout : undef ) }, $TYPE{APPEND} );
    } else {
      $_[0]->pluginValues ( { stateValue => $ERRORS{OK}, result => ( defined $stdout ? $stdout : undef ) }, $TYPE{APPEND} );
    }

    return ( $ERRORS{OK} );
  } else {
    if ( $_[0]->{_getOptionsValues}->{debug} ) {
      $_[0]->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, result => ( defined $stderr ? $stderr : undef ) }, $TYPE{APPEND} );
    } else {
      $_[0]->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $_[1] .': '. $stderr, result => ( defined $stderr ? $stderr : undef ) }, $TYPE{APPEND} );
    }

    return ( $ERRORS{UNKNOWN} );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

sub exit {
  &_checkAccObjRef ( $_[0] ); &_checkSubArgs1;

  exit $ERRORS { $_[0]->{_pluginValues}->{stateError} } if ( exists $_[0]->{_exit_} and $_[0]->{_exit_} == 1 );

  # Timing Out Slow Plugins - part 2/2  - - - - - - - - - - - - - - - - -

  if ( exists $_[0]->{_getOptionsArgv}->{timeout} ) {
    my $remaining = alarm (0);

    if ( $ALARM_OFF or $! =~ /\QASNMTAP::Asnmtap::Plugins::ALARM_OFF = 1\n\E/ or $@ =~ /\QASNMTAP::Asnmtap::Plugins::ALARM_OFF = 1\n\E/ ) {
      $_[0]->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "TIMING OUT SLOW PLUGIN ($remaining)" }, $TYPE{APPEND} );
      $remaining = 0;
    }

    $SIG{ALRM} = $_[0]->{_pluginValues}->{_handler_} ? $_[0]->{_pluginValues}->{_handler_} : 'DEFAULT';

    if ( $_[0]->{_pluginValues}->{_alarm_} ) {   # Previous alarm pending
	  my $alarm = $_[0]->{_pluginValues}->{_alarm_} - $_[0]->{_getOptionsArgv}->{timeout} + $remaining;

      if ( $alarm > 0 ) {          # Reset it, excluding the elapsed time
        alarm ($alarm);
      } else {              # It should have gone off already, set it off
        kill 'ALRM',$$;
      }
    }
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

  $_[0]->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'HELP, THERE IS A PROBLEM WITH THE PLUGIN' }, $TYPE{APPEND} ) if ( $_[0]->{_pluginValues}->{stateValue} == $ERRORS{DEPENDENT} or ( exists $_[0]->{_exit_} and $_[0]->{_exit_} == 2 ) );

  $_[0]->appendPerformanceData('Status='. $_[0]->{_pluginValues}->{stateValue} .';1;2;0;3') if ( defined $_[1] &&  $_[1] =~ /^[1357]$/ );

  my $duration = $_[0]->setEndTime_and_getResponsTime ($_[0]->{_pluginValues}->{startTime});
  $_[0]->appendPerformanceData('Compilation='. ($_[0]->setEndTime_and_getResponsTime ($^T) - $duration) .'ms;;;0;') if ( $_[1] =~ /^[2367]$/ );

  if ( $_[0]->{_getOptionsArgv}->{trendline} ) {
    my $responseTimeSeconds = ( $duration / 1000 );  # convert to seconds

    if ( $_[0]->{_getOptionsValues}->{debug} ) {
      my ($startTimeEpoch, undef) = split (/\./, $_[0]->{_pluginValues}->{startTime});
      my ($endTimeEpoch, undef)   = split (/\./, $_[0]->{_pluginValues}->{endTime});
      print "\nStart time   : ", scalar(localtime($startTimeEpoch)), "\n";
      print "End time     : ", scalar(localtime($endTimeEpoch)), "\n";
      print "Trendline    : ". $_[0]->{_getOptionsArgv}->{trendline} ."\n";
      print "Response time: $responseTimeSeconds\n";
    }

    if ( $_[0]->{_pluginValues}->{stateValue} ) {
      $_[0]->appendPerformanceData('Trendline='. $responseTimeSeconds .'s;;;;');
    } else {
      $_[0]->appendPerformanceData('Trendline='. $responseTimeSeconds .'s;'. $_[0]->{_getOptionsArgv}->{trendline} .';;;');
      $_[0]->{_pluginValues}->{alert} = "Response time $responseTimeSeconds > trendline ". $_[0]->{_getOptionsArgv}->{trendline} if ( $responseTimeSeconds > $_[0]->{_getOptionsArgv}->{trendline} );
    }
  } else {
    $_[0]->appendPerformanceData('Duration='. $duration .'ms;;;0;') if ( $_[1] =~ /^[2367]$/ );
  }

  $_[0]->{_pluginValues}->{alert} =~ s/^\s+//g if ( defined $_[0]->{_pluginValues}->{alert} );

  if ( $_[0]->{_getOptionsValues}->{debug} ) {
    print "\nStatus       : ". $_[0]->{_getOptionsArgv}->{status} ."\n" if ( defined $_[0]->{_getOptionsArgv}->{status} );
    print "Debug        : ". $_[0]->{_getOptionsValues}->{debug} ."\n" if ( defined $_[0]->{_getOptionsValues}->{debug} );
    print "Logging      : ". $_[0]->{_getOptionsArgv}->{logging} ."\n" if ( defined $_[0]->{_getOptionsArgv}->{logging} );
    print "Httpdump     : ". $_[0]->{_getOptionsArgv}->{debugfile} ."\n" if ( defined $_[0]->{_getOptionsArgv}->{debugfile} );
    print "State        : ". $_[0]->{_pluginValues}->{stateError} ."\n" if ( defined $_[0]->{_pluginValues}->{stateError} );
    print "Message      : ". $_[0]->{_pluginValues}->{message} ."\n" if ( defined $_[0]->{_pluginValues}->{message} );
    print "Alert        : ". $_[0]->{_pluginValues}->{alert} ."\n" if ( defined $_[0]->{_pluginValues}->{alert} );
    print "Error        : ". $_[0]->{_pluginValues}->{error} ."\n" if ( defined $_[0]->{_pluginValues}->{error} );
	print "\n";
  }

  my $returnMessage = $_[0]->{_pluginValues}->{stateError} .' - '. $_[0]->{_pluginValues}->{message} .':';
  $returnMessage .= ' '. $_[0]->{_pluginValues}->{alert} if ( $_[0]->{_pluginValues}->{alert} );
  $returnMessage .= ' ERROR: '. $_[0]->{_pluginValues}->{error} if (defined $_[0]->{_pluginValues}->{error});

  $_[0]->appendPerformanceData('Execution='. $_[0]->setEndTime_and_getResponsTime ($^T) .'ms;;;0;') if ( $_[1] =~ /^[2367]$/ );

  if ( defined $_[0]->{_pluginValues}->{performanceData} ) {
    $_[0]->{_pluginValues}->{performanceData} =~ s/^\s+//g;
    $returnMessage .= '|'. $_[0]->{_pluginValues}->{performanceData};
  }

  if ( $_[0]->{_getOptionsArgv}->{logging} ) {
    unless ( $CAPTUREOUTPUT ) {
      my $loggedStatus = ( $_[0]->{_getOptionsArgv}->{debugfile} ) ? $_[0]->{_getOptionsArgv}->{debugfile} : $_[0]->{_getOptionsArgv}->{logging};
      $loggedStatus .= "-status.txt";

      my $rvOpen = open( LOGGING, ">$loggedStatus" );

	  if ($rvOpen) {
        print LOGGING "$returnMessage\n";
        close(LOGGING);
      } else {
        print "Cannot open $loggedStatus to print debug information\n";
      }
    }

    if ( $_[0]->{_getOptionsValues}->{boolean_debug_all} ) {
      my $rvOpen = open ( LOGGING, '>>'. $_[0]->{_getOptionsArgv}->{logging} .'-all.txt' );

	  if ($rvOpen) {
        print LOGGING "--> $returnMessage\n";
        print LOGGING ' -> '. $_[0]->{_pluginValues}->{error} ."\n" if ( $_[0]->{_pluginValues}->{error} ne 'SUCCESS' );
        close(LOGGING);
      } else {
        print 'Cannot open '. $_[0]->{_getOptionsArgv}->{logging} ."-all.txt to print debug information\n";
      }
    }

    if ( $_[0]->{_getOptionsValues}->{boolean_debug_NOK} ) {
      if ( $_[0]->{_pluginValues}->{stateValue} ) {
        my $rvOpen = open ( LOGGING, '>'. $_[0]->{_getOptionsArgv}->{logging} .'-nok.txt' );

        if ( $rvOpen ) {
          print LOGGING "--> $returnMessage\n";
          print LOGGING ' -> '. $_[0]->{_pluginValues}->{error} ."\n";
          print LOGGING '  > '. $_[0]->{_pluginValues}->{result} ."\n";
          close(LOGGING);
        } else {
          print "Cannot open ". $_[0]->{_getOptionsArgv}->{logging} ."-nok.txt to print debug information\n";
        }
      }
    }
  }

  $_[0]->dumpData (1) if ( $_[0]->getOptionsArgv ('dumpData') );

  print "$returnMessage\n" if ( $_[0]->{_plugins} );
  $_[0]->{_exit_} = 1;
  exit $ERRORS { $_[0]->{_pluginValues}->{stateError} };
}

# Destructor  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub DESTROY { 
  print (ref ($_[0]), "::DESTROY: ()\n") if ( $_[0]->{_debug} ); 

  if ( exists $_[0]->{_pluginValues} ) {
    unless ( exists $_[0]->{_exit_} and $_[0]->{_exit_} == 1 ) {
      $_[0]->{_exit_} = 2;
      $_[0]->exit(0);
    }
  }

  $_[0]->{_exit_} = 1;
  $_[0]->exit(0);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins provides a nice object oriented interface for building ASNMTAP (http://asnmtap.citap.be) compatible plugins.

=head1 Description

ASNMTAP::Asnmtap::Plugins Subclass of ASNMTAP::Asnmtap

=head1 SEE ALSO

ASNMTAP::Asnmtap, ASNMTAP::Asnmtap::Plugins::Nagios

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