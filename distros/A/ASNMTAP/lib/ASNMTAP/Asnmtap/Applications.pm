# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Asnmtap::Applications
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Asnmtap::Applications;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);
use Date::Calc qw(Today);
use Time::Local;

# include the class files - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time qw(&get_csvfiledate &get_datetimeSignal);

use ASNMTAP::Asnmtap qw(:ASNMTAP :COMMANDS :_HIDDEN :APPLICATIONS :PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Applications::ISA         = qw(Exporter ASNMTAP::Asnmtap);

  %ASNMTAP::Asnmtap::Applications::EXPORT_TAGS = (ALL          => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO $TYPEMONITORING $RUNCMDONDEMAND
                                                                       $CAPTUREOUTPUT
                                                                       $PREFIXPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                                       %ERRORS %STATE %TYPE @EVENTS %EVENTS

                                                                       $CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND

                                                                       &_checkAccObjRef
                                                                       &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                                       &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                                       &_dumpValue

                                                                       $APPLICATIONPATH $PLUGINPATH
 							   
                                                                       $ASNMTAPMANUAL
                                                                       $DATABASE $CATALOGID
                                                                       $AWSTATSENABLED
                                                                       $CONFIGDIR $CGISESSDIR $DEBUGDIR $REPORTDIR $RESULTSDIR
                                                                       $CGISESSPATH $HTTPSPATH $IMAGESPATH $PDPHELPPATH $RESULTSPATH $SSHKEYPATH $WWWKEYPATH
                                                                       $HTTPSSERVER $REMOTE_HOST $REMOTE_ADDR $HTTPSURL $IMAGESURL $PDPHELPURL $RESULTSURL
                                                                       $SMTPUNIXSYSTEM $SERVERLISTSMTP $SERVERSMTP $SENDMAILFROM
                                                                       $SSHLOGONNAME $RSYNCIDENTITY $SSHIDENTITY $WWWIDENTITY
                                                                       $RMVERSION $RMDEFAULTUSER
                                                                       $CHARTDIRECTORLIB
                                                                       $HTMLTOPDFPRG $HTMLTOPDFHOW $HTMLTOPDFOPTNS
                                                                       $PERFPARSEBIN $PERFPARSEETC $PERFPARSELIB $PERFPARSESHARE $PERFPARSECGI $PERFPARSEENABLED
                                                                       $PERFPARSEVERSION $PERFPARSECONFIG $PERFPARSEDATABASE $PERFPARSEHOST $PERFPARSEPORT $PERFPARSEUSERNAME $PERFPARSEPASSWORD
                                                                       $RECORDSONPAGE $NUMBEROFFTESTS $VERIFYNUMBEROK $VERIFYMINUTEOK $FIRSTSTARTDATE $STRICTDATE $STATUSHEADER01
                                                 				          	   %COLORS %COLORSPIE %COLORSRRD %COLORSTABLE %ICONS %ICONSACK %ICONSUNSTABLE %ICONSRECORD %ICONSSYSTEM %ENVIRONMENT %SOUND %QUARTERS
                                                                       $SERVERMYSQLVERSION $SERVERMYSQLMERGE
                                                                       $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                                                       $SERVERNAMEREADONLY $SERVERPORTREADONLY $SERVERUSERREADONLY $SERVERPASSREADONLY
                                                                       $SERVERTABLCATALOG $SERVERTABLCLLCTRDMNS $SERVERTABLCOMMENTS $SERVERTABLCOUNTRIES $SERVERTABLCRONTABS $SERVERTABLDISPLAYDMNS $SERVERTABLDISPLAYGRPS $SERVERTABLENVIRONMENT $SERVERTABLEVENTS $SERVERTABLEVENTSCHNGSLGDT $SERVERTABLEVENTSDISPLAYDT $SERVERTABLHOLIDYS $SERVERTABLHOLIDYSBNDL $SERVERTABLLANGUAGE $SERVERTABLPAGEDIRS $SERVERTABLPLUGINS $SERVERTABLREPORTS $SERVERTABLREPORTSPRFDT $SERVERTABLRESULTSDIR $SERVERTABLSERVERS $SERVERTABLTIMEPERIODS $SERVERTABLUSERS $SERVERTABLVIEWS
                                                                       &read_table &get_session_param &get_trendline_from_test
                                                                       &set_doIt_and_doOffline
                                                                       &create_header &create_footer &encode_html_entities &decode_html_entities &print_header &print_legend
                                                                       &init_email_report &send_email_report &sending_mail

                                                                       &CSV_prepare_table &CSV_insert_into_table &CSV_import_from_table &CSV_cleanup_table
                                                                       &DBI_connect &DBI_do &DBI_execute &DBI_error_trap
                                                                       &LOG_init_log4perl
                                                                       &print_revision &usage &call_system) ],

                                                  APPLICATIONS => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO $TYPEMONITORING $RUNCMDONDEMAND
                                                                       $CAPTUREOUTPUT
                                                                       $PREFIXPATH $PLUGINPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                                       %ERRORS %STATE %TYPE

                                                                       &sending_mail

                                                                       &print_revision &usage &call_system) ],

                                                  COMMANDS     => [ qw($CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND) ],

                                                 _HIDDEN       => [ qw(&_checkAccObjRef
                                                                       &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                                       &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                                       &_dumpValue) ],

                                                  ARCHIVE      => [ qw($DATABASE $CATALOGID
                                                                       $DEBUGDIR $REPORTDIR
                                                                       $CGISESSPATH $RESULTSPATH
                                                                       $SMTPUNIXSYSTEM $SERVERLISTSMTP $SERVERSMTP $SENDMAILFROM
                                                                       @EVENTS %EVENTS
                                                                       &read_table &get_session_param
                                                                       &init_email_report &send_email_report
																	                                     &CSV_prepare_table &CSV_insert_into_table &CSV_import_from_table &CSV_cleanup_table
                                                                       &DBI_connect &DBI_do &DBI_execute
                                                                       &LOG_init_log4perl) ],

                                                  DBARCHIVE    => [ qw($DATABASE $CATALOGID $SERVERMYSQLVERSION $SERVERMYSQLMERGE $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE $SERVERTABLEVENTS $SERVERTABLCOMMENTS)],

                                                  COLLECTOR    => [ qw($APPLICATIONPATH

                                                                       $DEBUGDIR
                                                                       $CHARTDIRECTORLIB
                                                                       $HTTPSPATH $RESULTSPATH $PIDPATH
                                                                       $PERFPARSEBIN $PERFPARSEETC $PERFPARSELIB $PERFPARSESHARE $PERFPARSECGI $PERFPARSEENABLED
                                                                       $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                                                       %COLORSRRD %ENVIRONMENT @EVENTS %EVENTS
                                                                       &read_table &get_trendline_from_test
                                                                       &set_doIt_and_doOffline
                                                                       &create_header &create_footer
                                                                       &CSV_prepare_table &CSV_insert_into_table &CSV_import_from_table &CSV_cleanup_table
                                                                       &DBI_connect &DBI_do &DBI_execute
                                                                       &LOG_init_log4perl
                                                                       &print_revision &usage &call_system) ],

                                                  DBCOLLECTOR  => [ qw($DATABASE $CATALOGID $SERVERMYSQLVERSION $SERVERMYSQLMERGE $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                                                       $SERVERTABLCOMMENTS $SERVERTABLEVENTS $SERVERTABLEVENTSCHNGSLGDT $SERVERTABLEVENTSDISPLAYDT) ],
 
                                                  DISPLAY      => [ qw($APPLICATIONPATH

                                                                       $AWSTATSENABLED
                                                                       $HTTPSPATH $RESULTSPATH $PIDPATH
                                                                       $HTTPSURL $IMAGESURL $RESULTSURL
                                                                       $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                                                       $NUMBEROFFTESTS $VERIFYNUMBEROK $VERIFYMINUTEOK $STATUSHEADER01
                                                                       %COLORS %ICONS %ICONSACK %ICONSUNSTABLE %ICONSRECORD %ENVIRONMENT %SOUND
                                                                       &read_table &get_trendline_from_test
                                                                       &create_header &create_footer &encode_html_entities &decode_html_entities &print_header &print_legend

                                                                       &print_revision &usage &call_system) ],
 
                                                  DBDISPLAY    => [ qw($DATABASE $CATALOGID $SERVERMYSQLVERSION $SERVERMYSQLMERGE $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE 
                                                                       $SERVERTABLCOMMENTS $SERVERTABLEVENTS $SERVERTABLEVENTSCHNGSLGDT $SERVERTABLEVENTSDISPLAYDT) ],
									   
                                                  CGI          => [ qw($APPLICATIONPATH

                                                                       $ASNMTAPMANUAL
                                                                       $DATABASE $CATALOGID
                                                                       $AWSTATSENABLED
                                                                       $CONFIGDIR $CGISESSDIR $DEBUGDIR $REPORTDIR $RESULTSDIR
                                                                       $CGISESSPATH $HTTPSPATH $IMAGESPATH $PDPHELPPATH $RESULTSPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH $SSHKEYPATH $WWWKEYPATH
                                                                       $HTTPSSERVER $REMOTE_HOST $REMOTE_ADDR $HTTPSURL $IMAGESURL $PDPHELPURL $RESULTSURL
                                                                       $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                                                       $SSHLOGONNAME $RSYNCIDENTITY $SSHIDENTITY $WWWIDENTITY
                                                                       $RMVERSION $RMDEFAULTUSER
                                                                       $CHARTDIRECTORLIB
                                                                       $HTMLTOPDFPRG $HTMLTOPDFHOW $HTMLTOPDFOPTNS
                                                                       $PERFPARSEBIN $PERFPARSEETC $PERFPARSELIB $PERFPARSESHARE $PERFPARSECGI $PERFPARSEENABLED
                                                                       $PERFPARSEVERSION $PERFPARSECONFIG $PERFPARSEDATABASE $PERFPARSEHOST $PERFPARSEPORT $PERFPARSEUSERNAME $PERFPARSEPASSWORD
                                                                       $RECORDSONPAGE $NUMBEROFFTESTS $VERIFYNUMBEROK $VERIFYMINUTEOK $FIRSTSTARTDATE $STRICTDATE
                                                                       %COLORS %COLORSPIE %COLORSRRD %COLORSTABLE %ICONS %ICONSACK %ICONSUNSTABLE %ICONSRECORD %ICONSSYSTEM %ENVIRONMENT %SOUND %QUARTERS
                                                                       &get_session_param
                                                                       &set_doIt_and_doOffline
                                                                       &encode_html_entities &print_header &print_legend
 
                                                                       $SERVERMYSQLVERSION $SERVERMYSQLMERGE
                                                                       $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                                                       $SERVERNAMEREADONLY $SERVERPORTREADONLY $SERVERUSERREADONLY $SERVERPASSREADONLY
                                                                       $SERVERTABLCATALOG $SERVERTABLCLLCTRDMNS $SERVERTABLCOMMENTS $SERVERTABLCOUNTRIES $SERVERTABLCRONTABS $SERVERTABLDISPLAYDMNS $SERVERTABLDISPLAYGRPS $SERVERTABLENVIRONMENT $SERVERTABLEVENTS $SERVERTABLEVENTSCHNGSLGDT $SERVERTABLEVENTSDISPLAYDT $SERVERTABLHOLIDYS $SERVERTABLHOLIDYSBNDL $SERVERTABLLANGUAGE $SERVERTABLPAGEDIRS $SERVERTABLPLUGINS $SERVERTABLREPORTS $SERVERTABLREPORTSPRFDT $SERVERTABLRESULTSDIR $SERVERTABLSERVERS $SERVERTABLTIMEPERIODS $SERVERTABLUSERS $SERVERTABLVIEWS) ] );

  @ASNMTAP::Asnmtap::Applications::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Applications::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Applications::VERSION     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# TMP, exist into: Asnmtap

sub print_revision ($$);
sub usage;
sub call_system;

sub print_revision ($$) {
  my $commandName = shift;
  my $pluginRevision = shift;
  $pluginRevision =~ s/^\$Revision: //;
  $pluginRevision =~ s/ \$\s*$//;

  print "
$commandName $pluginRevision

© Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]

";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub usage {
  my $format = shift;
  printf($format, @_);
  exit $ERRORS{UNKNOWN};
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub call_system {
  my ($system_action, $debug) = @_;

  my ($stdout, $stderr, $exit_value, $signal_num, $dumped_core, $status);

  if ($CAPTUREOUTPUT) {
    use IO::CaptureOutput qw(capture_exec);
   ($stdout, $stderr) = capture_exec("$system_action");
   chomp($stdout); chomp($stderr);
  } else {
    system ("$system_action"); $stdout = $stderr = '';
  }

  $exit_value  = $? >> 8;
  $signal_num  = $? & 127;
  $dumped_core = $? & 128;
  $status = ( $exit_value == 0 && $signal_num == 0 && $dumped_core == 0 && $stderr eq '' ) ? 1 : 0;
  print "< $system_action >< $exit_value >< $signal_num >< $dumped_core >< $status >< $stdout >< $stderr >\n" if ($debug);
  return ($status, $stdout, $stderr);
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub read_table;
sub get_session_param;
sub get_trendline_from_test;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub _in_cyclus;
sub set_doIt_and_doOffline;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub create_header;
sub create_footer;

sub encode_html_entities;
sub decode_html_entities;

sub print_header;
sub print_legend;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub init_email_report;
sub send_email_report;
sub sending_mail;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub CSV_prepare_table;
sub CSV_insert_into_table;
sub CSV_import_from_table;
sub CSV_cleanup_table;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub DBI_connect;
sub DBI_do;
sub DBI_execute;
sub DBI_error_trap;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub LOG_init_log4perl;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs without TAGS  = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Common variables  = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Applications variables  - - - - - - - - - - - - - - - - - - - - - - - -

our $RMVERSION = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

our %QUARTERS  = ( '1' => '1', '2' => '4', '3' => '7', '4' => '10' );

# read config file  - - - - - - - - - - - - - - - - - - - - - - - - - - -

my %_config;

my $_configfile = "$APPLICATIONPATH/Applications.cnf";

if ( -e $_configfile ) {
  use Config::General qw(ParseConfig);
  %_config = ParseConfig ( -ConfigFile => $_configfile, -InterPolateVars => 0 ) ;
  die "ASNMTAP::Asnmtap::Applications: Config '$_configfile' can't be loaded." unless (%_config);
  undef $_configfile;
}

# SET ASNMTAP::Asnmtap::Applications VARIABLES  - - - - - - - - - - - - -

our $ASNMTAPMANUAL  = ( exists $_config{COMMON}{ASNMTAPMANUAL}     ? $_config{COMMON}{ASNMTAPMANUAL}     : 'ApplicationMonitorVersion2.000.xxx.pdf' );

our $SMTPUNIXSYSTEM = ( exists $_config{COMMON}{SMTPUNIXSYSTEM}    ? $_config{COMMON}{SMTPUNIXSYSTEM}    : 1 );
my  $serverListSMTP = ( exists $_config{COMMON}{SERVERLISTSMTP}    ? $_config{COMMON}{SERVERLISTSMTP}    : 'localhost' );
our $SERVERLISTSMTP = [ split ( /\s+/, $serverListSMTP ) ];
our $SERVERSMTP     = ( exists $_config{COMMON}{SERVERSMTP}        ? $_config{COMMON}{SERVERSMTP}        : 'localhost' );
our $SENDMAILFROM   = ( exists $_config{COMMON}{SENDMAILFROM}      ? $_config{COMMON}{SENDMAILFROM}      : 'asnmtap@localhost' );

our $HTTPSSERVER    = ( exists $_config{COMMON}{HTTPSSERVER}       ? $_config{COMMON}{HTTPSSERVER}       : 'asnmtap.localhost' );
our $REMOTE_HOST    = ( exists $_config{COMMON}{REMOTE_HOST}       ? $_config{COMMON}{REMOTE_HOST}       : 'localhost' );
our $REMOTE_ADDR    = ( exists $_config{COMMON}{REMOTE_ADDR}       ? $_config{COMMON}{REMOTE_ADDR}       : '127.0.0.1' );

our $SSHLOGONNAME   = ( exists $_config{COMMON}{SSHLOGONNAME}      ? $_config{COMMON}{SSHLOGONNAME}      : 'asnmtap' );
our $RSYNCIDENTITY  = ( exists $_config{COMMON}{RSYNCIDENTITY}     ? $_config{COMMON}{RSYNCIDENTITY}     : 'rsync' );
our $SSHIDENTITY    = ( exists $_config{COMMON}{SSHIDENTITY}       ? $_config{COMMON}{SSHIDENTITY}       : 'asnmtap' );
our $WWWIDENTITY    = ( exists $_config{COMMON}{WWWIDENTITY}       ? $_config{COMMON}{WWWIDENTITY}       : 'ssh' );

our $RMDEFAULTUSER  = ( exists $_config{COMMON}{RMDEFAULTUSER}     ? $_config{COMMON}{RMDEFAULTUSER}     : 'admin' );

our $RECORDSONPAGE  = ( exists $_config{COMMON}{RECORDSONPAGE}     ? $_config{COMMON}{RECORDSONPAGE}     : 10 );
our $NUMBEROFFTESTS = ( exists $_config{COMMON}{NUMBEROFFTESTS}    ? $_config{COMMON}{NUMBEROFFTESTS}    : 9 );
our $VERIFYNUMBEROK = ( exists $_config{COMMON}{VERIFYNUMBEROK}    ? $_config{COMMON}{VERIFYNUMBEROK}    : 3 );
our $VERIFYMINUTEOK = ( exists $_config{COMMON}{VERIFYMINUTEOK}    ? $_config{COMMON}{VERIFYMINUTEOK}    : 30 );
our $FIRSTSTARTDATE = ( exists $_config{COMMON}{FIRSTSTARTDATE}    ? $_config{COMMON}{FIRSTSTARTDATE}    : '2004-10-31' );
our $STRICTDATE     = ( exists $_config{COMMON}{STRICTDATE}        ? $_config{COMMON}{STRICTDATE}        : 0 );
our $STATUSHEADER01 = ( exists $_config{COMMON}{STATUSHEADER01}    ? $_config{COMMON}{STATUSHEADER01}    : 'De resultaten worden weergegeven binnen timeslots van vastgestelde duur per groep. De testen binnen éénzelfde groep worden sequentieel uitgevoerd.' );

our $CONFIGDIR      = 'config';
our $CGISESSDIR     = 'cgisess';
our $DEBUGDIR       = 'debug';
our $REPORTDIR      = 'reports';
our $RESULTSDIR     = 'results';

if ( exists $_config{SUBDIR} ) {
  $CONFIGDIR        = $_config{SUBDIR}{CONFIG}  if ( exists $_config{SUBDIR}{CONFIG} );
  $CGISESSDIR       = $_config{SUBDIR}{CGISESS} if ( exists $_config{SUBDIR}{CGISESS} );
  $DEBUGDIR         = $_config{SUBDIR}{DEBUG}   if ( exists $_config{SUBDIR}{DEBUG} );
  $REPORTDIR        = $_config{SUBDIR}{REPORT}  if ( exists $_config{SUBDIR}{REPORT} );
  $RESULTSDIR       = $_config{SUBDIR}{RESULTS} if ( exists $_config{SUBDIR}{RESULTS} );
}

our $CGISESSPATH    = "$APPLICATIONPATH/tmp/$CGISESSDIR";

our $HTTPSPATH      = "$APPLICATIONPATH/htmlroot";
our $IMAGESPATH     = "$HTTPSPATH/img";
our $PDPHELPPATH    = "$HTTPSPATH/pdf";
our $RESULTSPATH    = "$PREFIXPATH/$RESULTSDIR";
our $SSHKEYPATH     = '/home';
our $WWWKEYPATH     = '/var/www';

if ( exists $_config{PATH} ) {
  $HTTPSPATH        = $_config{PATH}{HTTPS}   if ( exists $_config{PATH}{HTTPS} );
  $IMAGESPATH       = $_config{PATH}{IMAGES}  if ( exists $_config{PATH}{IMAGES} );
  $PDPHELPPATH      = $_config{PATH}{PDPHELP} if ( exists $_config{PATH}{PDPHELP} );
  $RESULTSPATH      = $_config{PATH}{RESULTS} if ( exists $_config{PATH}{RESULTS} );
  $SSHKEYPATH       = $_config{PATH}{SSHKEY}  if ( exists $_config{PATH}{SSHKEY} );
  $WWWKEYPATH       = $_config{PATH}{WWWKEY}  if ( exists $_config{PATH}{WWWKEY} );
}

our $HTTPSURL       = '/asnmtap';
our $IMAGESURL      = "$HTTPSURL/img";
our $PDPHELPURL     = "$HTTPSURL/pdf";
our $RESULTSURL     = "/$RESULTSDIR";

if ( exists $_config{URL} ) {
  $HTTPSURL         = $_config{URL}{HTTPS}   if ( exists $_config{URL}{HTTPS} );
  $IMAGESURL        = $_config{URL}{IMAGES}  if ( exists $_config{URL}{IMAGES} );
  $PDPHELPURL       = $_config{URL}{PDPHELP} if ( exists $_config{URL}{PDPHELP} );
  $RESULTSURL       = $_config{URL}{RESULTS} if ( exists $_config{URL}{RESULTS} );
}

our $AWSTATSENABLED    = ( exists $_config{COMMON}{AWSTATS}{ENABLED}    ? $_config{COMMON}{AWSTATS}{ENABLED}    : 1 );

our $CHARTDIRECTORLIB  = ( exists $_config{COMMON}{CHARTDIRECTOR}{LIB}  ? $_config{COMMON}{CHARTDIRECTOR}{LIB}  : '/opt/ChartDirector/lib/.' );

our $HTMLTOPDFPRG      = ( exists $_config{COMMON}{HTMLTOPDF}{PRG}      ? $_config{COMMON}{HTMLTOPDF}{PRG}      : 'htmldoc' );
our $HTMLTOPDFHOW      = ( exists $_config{COMMON}{HTMLTOPDF}{HOW}      ? $_config{COMMON}{HTMLTOPDF}{HOW}      : 'shell' );
our $HTMLTOPDFOPTNS    = ( exists $_config{COMMON}{HTMLTOPDF}{OPTIONS}  ? $_config{COMMON}{HTMLTOPDF}{OPTIONS}  : "--bodyimage $IMAGESPATH/logos/bodyimage.gif --format pdf14 --size A4 --landscape --browserwidth 1280 --top 10mm --bottom 10mm --left 10mm --right 10mm --fontsize 10.0 --fontspacing 1.2 --headingfont Helvetica --bodyfont Helvetica --headfootsize 10.0 --headfootfont Helvetica --embedfonts --pagemode fullscreen --permissions no-copy,print --no-links --color --quiet --webpage" );

our $DATABASE          = ( exists $_config{DATABASE}{ASNMTAP}           ? $_config{DATABASE}{ASNMTAP}           : 'asnmtap' );
our $CATALOGID         = ( exists $_config{DATABASE}{CATALOGID}         ? $_config{DATABASE}{CATALOGID}         : 'CID' );

# SET ASNMTAP::Asnmtap::Applications::CSV VARIABLES - - - - - - - - - - -
our @EVENTS = ('catalogID', 'id', 'uKey', 'replicationStatus', 'test', 'title', 'status', 'startDate', 'startTime', 'endDate', 'endTime', 'duration', 'statusMessage', 'perfdata', 'step', 'timeslot', 'instability', 'persistent', 'downtime', 'filename');

our %EVENTS = (
  'catalogID'         => 'varchar(5)',
  'id'                => 'int(11)',
  'uKey'              => 'varchar(11)',
  'replicationStatus' => 'char(1)',
  'test'              => 'varchar(254)',
  'title'             => 'varchar(75)',
  'status'            => 'varchar(9)',
  'startDate'         => 'char(10)',
  'startTime'         => 'char(8)',
  'endDate'           => 'char(10)',
  'endTime'           => 'char(8)',
  'duration'          => 'char(8)',
  'statusMessage'     => 'varchar(1024)',
  'perfdata'          => 'text',
  'step'              => 'int(6)',
  'timeslot'          => 'varchar(10)',
  'instability'       => 'int(1)',
  'persistent'        => 'int(1)',
  'downtime'          => 'int(1)',
  'filename'          => 'varchar(254)'
);

# CGI.pm  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# archiver.pl - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
our $SERVERMYSQLVERSION     = ( exists $_config{DATABASE_ACCOUNT}{SERVER}{VERSION}     ? $_config{DATABASE_ACCOUNT}{SERVER}{VERSION}     : '5.0.x' );
our $SERVERMYSQLMERGE       = ( exists $_config{DATABASE_ACCOUNT}{SERVER}{MERGE}       ? $_config{DATABASE_ACCOUNT}{SERVER}{MERGE}       : '0' );

$SERVERMYSQLVERSION         = '5.0.x' unless ( $SERVERMYSQLVERSION eq '5.1.x' );
$SERVERMYSQLMERGE           = '0'   unless ( $SERVERMYSQLMERGE eq '1' );

# archiver.pl, collector.pl and display.pl  - - - - - - - - - - - - - - -
# comments.pl, holidayBundleSetDowntimes.pl - - - - - - - - - - - - - - -
# scripts into directory /cgi-bin/admin & /cgi-bin/sadmin - - - - - - - -
our $SERVERNAMEREADWRITE    = ( exists $_config{DATABASE_ACCOUNT}{READWRITE}{HOST}     ? $_config{DATABASE_ACCOUNT}{READWRITE}{HOST}     : 'localhost' );
our $SERVERPORTREADWRITE    = ( exists $_config{DATABASE_ACCOUNT}{READWRITE}{PORT}     ? $_config{DATABASE_ACCOUNT}{READWRITE}{PORT}     : '3306' );
our $SERVERUSERREADWRITE    = ( exists $_config{DATABASE_ACCOUNT}{READWRITE}{USERNAME} ? $_config{DATABASE_ACCOUNT}{READWRITE}{USERNAME} : 'asnmtap' );
our $SERVERPASSREADWRITE    = ( exists $_config{DATABASE_ACCOUNT}{READWRITE}{PASSWORD} ? $_config{DATABASE_ACCOUNT}{READWRITE}{PASSWORD} : 'asnmtap' );

# comments.pl, generateChart.pl, getHelpPlugin.pl, runCommandOnDemand.pl
# and detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl -
our $SERVERNAMEREADONLY     = ( exists $_config{DATABASE_ACCOUNT}{READONLY}{HOST}      ? $_config{DATABASE_ACCOUNT}{READONLY}{HOST}      : 'localhost' );
our $SERVERPORTREADONLY     = ( exists $_config{DATABASE_ACCOUNT}{READONLY}{PORT}      ? $_config{DATABASE_ACCOUNT}{READONLY}{PORT}      : '3306' );
our $SERVERUSERREADONLY     = ( exists $_config{DATABASE_ACCOUNT}{READONLY}{USERNAME}  ? $_config{DATABASE_ACCOUNT}{READONLY}{USERNAME}  : 'asnmtapro' );
our $SERVERPASSREADONLY     = ( exists $_config{DATABASE_ACCOUNT}{READONLY}{PASSWORD}  ? $_config{DATABASE_ACCOUNT}{READONLY}{PASSWORD}  : 'asnmtapro' );

# collector.pl, perfdata.pl & reports.pl
our $PERFPARSEBIN      = ( exists $_config{COMMON}{PERFPARSE}{BIN}      ? $_config{COMMON}{PERFPARSE}{BIN}      : $PREFIXPATH .'/perfparse/bin' );
our $PERFPARSEETC      = ( exists $_config{COMMON}{PERFPARSE}{ETC}      ? $_config{COMMON}{PERFPARSE}{ETC}      : $PREFIXPATH .'/perfparse/etc' );
our $PERFPARSELIB      = ( exists $_config{COMMON}{PERFPARSE}{LIB}      ? $_config{COMMON}{PERFPARSE}{LIB}      : $PREFIXPATH .'/perfparse/lib' );
our $PERFPARSESHARE    = ( exists $_config{COMMON}{PERFPARSE}{SHARE}    ? $_config{COMMON}{PERFPARSE}{SHARE}    : $PREFIXPATH .'/perfparse/share' );
our $PERFPARSECGI      = ( exists $_config{COMMON}{PERFPARSE}{CGI}      ? $_config{COMMON}{PERFPARSE}{CGI}      : '/cgi-bin/perfparse.cgi' );
our $PERFPARSEENABLED  = ( exists $_config{COMMON}{PERFPARSE}{ENABLED}  ? $_config{COMMON}{PERFPARSE}{ENABLED}  : 1 );

our $PERFPARSEVERSION  = ( exists $_config{COMMON}{PERFPARSE}{VERSION}  ? $_config{COMMON}{PERFPARSE}{VERSION}  : 19 );
our $PERFPARSECONFIG   = ( exists $_config{COMMON}{PERFPARSE}{CONFIG}   ? $_config{COMMON}{PERFPARSE}{CONFIG}   : 'perfparse.cfg' );
our $PERFPARSEDATABASE = ( exists $_config{COMMON}{PERFPARSE}{DATABASE} ? $_config{COMMON}{PERFPARSE}{DATABASE} : $DATABASE );
our $PERFPARSEHOST     = ( exists $_config{COMMON}{PERFPARSE}{HOST}     ? $_config{COMMON}{PERFPARSE}{HOST}     : $SERVERNAMEREADWRITE );
our $PERFPARSEPORT     = ( exists $_config{COMMON}{PERFPARSE}{PORT}     ? $_config{COMMON}{PERFPARSE}{PORT}     : $SERVERPORTREADWRITE );
our $PERFPARSEUSERNAME = ( exists $_config{COMMON}{PERFPARSE}{USERNAME} ? $_config{COMMON}{PERFPARSE}{USERNAME} : $SERVERUSERREADWRITE );
our $PERFPARSEPASSWORD = ( exists $_config{COMMON}{PERFPARSE}{PASSWORD} ? $_config{COMMON}{PERFPARSE}{PASSWORD} : $SERVERPASSREADWRITE );

# tables
our $SERVERTABLCATALOG         = 'catalog';
our $SERVERTABLCLLCTRDMNS      = 'collectorDaemons';
our $SERVERTABLCOMMENTS        = 'comments';
our $SERVERTABLCOUNTRIES       = 'countries';
our $SERVERTABLCRONTABS        = 'crontabs';
our $SERVERTABLDISPLAYDMNS     = 'displayDaemons';
our $SERVERTABLDISPLAYGRPS     = 'displayGroups';
our $SERVERTABLENVIRONMENT     = 'environment';
our $SERVERTABLEVENTS          = 'events';
our $SERVERTABLEVENTSCHNGSLGDT = 'eventsChangesLogData';
our $SERVERTABLEVENTSDISPLAYDT = 'eventsDisplayData';
our $SERVERTABLHOLIDYS         = 'holidays';
our $SERVERTABLHOLIDYSBNDL     = 'holidaysBundle';
our $SERVERTABLLANGUAGE        = 'language';
our $SERVERTABLPAGEDIRS        = 'pagedirs';
our $SERVERTABLPLUGINS         = 'plugins';
our $SERVERTABLREPORTS         = 'reports';
our $SERVERTABLREPORTSPRFDT    = 'reports_perfdata';
our $SERVERTABLRESULTSDIR      = 'resultsdir';
our $SERVERTABLSERVERS         = 'servers';
our $SERVERTABLTIMEPERIODS     = 'timeperiods';
our $SERVERTABLUSERS           = 'users';
our $SERVERTABLVIEWS           = 'views';

if ( exists $_config{TABLES} ) {
  $SERVERTABLCATALOG           = $_config{TABLES}{CATALOG}              if ( exists $_config{TABLES}{CATALOG} );
  $SERVERTABLCLLCTRDMNS        = $_config{TABLES}{COLLECTORDAEMONS}     if ( exists $_config{TABLES}{COLLECTORDAEMONS} );
  $SERVERTABLCOMMENTS          = $_config{TABLES}{COMMENTS}             if ( exists $_config{TABLES}{COMMENTS} );
  $SERVERTABLCOUNTRIES         = $_config{TABLES}{COUNTRIES}            if ( exists $_config{TABLES}{COUNTRIES} );
  $SERVERTABLCRONTABS          = $_config{TABLES}{CRONTABS}             if ( exists $_config{TABLES}{CRONTABS} );
  $SERVERTABLDISPLAYDMNS       = $_config{TABLES}{DISPLAYDAEMONS}       if ( exists $_config{TABLES}{DISPLAYDAEMONS} );
  $SERVERTABLDISPLAYGRPS       = $_config{TABLES}{DISPLAYGROUPS}        if ( exists $_config{TABLES}{DISPLAYGROUPS} );
  $SERVERTABLENVIRONMENT       = $_config{TABLES}{ENVIRONMENT}          if ( exists $_config{TABLES}{ENVIRONMENT} );
  $SERVERTABLEVENTS            = $_config{TABLES}{EVENTS}               if ( exists $_config{TABLES}{EVENTS} );
  $SERVERTABLEVENTSCHNGSLGDT   = $_config{TABLES}{EVENTSCHANGESLOGDATA} if ( exists $_config{TABLES}{EVENTSCHANGESLOGDATA} );
  $SERVERTABLEVENTSDISPLAYDT   = $_config{TABLES}{EVENTSDISPLAYDATA}    if ( exists $_config{TABLES}{EVENTSDISPLAYDATA} );
  $SERVERTABLHOLIDYS           = $_config{TABLES}{HOLIDAYS}             if ( exists $_config{TABLES}{HOLIDAYS} );
  $SERVERTABLHOLIDYSBNDL       = $_config{TABLES}{HOLIDAYSBUNDLE}       if ( exists $_config{TABLES}{HOLIDAYSBUNDLE} );
  $SERVERTABLLANGUAGE          = $_config{TABLES}{LANGUAGE}             if ( exists $_config{TABLES}{LANGUAGE} );
  $SERVERTABLPAGEDIRS          = $_config{TABLES}{PAGEDIRS}             if ( exists $_config{TABLES}{PAGEDIRS} );
  $SERVERTABLPLUGINS           = $_config{TABLES}{PLUGINS}              if ( exists $_config{TABLES}{PLUGINS} );
  $SERVERTABLREPORTS           = $_config{TABLES}{REPORTS}              if ( exists $_config{TABLES}{REPORTS} );
  $SERVERTABLREPORTSPRFDT      = $_config{TABLES}{REPORTSPERFDATA}      if ( exists $_config{TABLES}{REPORTSPERFDATA} );
  $SERVERTABLRESULTSDIR        = $_config{TABLES}{RESULTSDIR}           if ( exists $_config{TABLES}{RESULTSDIR} );
  $SERVERTABLSERVERS           = $_config{TABLES}{SERVERS}              if ( exists $_config{TABLES}{SERVERS} );
  $SERVERTABLTIMEPERIODS       = $_config{TABLES}{TIMEPERIODS}          if ( exists $_config{TABLES}{TIMEPERIODS} );
  $SERVERTABLUSERS             = $_config{TABLES}{USERS}                if ( exists $_config{TABLES}{USERS} );
  $SERVERTABLVIEWS             = $_config{TABLES}{VIEWS}                if ( exists $_config{TABLES}{VIEWS} );
}

our %COLORS      = ('OK'=>'#99CC99','WARNING'=>'#FFFF00','CRITICAL'=>'#FF4444','UNKNOWN'=>'#FFFFFF','DEPENDENT'=>'#D8D8BF','OFFLINE'=>'#0000FF','NO DATA'=>'#CC00CC','IN PROGRESS'=>'#99CC99','NO TEST'=>'#99CC99', '<NIHIL>'=>'#CC00CC','TRENDLINE'=>'#ffa000');
our %COLORSPIE   = ('OK'=>0x00BA00, 'WARNING'=>0xffff00, 'CRITICAL'=>0xff0000, 'UNKNOWN'=>0x99FFFF, 'DEPENDENT'=>0xD8D8BF, 'OFFLINE'=>0x0000FF, 'NO DATA'=>0xCC00CC, 'IN PROGRESS'=>0x99CC99, 'NO TEST'=>0x444444,  '<NIHIL>'=>0xCC00CC, 'TRENDLINE'=>0xffa000);
our %COLORSRRD   = ('OK'=>0x00BA00, 'WARNING'=>0xffff00, 'CRITICAL'=>0xff0000, 'UNKNOWN'=>0x99FFFF, 'DEPENDENT'=>0xD8D8BF, 'OFFLINE'=>0x0000FF, 'NO DATA'=>0xCC00CC, 'IN PROGRESS'=>0x99CC99, 'NO TEST'=>0x000000,  '<NIHIL>'=>0xCC00CC, 'TRENDLINE'=>0xffa000);
our %COLORSTABLE = ('TABLE'=>'#333344', 'NOBLOCK'=>'#335566','ENDBLOCK'=>'#665555','STARTBLOCK'=>'#996666');

if ( exists $_config{COLORS} ) {
  $COLORS{OK}            = '#'. $_config{COLORS}{OK}          if ( exists $_config{COLORS}{OK} );
  $COLORS{WARNING}       = '#'. $_config{COLORS}{WARNING}     if ( exists $_config{COLORS}{WARNING} );
  $COLORS{CRITICAL}      = '#'. $_config{COLORS}{CRITICAL}    if ( exists $_config{COLORS}{CRITICAL} );
  $COLORS{UNKNOWN}       = '#'. $_config{COLORS}{UNKNOWN}     if ( exists $_config{COLORS}{UNKNOWN} );
  $COLORS{DEPENDENT}     = '#'. $_config{COLORS}{DEPENDENT}   if ( exists $_config{COLORS}{DEPENDENT} );
  $COLORS{OFFLINE}       = '#'. $_config{COLORS}{OFFLINE}     if ( exists $_config{COLORS}{OFFLINE} );
  $COLORS{'NO DATA'}     = '#'. $_config{COLORS}{NO_DATA}     if ( exists $_config{COLORS}{NO_DATA} );
  $COLORS{'IN PROGRESS'} = '#'. $_config{COLORS}{IN_PROGRESS} if ( exists $_config{COLORS}{IN_PROGRESS} );
  $COLORS{'NO TEST'}     = '#'. $_config{COLORS}{NO_TEST}     if ( exists $_config{COLORS}{NO_TEST} );
  $COLORS{'<NIHIL>'}     = '#'. $_config{COLORS}{_NIHIL_}     if ( exists $_config{COLORS}{_NIHIL_} );
  $COLORS{TRENDLINE}     = '#'. $_config{COLORS}{TRENDLINE}   if ( exists $_config{COLORS}{TRENDLINE} );

  if ( exists $_config{COLORS}{PIE} ) {
    $COLORSPIE{OK}            = $_config{COLORS}{PIE}{OK}          if ( exists $_config{COLORS}{PIE}{OK} );
    $COLORSPIE{WARNING}       = $_config{COLORS}{PIE}{WARNING}     if ( exists $_config{COLORS}{PIE}{WARNING} );
    $COLORSPIE{CRITICAL}      = $_config{COLORS}{PIE}{CRITICAL}    if ( exists $_config{COLORS}{PIE}{CRITICAL} );
    $COLORSPIE{UNKNOWN}       = $_config{COLORS}{PIE}{UNKNOWN}     if ( exists $_config{COLORS}{PIE}{UNKNOWN} );
    $COLORSPIE{DEPENDENT}     = $_config{COLORS}{PIE}{DEPENDENT}   if ( exists $_config{COLORS}{PIE}{DEPENDENT} );
    $COLORSPIE{OFFLINE}       = $_config{COLORS}{PIE}{OFFLINE}     if ( exists $_config{COLORS}{PIE}{OFFLINE} );
    $COLORSPIE{'NO DATA'}     = $_config{COLORS}{PIE}{NO_DATA}     if ( exists $_config{COLORS}{PIE}{NO_DATA} );
    $COLORSPIE{'IN PROGRESS'} = $_config{COLORS}{PIE}{IN_PROGRESS} if ( exists $_config{COLORS}{PIE}{IN_PROGRESS} );
    $COLORSPIE{'NO TEST'}     = $_config{COLORS}{PIE}{NO_TEST}     if ( exists $_config{COLORS}{PIE}{NO_TEST} );
    $COLORSPIE{'<NIHIL>'}     = $_config{COLORS}{PIE}{_NIHIL_}     if ( exists $_config{COLORS}{PIE}{_NIHIL_} );
    $COLORSPIE{TRENDLINE}     = $_config{COLORS}{PIE}{TRENDLINE}   if ( exists $_config{COLORS}{PIE}{TRENDLINE} );
  }

  if ( exists $_config{COLORS}{RRD} ) {
    $COLORSRRD{OK}            = $_config{COLORS}{RRD}{OK}          if ( exists $_config{COLORS}{RRD}{OK} );
    $COLORSRRD{WARNING}       = $_config{COLORS}{RRD}{WARNING}     if ( exists $_config{COLORS}{RRD}{WARNING} );
    $COLORSRRD{CRITICAL}      = $_config{COLORS}{RRD}{CRITICAL}    if ( exists $_config{COLORS}{RRD}{CRITICAL} );
    $COLORSRRD{UNKNOWN}       = $_config{COLORS}{RRD}{UNKNOWN}     if ( exists $_config{COLORS}{RRD}{UNKNOWN} );
    $COLORSRRD{DEPENDENT}     = $_config{COLORS}{RRD}{DEPENDENT}   if ( exists $_config{COLORS}{RRD}{DEPENDENT} );
    $COLORSRRD{OFFLINE}       = $_config{COLORS}{RRD}{OFFLINE}     if ( exists $_config{COLORS}{RRD}{OFFLINE} );
    $COLORSRRD{'NO DATA'}     = $_config{COLORS}{RRD}{NO_DATA}     if ( exists $_config{COLORS}{RRD}{NO_DATA} );
    $COLORSRRD{'IN PROGRESS'} = $_config{COLORS}{RRD}{IN_PROGRESS} if ( exists $_config{COLORS}{RRD}{IN_PROGRESS} );
    $COLORSRRD{'NO TEST'}     = $_config{COLORS}{RRD}{NO_TEST}     if ( exists $_config{COLORS}{RRD}{NO_TEST} );
    $COLORSRRD{'<NIHIL>'}     = $_config{COLORS}{RRD}{_NIHIL_}     if ( exists $_config{COLORS}{RRD}{_NIHIL_} );
    $COLORSRRD{TRENDLINE}     = $_config{COLORS}{RRD}{TRENDLINE}   if ( exists $_config{COLORS}{RRD}{TRENDLINE} );
  }

  if ( exists $_config{COLORS}{TABLE} ) {
    $COLORSTABLE{TABLE}       = '#'. $_config{COLORS}{TABLE}{TABLE}      if ( exists $_config{COLORS}{TABLE}{TABLE} );
    $COLORSTABLE{NOBLOCK}     = '#'. $_config{COLORS}{TABLE}{NOBLOCK}    if ( exists $_config{COLORS}{TABLE}{NOBLOCK} );
    $COLORSTABLE{ENDBLOCK}    = '#'. $_config{COLORS}{TABLE}{ENDBLOCK}   if ( exists $_config{COLORS}{TABLE}{ENDBLOCK} );
    $COLORSTABLE{STARTBLOCK}  = '#'. $_config{COLORS}{TABLE}{STARTBLOCK} if ( exists $_config{COLORS}{TABLE}{STARTBLOCK} );
  }
}

our %ENVIRONMENT   = ('P'=>'Production', 'S'=>'Simulation', 'A'=>'Acceptation', 'T'=>'Test', 'D'=>'Development', 'L'=>'Local');

our %ICONS         = ('OK'=>'green.gif','WARNING'=>'yellow.gif','CRITICAL'=>'red.gif','UNKNOWN'=>'clear.gif','DEPENDENT'=>'','OFFLINE'=>'blue.gif','NO DATA'=>'purple.gif','IN PROGRESS'=>'running.gif','NO TEST'=>'notest.gif','TRENDLINE'=>'orange.gif');
our %ICONSACK      = ('OK'=>'green-ack.gif','WARNING'=>'yellow-ack.gif','CRITICAL'=>'red-ack.gif','UNKNOWN'=>'clear-ack.gif','DEPENDENT'=>'','OFFLINE'=>'blue-ack.gif','NO DATA'=>'purple-ack.gif','IN PROGRESS'=>'running.gif','NO TEST'=>'notest-ack.gif','TRENDLINE'=>'orange-ack.gif');
our %ICONSUNSTABLE = ('OK'=>'green-unstable.gif','WARNING'=>'yellow-unstable.gif','CRITICAL'=>'red-unstable.gif','UNKNOWN'=>'clear-unstable.gif','DEPENDENT'=>'','OFFLINE'=>'blue-unstable.gif','NO DATA'=>'purple-unstable.gif','IN PROGRESS'=>'running.gif','NO TEST'=>'notest-unstable.gif','TRENDLINE'=>'orange-unstable.gif');
our %ICONSRECORD   = ('maintenance'=>'maintenance.gif', 'duplicate'=>'recordDuplicate.gif', 'delete'=>'recordDelete.gif', 'details'=>'recordDetails.gif', 'query'=>'recordQuery.gif', 'edit'=>'recordEdit.gif', 'table'=>'recordTable.gif', 'up'=>'1arrowUp.gif', 'down'=>'1arrowDown.gif', 'left'=>'1arrowLeft.gif', 'right'=>'1arrowRight.gif', 'first'=>'2arrowLeft.gif', 'last'=>'2arrowRight.gif');
our %ICONSSYSTEM   = ('pidKill'=>'pidKill.gif', 'pidRemove'=>'pidRemove.gif', 'daemonReload'=>'daemonReload.gif', 'daemonStart'=>'daemonStart.gif', 'daemonStop'=>'daemonStop.gif', 'daemonRestart'=>'daemonRestart.gif');

if ( exists $_config{ICONS} ) {
  $ICONS{OK}            = $_config{ICONS}{OK}          if ( exists $_config{ICONS}{OK} );
  $ICONS{WARNING}       = $_config{ICONS}{WARNING}     if ( exists $_config{ICONS}{WARNING} );
  $ICONS{CRITICAL}      = $_config{ICONS}{CRITICAL}    if ( exists $_config{ICONS}{CRITICAL} );
  $ICONS{UNKNOWN}       = $_config{ICONS}{UNKNOWN}     if ( exists $_config{ICONS}{UNKNOWN} );
  $ICONS{DEPENDENT}     = $_config{ICONS}{DEPENDENT}   if ( exists $_config{ICONS}{DEPENDENT} );
  $ICONS{OFFLINE}       = $_config{ICONS}{OFFLINE}     if ( exists $_config{ICONS}{OFFLINE} );
  $ICONS{'NO DATA'}     = $_config{ICONS}{NO_DATA}     if ( exists $_config{ICONS}{NO_DATA} );
  $ICONS{'IN PROGRESS'} = $_config{ICONS}{IN_PROGRESS} if ( exists $_config{ICONS}{IN_PROGRESS} );
  $ICONS{'NO TEST'}     = $_config{ICONS}{NO_TEST}     if ( exists $_config{ICONS}{NO_TEST} );
  $ICONS{TRENDLINE}     = $_config{ICONS}{TRENDLINE}   if ( exists $_config{ICONS}{TRENDLINE} );

  if ( exists $_config{ICONS}{ACK} ) {
    $ICONSACK{OK}            = $_config{ICONS}{ACK}{OK}          if ( exists $_config{ICONS}{ACK}{OK} );
    $ICONSACK{WARNING}       = $_config{ICONS}{ACK}{WARNING}     if ( exists $_config{ICONS}{ACK}{WARNING} );
    $ICONSACK{CRITICAL}      = $_config{ICONS}{ACK}{CRITICAL}    if ( exists $_config{ICONS}{ACK}{CRITICAL} );
    $ICONSACK{UNKNOWN}       = $_config{ICONS}{ACK}{UNKNOWN}     if ( exists $_config{ICONS}{ACK}{UNKNOWN} );
    $ICONSACK{DEPENDENT}     = $_config{ICONS}{ACK}{DEPENDENT}   if ( exists $_config{ICONS}{ACK}{DEPENDENT} );
    $ICONSACK{OFFLINE}       = $_config{ICONS}{ACK}{OFFLINE}     if ( exists $_config{ICONS}{ACK}{OFFLINE} );
    $ICONSACK{'NO DATA'}     = $_config{ICONS}{ACK}{NO_DATA}     if ( exists $_config{ICONS}{ACK}{NO_DATA} );
    $ICONSACK{'IN PROGRESS'} = $_config{ICONS}{ACK}{IN_PROGRESS} if ( exists $_config{ICONS}{ACK}{IN_PROGRESS} );
    $ICONSACK{'NO TEST'}     = $_config{ICONS}{ACK}{NO_TEST}     if ( exists $_config{ICONS}{ACK}{NO_TEST} );
    $ICONSACK{TRENDLINE}     = $_config{ICONS}{ACK}{TRENDLINE}   if ( exists $_config{ICONS}{ACK}{TRENDLINE} );
  }

  if ( exists $_config{ICONS}{UNSTABLE} ) {
    $ICONSUNSTABLE{OK}            = $_config{ICONS}{UNSTABLE}{OK}          if ( exists $_config{ICONS}{UNSTABLE}{OK} );
    $ICONSUNSTABLE{WARNING}       = $_config{ICONS}{UNSTABLE}{WARNING}     if ( exists $_config{ICONS}{UNSTABLE}{WARNING} );
    $ICONSUNSTABLE{CRITICAL}      = $_config{ICONS}{UNSTABLE}{CRITICAL}    if ( exists $_config{ICONS}{UNSTABLE}{CRITICAL} );
    $ICONSUNSTABLE{UNKNOWN}       = $_config{ICONS}{UNSTABLE}{UNKNOWN}     if ( exists $_config{ICONS}{UNSTABLE}{UNKNOWN} );
    $ICONSUNSTABLE{DEPENDENT}     = $_config{ICONS}{UNSTABLE}{DEPENDENT}   if ( exists $_config{ICONS}{UNSTABLE}{DEPENDENT} );
    $ICONSUNSTABLE{OFFLINE}       = $_config{ICONS}{UNSTABLE}{OFFLINE}     if ( exists $_config{ICONS}{UNSTABLE}{OFFLINE} );
    $ICONSUNSTABLE{'NO DATA'}     = $_config{ICONS}{UNSTABLE}{NO_DATA}     if ( exists $_config{ICONS}{UNSTABLE}{NO_DATA} );
    $ICONSUNSTABLE{'IN PROGRESS'} = $_config{ICONS}{UNSTABLE}{IN_PROGRESS} if ( exists $_config{ICONS}{UNSTABLE}{IN_PROGRESS} );
    $ICONSUNSTABLE{'NO TEST'}     = $_config{ICONS}{UNSTABLE}{NO_TEST}     if ( exists $_config{ICONS}{UNSTABLE}{NO_TEST} );
    $ICONSUNSTABLE{TRENDLINE}     = $_config{ICONS}{UNSTABLE}{TRENDLINE}   if ( exists $_config{ICONS}{UNSTABLE}{TRENDLINE} );
  }

  if ( exists $_config{ICONS}{RECORD} ) {
    $ICONSRECORD{maintenance} = $_config{ICONS}{RECORD}{maintenance} if ( exists $_config{ICONS}{RECORD}{maintenance} );
    $ICONSRECORD{duplicate}   = $_config{ICONS}{RECORD}{duplicate}   if ( exists $_config{ICONS}{RECORD}{duplicate} );
    $ICONSRECORD{delete}      = $_config{ICONS}{RECORD}{delete}      if ( exists $_config{ICONS}{RECORD}{delete} );
    $ICONSRECORD{details}     = $_config{ICONS}{RECORD}{details}     if ( exists $_config{ICONS}{RECORD}{details} );
    $ICONSRECORD{query}       = $_config{ICONS}{RECORD}{query}       if ( exists $_config{ICONS}{RECORD}{query} );
    $ICONSRECORD{edit}        = $_config{ICONS}{RECORD}{edit}        if ( exists $_config{ICONS}{RECORD}{edit} );
    $ICONSRECORD{table}       = $_config{ICONS}{RECORD}{table}       if ( exists $_config{ICONS}{RECORD}{table} );
    $ICONSRECORD{up}          = $_config{ICONS}{RECORD}{up}          if ( exists $_config{ICONS}{RECORD}{up} );
    $ICONSRECORD{down}        = $_config{ICONS}{RECORD}{down}        if ( exists $_config{ICONS}{RECORD}{down} );
    $ICONSRECORD{left}        = $_config{ICONS}{RECORD}{left}        if ( exists $_config{ICONS}{RECORD}{left} );
    $ICONSRECORD{right}       = $_config{ICONS}{RECORD}{right}       if ( exists $_config{ICONS}{RECORD}{right} );
    $ICONSRECORD{first}       = $_config{ICONS}{RECORD}{first}       if ( exists $_config{ICONS}{RECORD}{first} );
    $ICONSRECORD{last}        = $_config{ICONS}{RECORD}{last}        if ( exists $_config{ICONS}{RECORD}{last} );
  }

  if ( exists $_config{ICONS}{SYSTEM} ) {
    $ICONSSYSTEM{pidKill}       = $_config{ICONS}{SYSTEM}{pidKill}       if ( exists $_config{ICONS}{SYSTEM}{pidKill} );
    $ICONSSYSTEM{pidRemove}     = $_config{ICONS}{SYSTEM}{pidRemove}     if ( exists $_config{ICONS}{SYSTEM}{pidRemove} );
    $ICONSSYSTEM{daemonReload}  = $_config{ICONS}{SYSTEM}{daemonReload}  if ( exists $_config{ICONS}{SYSTEM}{daemonReload} );
    $ICONSSYSTEM{daemonStart}   = $_config{ICONS}{SYSTEM}{daemonStart}   if ( exists $_config{ICONS}{SYSTEM}{daemonStart} );
    $ICONSSYSTEM{daemonStop}    = $_config{ICONS}{SYSTEM}{daemonStop}    if ( exists $_config{ICONS}{SYSTEM}{daemonStop} );
    $ICONSSYSTEM{daemonRestart} = $_config{ICONS}{SYSTEM}{daemonRestart} if ( exists $_config{ICONS}{SYSTEM}{daemonRestart} );
  }
}

our %SOUND = ('0'=>'attention.wav','1'=>'warning.wav','2'=>'critical.wav','3'=>'unknown.wav','4'=>'attention.wav','5'=>'attention.wav','6'=>'attention.wav','7'=>'nodata.wav','8'=>'attention.wav','9'=>'warning.wav');

if ( exists $_config{SOUND} ) {
  $SOUND{0} = $_config{SOUND}{0} if ( exists $_config{SOUND}{0} );
  $SOUND{1} = $_config{SOUND}{1} if ( exists $_config{SOUND}{1} );
  $SOUND{2} = $_config{SOUND}{2} if ( exists $_config{SOUND}{2} );
  $SOUND{3} = $_config{SOUND}{3} if ( exists $_config{SOUND}{3} );
  $SOUND{4} = $_config{SOUND}{4} if ( exists $_config{SOUND}{4} );
  $SOUND{5} = $_config{SOUND}{5} if ( exists $_config{SOUND}{5} );
  $SOUND{6} = $_config{SOUND}{6} if ( exists $_config{SOUND}{6} );
  $SOUND{7} = $_config{SOUND}{7} if ( exists $_config{SOUND}{7} );
  $SOUND{8} = $_config{SOUND}{8} if ( exists $_config{SOUND}{8} );
  $SOUND{9} = $_config{SOUND}{9} if ( exists $_config{SOUND}{9} );
}

undef %_config;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub read_table {
  my ($prgtext, $filename, $email, $tDebug) = @_;

  my @table = ();
  my $rvOpen = open(CT, "$APPLICATIONPATH/etc/$filename");

  if ( $rvOpen ) {
    while (<CT>) {
      chomp;

      unless ( /^#/ ) {
        my $dummy = $_;
        $dummy =~ s/\ {1,}//g;
        if ($dummy ne '') { push (@table, $_); }
      }
    }

    close(CT);

	if ( $email ) {
      my $debug = $tDebug;
      $debug = 0 if ($tDebug eq 'F');
      $debug = 1 if ($tDebug eq 'T');
      $debug = 2 if ($tDebug eq 'L');
      $debug = 3 if ($tDebug eq 'M');
      $debug = 4 if ($tDebug eq 'A');
      $debug = 5 if ($tDebug eq 'S');

      use Sys::Hostname;
      my $action = ($email == 2 ? 'reloaded' : 'started');
      my $subject = "$prgtext\@". hostname() .": Config $APPLICATIONPATH/etc/$filename successfully $action at ". get_datetimeSignal();
      my $message = $subject ."\n";
      my $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $message, $debug );
      print "Problem sending email to the '$APPLICATION' server administrators\n" unless ( $returnCode );
    }
  } else {
    print "Cannot open $APPLICATIONPATH/etc/$filename!\n";
    exit $ERRORS{UNKNOWN};
  }

  return @table;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_session_param {
  my ($sessionID, $cgipath, $filename, $debug) =  @_;

  my ($Tdebug, $cgisession);

  if ($debug eq 'F') {
    $Tdebug = 0;
  } elsif ($debug eq 'T') {
    $Tdebug = 1;
  } elsif ($debug eq 'L') {
    $Tdebug = 2;
  } elsif ($debug eq 'M') {
    $Tdebug = 3;
  } elsif ($debug eq 'A') {
    $Tdebug = 4;
  } elsif ($debug eq 'S') {
    $Tdebug = 5;
  } else {
    $Tdebug = $debug;
  }

  my $cgipathFilename = ($cgipath eq '') ? "$filename" : "$cgipath/$filename";

  if ( -e "$cgipathFilename" ) {
    my $rvOpen = open(CGISESSION, "$cgipathFilename");

    if ($rvOpen) {
      while (<CGISESSION>) {
        chomp;
        $cgisession .= $_;
      }

      close(CGISESSION);
    } else {
      print "\nCannot open cgisess '$cgipathFilename'!\n" if ($Tdebug);
      return (0, ());
    }
  } else {
    print "\ncgisess '$cgipathFilename' doesn't exist!\n" if ($Tdebug);
    return (0, ());
  }

  unless ( defined $cgisession ) {
    print "\nEmpty cgisess file '$cgipathFilename'!\n" if ($Tdebug);
    return (0, ());
  }

  print "$cgisession\n\n" if ($Tdebug == 2);

  (undef, $cgisession) = map { split (/^\$D = {/) } split (/};;\$D$/, $cgisession);
  $cgisession =~ s/["']//g;

  my %session = map { my ($key, $value) = split (/ => /) } split (/,/, $cgisession);

  if ($Tdebug == 2) {
    print "Session param\n";
    print "_SESSION_ID          : ", $session{_SESSION_ID}, "\n" if (defined $session{_SESSION_ID});
    print "_SESSION_REMOTE_ADDR : ", $session{_SESSION_REMOTE_ADDR}, "\n" if (defined $session{_SESSION_REMOTE_ADDR});
    print "_SESSION_CTIME       : ", $session{_SESSION_CTIME}, "\n" if (defined $session{_SESSION_CTIME});
    print "_SESSION_ATIME       : ", $session{_SESSION_ATIME}, "\n" if (defined $session{_SESSION_ATIME});
    print "_SESSION_ETIME       : ", $session{_SESSION_ETIME}, "\n" if (defined $session{_SESSION_ETIME});
    print "_SESSION_EXPIRE_LIST : ", $session{_SESSION_EXPIRE_LIST}, "\n" if (defined $session{_SESSION_EXPIRE_LIST});
    print "ASNMTAP              : ", $session{ASNMTAP}, "\n" if (defined $session{ASNMTAP});
    print "~login-trials        : ", $session{'~login-trials'}, "\n" if (defined $session{'~login-trials'});
    print "~logged-in           : ", $session{'~logged-in'}, "\n" if (defined $session{'~logged-in'});
    print "remoteUser           : ", $session{remoteUser}, "\n" if (defined $session{remoteUser});
    print "remoteAddr           : ", $session{remoteAddr}, "\n" if (defined $session{remoteAddr});
    print "remoteNetmask        : ", $session{remoteNetmask}, "\n" if (defined $session{remoteNetmask});
    print "givenName            : ", $session{givenName}, "\n" if (defined $session{givenName});
    print "familyName           : ", $session{familyName}, "\n" if (defined $session{familyName});
    print "email                : ", $session{email}, "\n" if (defined $session{email});
    print "keyLanguage          : ", $session{keyLanguage}, "\n" if (defined $session{keyLanguage});
    print "password             : ", $session{password}, "\n" if (defined $session{password});
    print "userType             : ", $session{userType}, "\n" if (defined $session{userType});
    print "pagedir              : ", $session{pagedir}, "\n" if (defined $session{pagedir});
    print "activated            : ", $session{activated}, "\n" if (defined $session{activated});
    print "iconAdd              : ", $session{iconAdd}, "\n" if (defined $session{iconAdd});
    print "iconDetails          : ", $session{iconDetails}, "\n" if (defined $session{iconDetails});
    print "iconEdit             : ", $session{iconEdit}, "\n" if (defined $session{iconEdit});
    print "iconDelete           : ", $session{iconDelete}, "\n" if (defined $session{iconDelete});
    print "iconQuery            : ", $session{iconQuery}, "\n" if (defined $session{iconQuery});
    print "iconTable            : ", $session{iconTable}, "\n" if (defined $session{iconTable});
  }

  if (defined $session{_SESSION_ID} and $session{_SESSION_ID} eq $sessionID) {
    print "\n-> cgisess '$cgipathFilename' correct sessionID: $sessionID!\n" if ($Tdebug);
    return (1, %session);
  } else {
    print "\n-> cgisess '$cgipathFilename' wrong sessionID: $sessionID!\n" if ($Tdebug);
    return (0, ());
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_trendline_from_test {
  my ($test) = @_;

  my ($pos, $posFrom);
  my $trendline = 0;

  if (($pos = index $test, " -t ") ne -1) {
    $posFrom = $pos + 4;
  } elsif (($pos = index $test, " --trendline=") ne -1) {
    $posFrom = $pos + 13;
  }

  if (defined $posFrom) {
    $trendline = substr($test, $posFrom);
    $trendline =~ s/(\d+)[ |\n][\D|\d]*/$1/g;
  }

  return $trendline;
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub _in_cyclus {
  my ($what, $cyclus, $min, $max) = @_;

  my @a = split(/,/, $cyclus);
  my @b = ();
  my ($x, $i);

  map {
    if (/^\*\/(\d+)$/) {                                          # */n
      if ($1) {
        for $i ($min..$max) { push (@b, $i) if ((($i-$min) % $1) == 0); };
      }
    } elsif (/^\*$/) {                                            # *
      push (@b, $min..$max);
    } elsif (/^(\d+)-(\d+)\/(\d+)$/) {					          # x-y/n
      if ($3) {
        for $i ($1..$2) { push (@b, $i) if ((($i-$1) % $3) == 0); };
      }
    } elsif (/^(\d+)-(\d+)$/) {                                   # x-y
      push (@b, $1..$2);
    } else {                                                      # x
      push (@b, $_);
    }
  } @a;

  for $x (@b) { return (1) if ($what eq $x); }
  return (0);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub set_doIt_and_doOffline {
  my ($min, $hour, $mday, $mon, $wday, $tmin, $thour, $tmday, $tmon, $twday) = @_;

  my ($doIt, $doOffline);

  # do it -- this month?
  $doIt = (($tmon eq "*") || ($mon eq $tmon) || _in_cyclus($mon, $tmon, 1, 12)) ? 1 : 0;

  # do it -- this day of the month?
  $doIt = ($doIt && (($tmday eq "*") || ($mday eq $tmday) || _in_cyclus($mday, $tmday, 1, 31))) ? 1 : 0;

  # do it -- this day of the week?
  $doIt = ($doIt && (($twday eq "*") || ($wday eq $twday) || _in_cyclus($wday, $twday, 0, 6))) ? 1 : 0;

  # do it -- this hour?
  $doIt = ($doIt && (($thour eq "*") || ($hour eq $thour)|| _in_cyclus($hour, $thour, 0, 23))) ? 1 : 0;

  # do it -- this minute?
  $doIt = ($doIt && (($tmin eq "*") || ($min eq $tmin) || _in_cyclus($min, $tmin, 0, 59))) ? 1 : 0;

  # do Offline?
  $doOffline = (!$doIt && (($min eq $tmin) || _in_cyclus($min, $tmin, 0, 59))) ? 1 : 0;

  return ($doIt, $doOffline);
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub create_header {
  my $filename = shift;

  unless ( -e "$filename" ) {                        # create HEADER.html
    my $rvOpen = open(HEADER, ">$filename");

    if ($rvOpen) {
      print_header (*HEADER, "index", "index-cv", $APPLICATION, "Debug", 3600, '', 'F', '', undef, "asnmtap-results.css");
      print HEADER '<br>', "\n", '<table WIDTH="100%" border=0><tr><td class="DataDirectory">', "\n";
      close(HEADER);
    } else {
      print "Cannot open $filename to create reports page\n";
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub create_footer {
  my $filename = shift;

  unless ( -e "$filename" ) {                        # create FOOTER.html
    my $rvOpen = open(FOOTER, ">$filename");

    if ($rvOpen) {
      print FOOTER '</td></tr></table>', "\n", '<BR>', "\n";
      print_legend (*FOOTER);
      print FOOTER '</BODY>', "\n", '</HTML>', "\n";
      close(FOOTER);
    } else {
      print "Cannot open $filename to create reports page\n";
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub encode_html_entities {
  my ($type, $string) = @_;

  sub convert_octalLatin1_to_decimalHtmlEntity {
    my $octalLatin1 = shift;
    return ("&#" .oct($octalLatin1). ";");
  }

  sub convert_charLatin1_to_decimalHtmlEntity {
    my $charLatin1 = shift;
    return ("&#" .ord($charLatin1). ";");
  }

  # Entities:  & | é @ " # ' ( § ^ è ! ç { à } ) ° - _ ^ ¨ $ * ù % ´ µ £ ` , ? ; . : / = + ~ < > \ ² ³ €
  use HTML::Entities;

  my $htmlEntityString;

  if ($type eq 'A') {      # convert All entities
    $htmlEntityString = encode_entities($string);
  } elsif ($type eq 'C') { # Comment data
    $htmlEntityString = encode_entities($string, ' &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:=\+~²³€');
  } elsif ($type eq 'D') { # Debug data
    $htmlEntityString = encode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'E') { # Error status message
    $htmlEntityString = encode_entities($string, '&|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'K') { # primary Key
    $htmlEntityString = encode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'M') { # status Message
    $htmlEntityString = encode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'S') { # Status
    $htmlEntityString = encode_entities($string, '<>');
  } elsif ($type eq 'T') { # Title
    $htmlEntityString = encode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'U') { # Url
    $htmlEntityString = encode_entities($string, '& ');
  } elsif ($type eq 'V') { # session Variable
    $htmlEntityString = encode_entities($string);
    $htmlEntityString =~ s/\\([2][4-7][0-7]|[3][0-7][0-7])/convert_octalLatin1_to_decimalHtmlEntity($1)/eg;
    $htmlEntityString =~ s/([\240-\377])/convert_charLatin1_to_decimalHtmlEntity($1)/eg;
  } else {
    $htmlEntityString = $string;
  }

  return ($htmlEntityString);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub decode_html_entities {
  my ($type, $string) = @_;

  # Entities:  & | é @ " # ' ( § ^ è ! ç { à } ) ° - _ ^ ¨ $ * ù % ´ µ £ ` , ? ; . : / = + ~ < > \ ² ³ €
  use HTML::Entities;

  my $htmlEntityString;

  if ($type eq 'A') {      # convert All entities
    $htmlEntityString = decode_entities($string);
  } elsif ($type eq 'C') { # Comment data
    $htmlEntityString = decode_entities($string, ' &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:=\+~²³€');
  } elsif ($type eq 'D') { # Debug data
    $htmlEntityString = decode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'E') { # Error status message
    $htmlEntityString = decode_entities($string, '&|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'K') { # primary Key
    $htmlEntityString = decode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'M') { # status Message
    $htmlEntityString = decode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'S') { # Status
    $htmlEntityString = decode_entities($string, '<>');
  } elsif ($type eq 'T') { # Title
    $htmlEntityString = decode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'U') { # Url
    $htmlEntityString = decode_entities($string, '& ');
  } elsif ($type eq 'V') { # session Variable
    $htmlEntityString = decode_entities($string);
  } else {
    $htmlEntityString = $string;
  }

  return ($htmlEntityString);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_header {
  my ($HTML, $pagedir, $pageset, $htmlTitle, $subTitle, $refresh, $onload, $openPngImage, $headScript, $sessionID, $stylesheet) = @_;

  my ($pageDir, $environment) = split (/\//, $pagedir, 2);
  $environment = 'P' unless (defined $environment);

  my $sessionIdOrCookie = ( defined $sessionID ) ? "&amp;CGISESSID=$sessionID" : "&amp;CGICOOKIE=1";
  my $reloadOrToggle    = ( $subTitle =~ /^(?:Full View|Condenced View|Minimal Condenced View)$/ ) ? "<A HREF=\"#\" onClick=\"togglePageDirCookie('pagedir_id_${pageDir}_${environment}', '$HTTPSURL/nav/$pagedir')\">" : "<A HREF=\"#\" onClick=\"reloadPageDirCookie('pagedir_id_${pageDir}_${environment}', '$HTTPSURL/nav/$pagedir')\">";
  my $selectEnvironment = (( $pagedir ne '<NIHIL>' and $pageset ne '<NIHIL>' ) ? '<form action="" name="environment"><select name="environment" size="1" onChange="loadEnvironmentPageDirCookie(\'' .$pageDir. '\', this.options[this.selectedIndex].value);"><option value="P"'. ($environment eq 'P' ? ' selected' : '') .'>Production</option><option value="A"'. ($environment eq 'A' ? ' selected' : '') .'>Acceptation</option><option value="S"'. ($environment eq 'S' ? ' selected' : '') .'>Simulation</option><option value="T"'. ($environment eq 'T' ? ' selected' : '') .'>Test</option></select></form>' : '');

  my $showToggle   = ($pagedir ne '<NIHIL>') ? $reloadOrToggle : "<A HREF=\"$HTTPSURL/cgi-bin/$pageset/index.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F$sessionIdOrCookie\">";
  $showToggle     .= "<IMG SRC=\"$IMAGESURL/toggle.gif\" title=\"Toggle\" alt=\"Toggle\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>";
  my $showReport   = ($pagedir ne '<NIHIL>') ? "<A HREF=\"$HTTPSURL/nav/$pagedir/reports-$pageset.html\"><IMG SRC=\"$IMAGESURL/report.gif\" title=\"Report\" alt=\"Report\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>" : '';
  my $showOnDemand = ($pagedir ne '<NIHIL>') ? "<A HREF=\"$HTTPSURL/cgi-bin/runCmdOnDemand.pl?pagedir=$pagedir&amp;pageset=$pageset$sessionIdOrCookie\"><IMG SRC=\"$IMAGESURL/ondemand.gif\" title=\"On demand\" alt=\"On demand\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>" : '';
  my $showData     = ($pagedir ne '<NIHIL>') ? "<A HREF=\"$HTTPSURL/cgi-bin/getArchivedReport.pl?pagedir=$pagedir&amp;pageset=$pageset$sessionIdOrCookie\"><IMG SRC=\"$IMAGESURL/data.gif\" title=\"Report Archive\" alt=\"Report Archive\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>" : '';
  my $showAwstats  = ($AWSTATSENABLED) ? "<A HREF=\"/awstats/awstats.pl\" target=\"_blank\"><IMG SRC=\"$IMAGESURL/awstats.gif\" title=\"Awstats\" alt=\"Awstats\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>" : '';
  my $showInfo     = "<A HREF=\"$HTTPSURL/cgi-bin/info.pl?pagedir=$pagedir&amp;pageset=$pageset$sessionIdOrCookie\"><IMG SRC=\"$IMAGESURL/info.gif\" title=\"Info\" alt=\"Info\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>";

  $stylesheet = "asnmtap.css" unless ( defined $stylesheet );

  my $metaRefresh = ( $onload =~ /^\QONLOAD="startRefresh();\E/ ) ? "" : "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"$refresh\">";
  my ($showRefresh, $showSound, $showJSFX) = ('', '', '');
  my (undef, $cMonth, $cDay) = Today();

  if ( ( $pagedir =~ /^(?:index|test)$/ ) and ( ( $cMonth == 01 and $cDay == 01 ) || ( $cMonth == 02 and $cDay == 14 ) || ( $cMonth == 12 and $cDay > 21 and $cDay < 29 ) || ( $cMonth == 12 and $cDay == 31 ) ) ) {
    $showJSFX .= "<script language=\"JavaScript\" SRC=\"$HTTPSURL/JSFX_Layer.js\"></script>\n<script language=\"JavaScript\" SRC=\"$HTTPSURL/JSFX_Browser.js\"></script>\n<script language=\"JavaScript\" SRC=\"$HTTPSURL/";

    if ( $cMonth == 01 and $cDay == 01 ) {
      $showJSFX .= 'JSFX_Fireworks2.js';
    } elsif ( ( $cMonth == 02 and $cDay == 14 ) || ( $cMonth == 10 and $cDay == 31 ) ) {
      $showJSFX .= 'JSFX_Halloween.js';
    } elsif ( $cMonth == 12 and $cDay == 31 ) {
      $showJSFX .= 'JSFX_Fireworks.js';
    } else {
      $showJSFX .= 'JSFX_Falling.js';
    }

    $showJSFX .= "\"></script>\n<script language=\"JavaScript\">\n  function JSFX_StartEffects() {\n";

    if ( $cMonth == 01 and $cDay == 01 ) {
      $showJSFX .= "    JSFX.FireworkDisplay2(1);\n";
    } elsif ( $cMonth == 02 and $cDay == 14 ) {
      $showJSFX .= "    JSFX.AddGhost(\"$IMAGESURL/cupido.gif\");\n";
    } elsif ( $cMonth == 04 and  $cDay == 18 ) {
      $showJSFX .= "    JSFX.Falling(1, \"E=mc²\", 60);\n";
    } elsif ( $cMonth == 10 and $cDay == 31 ) {
      $showJSFX .= "    JSFX.AddGhost(\"$IMAGESURL/ghost.gif\");\n";
    } elsif ( $cMonth == 12 ) {
      if ( $cDay > 21 and $cDay < 29 ) {
        $showJSFX .= "    JSFX.Falling(1, \"<IMG SRC='$IMAGESURL/snowflake-1.gif'>\", 20);\n    JSFX.Falling(1, \"<IMG SRC='$IMAGESURL/snowflake-2.gif'>\", 40);\n    JSFX.Falling(1, \"<IMG SRC='$IMAGESURL/snowflake-3.gif'>\", 60);\n    JSFX.Falling(1, \"<IMG SRC='$IMAGESURL/snowflake-4.gif'>\", 80);\n";
      } elsif ( $cDay == 31 ) {
        $showJSFX .= "    JSFX.FireworkDisplay(1);\n";
      }
    } else {
      $showJSFX .= "    JSFX.Falling(1, \"Happy Birthday\", 60);\n";
    }

    $showJSFX .= "  }\n\n  JSFX_StartEffects()\n</script>\n";
  }

  print $HTML <<EndOfHtml;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>${ENVIRONMENT{$environment}}: $APPLICATION @ $BUSINESS</title>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
  <META HTTP-EQUIV="Expires" CONTENT="Wed, 10 Dec 2003 00:00:01 GMT">
  <META HTTP-EQUIV="Pragma" CONTENT="no-cache">
  <META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
  $metaRefresh
  <link rel="stylesheet" type="text/css" href="$HTTPSURL/$stylesheet">
  $headScript
  <script language="JavaScript1.2" type="text/javascript">
    var pagedir_prefix = new Array();
    pagedir_prefix[0] = "";
    pagedir_prefix[1] = "-cv";
    pagedir_prefix[2] = "-mcv";

    function getPageDirCookie( name ) {
      var prefix = name + '=';
      var ca = document.cookie.split( ';' );

      for( var i=0; i < ca.length; i++ ) {
        var c = ca[i];
        while ( c.charAt( 0 ) == ' ' ) c = c.substring( 1, c.length );
        if ( c.indexOf( prefix ) == 0 ) return unescape( c.substring( prefix.length, c.length ) );
      }

      return null;
    }

    function deletePageDirCookie( name ) { setPageDirCookie( name, '', '', -1 ); }

    function setPageDirCookie( name, url, value, days ) {
      var expires = '';

      if ( days ) {
        (time = new Date()).setTime( new Date().getTime() + days * 24 * 60 * 60 * 1000);
        expires = "; expires=" + time.toGMTString();
      }

	  document.cookie = name + "=" + escape(value) + expires + "; path=/";
    }

    function loadEnvironmentPageDirCookie ( pageDir, environment ) {
      var name = 'pagedir_id_' + pageDir + '_' + environment;
      var url  = '$HTTPSURL/nav/' + pageDir + '/';
      if (environment != 'P') { url += environment + '/'; }
      reloadPageDirCookie( name, url );
    }

    function reloadPageDirCookie( name, url ) {
      var pagedir_id = getPageDirCookie( name );

      if (pagedir_id == null || pagedir_id == "" || pagedir_id < 0 || pagedir_id > 2) {
        pagedir_id = 0;
        setPageDirCookie ( name, url, pagedir_id, 365 );
      }

      window.location = url + "/index" + pagedir_prefix[pagedir_id] + ".html";
    }

    function togglePageDirCookie( name, url ) {
      var pagedir_id = getPageDirCookie( name );

      if (pagedir_id != null && pagedir_id != "" && pagedir_id > 0 && pagedir_id <= 2) {
        if (pagedir_id < 2) {
          pagedir_id++;
        } else {
          pagedir_id = 0;
        }
      } else {
        pagedir_id = 1;
      }

      setPageDirCookie ( name, url, pagedir_id, 365 );
      window.location = url + "/index" + pagedir_prefix[pagedir_id] + ".html";
    }

    function setSoundCookie( name, value, days ) {
      var expires = '';

      if ( days ) {
        (time = new Date()).setTime( new Date().getTime() + days * 24 * 60 * 60 * 1000);
        expires = "; expires=" + time.toGMTString();
      }

	  document.cookie = name + "=" + escape(value) + expires + "; path=$HTTPSURL/nav/";
    }

    function getSoundCookie( name ) {
      var prefix = name + '=';
      var ca = document.cookie.split( ';' );

      for( var i=0; i < ca.length; i++ ) {
        var c = ca[i];
        while ( c.charAt( 0 ) == ' ' ) c = c.substring( 1, c.length );
        if ( c.indexOf( prefix ) == 0 ) return unescape( c.substring( prefix.length, c.length ) );
      }

      return null;
    }

    function deleteSoundCookie( name ) { setSoundCookie( name, '', -1 ); }

    function dynamicContentNS4NS6FF (elementID, content, booleanBlur) {
      if (document.all)
        document.getElementById(elementID).innerHTML=content
      else if (document.getElementById) {
        var range = document.createRange ();
        var element = document.getElementById (elementID);
        range.setStartBefore (element);
        var htmlFragment = range.createContextualFragment (content);
        while ( element.hasChildNodes() ) element.removeChild (element.lastChild);
        element.appendChild (htmlFragment);
        if (booleanBlur) blur ();
      }
    }

    function initSound( ) {
      var soundState = getSoundCookie( 'soundState' );

      if (document.all) {
        if ( soundState == null || soundState == 'on' ) { startSound( ); } else { stopSound( ); }
      } else {
        if ( soundState == null || soundState == 'off' ) { stopSound( ); } else { startSound( ); }
      }
    }

    function startSound( ) {
      setSoundCookie ( 'soundState', 'on', 1 );
      document.getElementById('soundID').innerHTML='<A HREF=\"javascript:stopSound();\" title=\"Stop Sound\" alt=\"Stop Sound\"><img src=\"$IMAGESURL/on.gif\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0><\\/A>'
    }

    function stopSound( ) {
      setSoundCookie ( 'soundState', 'off', 1 );
      document.getElementById('soundID').innerHTML='<A HREF=\"javascript:startSound();\" title=\"Start Sound\" alt=\"Start Sound\"><img src=\"$IMAGESURL/off.gif\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0<\\/A>'
    }

    function LegendSound( sound ) {
      var soundState = getSoundCookie( 'soundState' );
EndOfHtml

  if ($subTitle !~ /^Reports\&nbsp\;\&nbsp\;/) {
    $showSound = "<span id=\"soundID\" class=\"LegendLastUpdate\"></span>";

    print $HTML <<EndOfHtml;

      if ( soundState != null && soundState == 'on' ) {
        playSound = '<embed src="$HTTPSURL/sound/' + sound + '" width="" height="" alt="" hidden="true" autostart="true" loop="false"><\\/embed>';
        dynamicContentNS4NS6FF ('LegendSound', playSound, 1);
      } else {
        dynamicContentNS4NS6FF ('LegendSound', '&nbsp;', 1);
      }
EndOfHtml
  }

  print $HTML "    }\n";

  if ( $onload =~ /^\QONLOAD="startRefresh();\E/ ) {
    $showRefresh = "<span id=\"refreshID\" class=\"LegendLastUpdate\"></span>";

    my $startRefresh = $refresh * 1000;

    print $HTML <<EndOfHtml;
    function startRefresh() {
      var pagedir_id = getPageDirCookie( 'pagedir_id_${pageDir}_${environment}' );

      if (pagedir_id == null || pagedir_id == "" || pagedir_id < 0 || pagedir_id > 2) {
        pagedir_id = 0;
        setPageDirCookie ( 'pagedir_id_${pageDir}_${environment}', '$HTTPSURL/nav/$pagedir', pagedir_id, 365 );
      }

      timerID = setTimeout("location.href='$HTTPSURL/nav/$pagedir/index" + pagedir_prefix[pagedir_id] + ".html'", $startRefresh);
      document.body.style.backgroundImage = 'url($IMAGESURL/startRefresh.gif)';
      document.getElementById('refreshID').innerHTML='<A HREF=\"javascript:stopRefresh();\" title=\"Stop Refresh\" alt=\"Stop Refresh\"><img src=\"$IMAGESURL/stop.gif\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0><\\/A>'
    }

    function stopRefresh() {
      clearTimeout(timerID);
      document.body.style.backgroundImage = 'url($IMAGESURL/stopRefresh.gif)';
      document.getElementById('refreshID').innerHTML='<A HREF=\"javascript:startRefresh();\" title=\"Start Refresh\" alt=\"Start Refresh\"><img src=\"$IMAGESURL/start.gif\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0<\\/A>'
    }
EndOfHtml
  }

  print $HTML "  </script>\n";

  if ( $openPngImage eq 'T' ) {
    print $HTML <<EndOfHtml;
  <script language="JavaScript1.2" type="text/javascript">
    function chromeless(u,n,W,H,X,Y,tH,tW,wB,wBs,wBG,wBGs,wNS,fSO,brd,bli,max,min,res,tsz){
      var c=(document.all&&navigator.userAgent.indexOf("Win")!=-1)?1:0
      var v=navigator.appVersion.substring(navigator.appVersion.indexOf("MSIE ")+5,navigator.appVersion.indexOf("MSIE ")+8)
      min=(v>=5.5?min:false);
      var w=window.screen.width; var h=window.screen.height
      var W=W||w; W=(typeof(W)=='string'?Math.ceil(parseInt(W)*w/100):W); W+=(brd*2+2)*c
      var H=H||h; H=(typeof(H)=='string'?Math.ceil(parseInt(H)*h/100):H); H+=(tsz+brd+2)*c
      var X=X||Math.ceil((w-W)/2)
      var Y=Y||Math.ceil((h-H)/2)
      var s=",width="+W+",height="+H
      var CWIN=window.open(u,n,wNS+s,true)
      CWIN.moveTo(X,Y)
      CWIN.focus()
      CWIN.setURL=function(u) { if (this && !this.closed) { if (this.frames.main) this.frames.main.location.href=u; else this.location.href=u } }
      CWIN.closeIT=function() { if (this && !this.closed) this.close() }
      return CWIN
    }

    function openPngImage(u,W,H,X,Y,n,b,x,t, m,r) {
      var tH  = '<font face=verdana color=#0000FF size=1>' + t + '<\\/font>';
      var tW  = '&nbsp;' + t;
      var wB  = '#0000FF';
      var wBs = '#0000FF';
      var wBG = '#000066';
      var wBGs= '#000000';
      var wNS = 'toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=1,resizable=0';
      var fSO = 'scrolling=yes noresize';
      var brd = b;
      var bli = 1;
      var max = x||false;
      var res = r||false;
      var min = m||true;
      var tsz = 20;
      return chromeless(u,n,W,H,X,Y,tH,tW,wB,wBs,wBG,wBGs,wNS,fSO,brd,bli,max,min,res,tsz);
    }
  </script>
EndOfHtml
  }

  print $HTML <<EndOfHtml;
</head>
<BODY $onload>
  $showJSFX
  <TABLE WIDTH="100%"><TR>
    <TD ALIGN="LEFT" WIDTH="292">
      $showToggle
      $showReport
      $showOnDemand
      $showData
      $showAwstats
      $showInfo
      $showRefresh
      $showSound
    </TD>
	<td class="HeaderTitel">$htmlTitle</td><td width="180" class="HeaderSubTitel">$subTitle</td><td width="1" valign="middle">$selectEnvironment</td>
  </TR></TABLE>
  <HR>
EndOfHtml

  if ( $pagedir ne '<NIHIL>' and $pageset ne '<NIHIL>' ) {
    my $showToggle   = "<A HREF=\"#\" onClick=\"reloadPageDirCookie('pagedir_id_${pageDir}_${environment}', '$HTTPSURL/nav/$pagedir')\">";
    $showToggle     .= "<IMG SRC=\"$IMAGESURL/toggle.gif\" title=\"Toggle\" alt=\"Toggle\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>";

    my $directory = $HTTPSPATH ."/nav/". $pagedir;
    next unless (-e "$directory");
    my $reportFilename = $directory . '/reports-' . $pageset . '.html';

    unless ( -e "$reportFilename" ) { # create $reportFilename
      my $rvOpen = open(REPORTS, ">$reportFilename");

      if ($rvOpen) {
        print REPORTS <<EndOfHtml;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">  
<html>
<head>
  <title>${ENVIRONMENT{$environment}}: $APPLICATION @ $BUSINESS</title>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
  <META HTTP-EQUIV="Expires" CONTENT="Wed, 10 Dec 2003 00:00:01 GMT">
  <META HTTP-EQUIV="Pragma" CONTENT="no-cache">
  <META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
  <META HTTP-EQUIV="Refresh" CONTENT="$refresh">
  <link rel="stylesheet" type="text/css" href="$HTTPSURL/asnmtap.css">
  <script language="JavaScript1.2" type="text/javascript">
    var pagedir_prefix = new Array();
    pagedir_prefix[0] = "";
    pagedir_prefix[1] = "-cv";
    pagedir_prefix[2] = "-mcv";

    function getPageDirCookie( name ) {
      var prefix = name + '=';
      var ca = document.cookie.split( ';' );

      for( var i=0; i < ca.length; i++ ) {
        var c = ca[i];
        while ( c.charAt( 0 ) == ' ' ) c = c.substring( 1, c.length );
        if ( c.indexOf( prefix ) == 0 ) return unescape( c.substring( prefix.length, c.length ) );
      }

      return null;
    }

    function deletePageDirCookie( name ) { setPageDirCookie( name, '', '', -1 ); }

    function setPageDirCookie( name, url, value, days ) {
      var expires = '';

      if ( days ) {
        (time = new Date()).setTime( new Date().getTime() + days * 24 * 60 * 60 * 1000);
        expires = "; expires=" + time.toGMTString();
      }

	  document.cookie = name + "=" + escape(value) + expires + "; path=/";
    }

    function loadEnvironmentPageDirCookie ( pageDir, environment ) {
      var name = 'pagedir_id_' + pageDir + '_' + environment;
      var url  = '$HTTPSURL/nav/' + pageDir + '/';
      if (environment != 'P') { url += environment + '/'; }
      reloadPageDirCookie( name, url );
    }

    function reloadPageDirCookie( name, url ) {
      var pagedir_id = getPageDirCookie( name );

      if (pagedir_id == null || pagedir_id == "" || pagedir_id < 0 || pagedir_id > 2) {
        pagedir_id = 0;
        setPageDirCookie ( name, url, pagedir_id, 365 );
      }

      window.location = url + "/index" + pagedir_prefix[pagedir_id] + ".html";
    }

    function togglePageDirCookie( name, url ) {
      var pagedir_id = getPageDirCookie( name );

      if (pagedir_id != null && pagedir_id != "" && pagedir_id > 0 && pagedir_id <= 2) {
        if (pagedir_id < 2) {
          pagedir_id++;
        } else {
          pagedir_id = 0;
        }
      } else {
        pagedir_id = 1;
      }

      setPageDirCookie ( name, url, pagedir_id, 365 );
      window.location = url + "/index" + pagedir_prefix[pagedir_id] + ".html";
    }
  </script>
</head>
<BODY $onload>
  <TABLE WIDTH="100%"><TR>
    <TD ALIGN="LEFT" WIDTH="260">
      $showToggle
      $showReport
      $showOnDemand
      $showData
      $showAwstats
      $showInfo
    </TD>
	<td class="HeaderTitel">$htmlTitle</td><td width="180" class="HeaderSubTitel">Reports Menu</td><td width="1" valign="middle">$selectEnvironment</td>
  </TR></TABLE>
  <HR>

  <br>
  <table border="0" cellpadding="0" cellspacing="0" summary="menu" width="100%">
    <tr><td class="ReportItem"><a href="$HTTPSURL/cgi-bin/detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;CGICOOKIE=1&amp;detailed=on">Detailed Statistics &amp; Report Generation</a></td></tr>
    <tr><td>&nbsp;</td></tr>
    <tr><td class="ReportItem"><a href="$HTTPSURL/cgi-bin/detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;CGICOOKIE=1&amp;detailed=off">Compare Response Time Trends</a></td></tr>
    <tr><td>&nbsp;</td></tr>
EndOfHtml

        print REPORTS '    <tr><td>&nbsp;</td></tr>', "\n", '    <tr><td>&nbsp;</td></tr>', "\n", "    <tr><td class=\"ReportItem\"><a href=\"$HTTPSURL/cgi-bin/perfparse.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;CGICOOKIE=1\">PerfParse facilities for the performance data produced by the $APPLICATION</a></td></tr>", "\n" if (-e "${HTTPSPATH}${PERFPARSECGI}");
        print REPORTS '  </table>', "\n", '  <br>', "\n";
        print_legend (*REPORTS);
        print REPORTS '</body>', "\n", '</html>', "\n";

        close(REPORTS);
      } else {
        print "Cannot open $reportFilename to create reports page\n";
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_legend {
  my $HTML = shift;

  print $HTML <<EndOfHtml;
<HR>
<table width="100%">
  <tr>
    <td class="LegendCopyright">&copy; Copyright $COPYRIGHT \@ $BUSINESS</td>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'IN PROGRESS'}"><IMG SRC="$IMAGESURL/$ICONS{'IN PROGRESS'}" ALT="IN PROGRESS" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> in progress</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{OK}"><IMG SRC="$IMAGESURL/$ICONS{OK}" ALT="OK" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> ok</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{TRENDLINE}"><IMG SRC="$IMAGESURL/$ICONS{TRENDLINE}" ALT="TRENDLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{TRENDLINE}}');"> trendline</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{WARNING}"><IMG SRC="$IMAGESURL/$ICONS{WARNING}" ALT="WARNING" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{WARNING}}');"> warning</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{CRITICAL}"><IMG SRC="$IMAGESURL/$ICONS{CRITICAL}" ALT="CRITICAL" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{CRITICAL}}');"> critical</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{UNKNOWN}"><IMG SRC="$IMAGESURL/$ICONS{UNKNOWN}" ALT="UNKNOWN" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{UNKNOWN}}');"> unknown</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO TEST'}"><IMG SRC="$IMAGESURL/$ICONS{'NO TEST'}" ALT="NO TEST" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> no test</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO DATA'}"><IMG SRC="$IMAGESURL/$ICONS{'NO DATA'}" ALT="NO DATA" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'NO DATA'}}');"> no data</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{OFFLINE}"><IMG SRC="$IMAGESURL/$ICONS{OFFLINE}" ALT="OFFLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> offline</FONT></TD>
    <td align="right"><span id="SoundStatus" class="LegendLastUpdate">&nbsp;</span><span id="LegendSound" class="LegendLastUpdate">&nbsp;</span>v$RMVERSION</td>
  </tr><tr>
	<td>&nbsp;</td>
	<td class="LegendIcons">Comments:</td>
    <td class="LegendIcons"><FONT COLOR="$COLORS{OK}"><IMG SRC="$IMAGESURL/$ICONSACK{OK}" ALT="OK" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> ok</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{TRENDLINE}"><IMG SRC="$IMAGESURL/$ICONSACK{TRENDLINE}" ALT="TRENDLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{TRENDLINE}}');"> trendline</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{WARNING}"><IMG SRC="$IMAGESURL/$ICONSACK{WARNING}" ALT="WARNING" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{WARNING}}');"> warning</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{CRITICAL}"><IMG SRC="$IMAGESURL/$ICONSACK{CRITICAL}" ALT="CRITICAL" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{CRITICAL}}');"> critical</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{UNKNOWN}"><IMG SRC="$IMAGESURL/$ICONSACK{UNKNOWN}" ALT="UNKNOWN" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{UNKNOWN}}');"> unknown</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO TEST'}"><IMG SRC="$IMAGESURL/$ICONSACK{'NO TEST'}" ALT="NO TEST" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> no test</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO DATA'}"><IMG SRC="$IMAGESURL/$ICONSACK{'NO DATA'}" ALT="NO DATA" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'NO DATA'}}');"> no data</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{OFFLINE}"><IMG SRC="$IMAGESURL/$ICONSACK{OFFLINE}" ALT="OFFLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> offline</FONT></TD>
    <td>&nbsp;</td>
  </tr><tr>
	<td>&nbsp;</td>
	<td class="LegendIcons">Instability:</td>
    <td class="LegendIcons"><FONT COLOR="$COLORS{OK}"><IMG SRC="$IMAGESURL/$ICONSUNSTABLE{OK}" ALT="OK" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> ok</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{TRENDLINE}"><IMG SRC="$IMAGESURL/$ICONSUNSTABLE{TRENDLINE}" ALT="TRENDLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{TRENDLINE}}');"> trendline</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{WARNING}"><IMG SRC="$IMAGESURL/$ICONSUNSTABLE{WARNING}" ALT="WARNING" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{WARNING}}');"> warning</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{CRITICAL}"><IMG SRC="$IMAGESURL/$ICONSUNSTABLE{CRITICAL}" ALT="CRITICAL" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{CRITICAL}}');"> critical</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{UNKNOWN}"><IMG SRC="$IMAGESURL/$ICONSUNSTABLE{UNKNOWN}" ALT="UNKNOWN" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{UNKNOWN}}');"> unknown</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO TEST'}"><IMG SRC="$IMAGESURL/$ICONSUNSTABLE{'NO TEST'}" ALT="NO TEST" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> no test</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO DATA'}"><IMG SRC="$IMAGESURL/$ICONSUNSTABLE{'NO DATA'}" ALT="NO DATA" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'NO DATA'}}');"> no data</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{OFFLINE}"><IMG SRC="$IMAGESURL/$ICONSUNSTABLE{OFFLINE}" ALT="OFFLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> offline</FONT></TD>
    <td class="LegendLastUpdate">last update:&nbsp;&nbsp;
EndOfHtml

  print $HTML get_datetimeSignal();

  print $HTML <<EndOfHtml;
    </td>
  </tr>
</table>
<HR>
EndOfHtml
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub init_email_report {
  my ($EMAILREPORT, $filename, $debug) = @_;

  my $emailReport = $RESULTSPATH .'/'. $filename;
  my $rvOpen = ( $debug ) ? '1' : open($EMAILREPORT, "> $emailReport");
  select((select($EMAILREPORT), $| = 1)[0]); # autoflush

  unless ( defined $rvOpen ) {
    $emailReport = '~/'. $filename;
    $rvOpen = open($EMAILREPORT, "> $emailReport");
    select((select($EMAILREPORT), $| = 1)[0]); # autoflush
    print "Cannot create '$emailReport' for buffering email report information\n" unless (-e "$emailReport");
  }

  return ($emailReport, $rvOpen);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub send_email_report {
  my ($EMAILREPORT, $emailReport, $rvOpen, $prgtext, $debug) = @_;

  my $returnCode;

  if ( $rvOpen and ! $debug ) {
    close($EMAILREPORT);

    if (-e "$emailReport") {
      my $emailMessage;
      $rvOpen = open($EMAILREPORT, "$emailReport");

      if ($rvOpen) {
        while (<$EMAILREPORT>) { $emailMessage .= $_; }
        close($EMAILREPORT);

        if (defined $emailMessage) {
          use Sys::Hostname;
          my $subject = $prgtext .' / Daily status from '. hostname() .': '. get_csvfiledate();
          $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $emailMessage, $debug );
          print "Problem sending email to the '$APPLICATION' server administrators\n" unless ( $returnCode );
        }
      } else {
        print "Cannot open $emailReport to send email report information\n";
      }
    } else {
      print "$emailReport to send email report information doesn't exist\n";
    }
  }

  return ($returnCode);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub sending_mail {
  my ( $serverListSMTP, $mailTo, $mailFrom, $mailSubject, $mailBody, $debug ) = @_;

  # look at Mail.pm !!!
  use Mail::Sendmail qw(sendmail %mailcfg);
  $mailcfg{port}     = 25;
  $mailcfg{retries}  = 3;
  $mailcfg{delay}    = 1;
  $mailcfg{mime}     = 0;
  $mailcfg{debug}    = ($debug eq 'T') ? 1 : 0;
  $mailcfg{smtp}     = $serverListSMTP;

  use Sys::Hostname;
  my %mail = ( To => $mailTo, From => $mailFrom, Subject => $mailSubject .' from '. hostname(), Message => $mailBody );
  my $returnCode = ( sendmail %mail ) ? 1 : 0;
  print "\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log, "\n" if ($debug eq 'T');
  return ( $returnCode );
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub CSV_prepare_table {
  my ($path, $tableFilename, $extention, $tableName, $columnSequence, $tableDefinition, $logger, $debug) = @_;

  my $rv = 1;
  my $dbh = DBI->connect ("DBI:CSV:", "", "", {f_schema => undef, f_dir => $path, f_ext => $extention} ) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot connect to the database", $logger, $debug);

  if ( $rv ) {
    $dbh->{csv_tables}{$tableName}  = { file => $tableFilename };

    $dbh->{csv_null}                = 1;
    $dbh->{csv_allow_whitespace}    = 0;
    $dbh->{csv_allow_loose_quotes}  = 0;
    $dbh->{csv_allow_loose_escapes} = 0;

    $dbh->{csv_eol}                 = $\;
    $dbh->{csv_sep_char}            = ',';
    $dbh->{csv_quote_char}          = '"';
    $dbh->{csv_escape_char}         = '"';

    if ( -e "$path$tableFilename$extention" ) {
      @{$columnSequence} = ();

      use Text::CSV;
      my $csv = Text::CSV->new( { binary => 1 } );

      if ( open my $rvOpen, "<", "$path$tableFilename$extention" ) {
        if ( my $fields = $csv->getline ($rvOpen) ) {
          @{$columnSequence} = @$fields;
        } else {
          CSV_error_message (*EMAILREPORT, 'Failed to parse line: '. $csv->error_input, $debug);
        }

        close $rvOpen;
      } else {
        CSV_error_message (*EMAILREPORT, "Cannot open $path$tableFilename$extention to print debug information", $debug);
      }
    } else {
      my $create;

      foreach my $columnName ( @{$columnSequence} ) {
        $create .= "  $columnName " .$tableDefinition->{$columnName}. ",\n";
      }

      chomp $create; chop $create;
      my $sql = "CREATE TABLE $tableName (\n$create\n)";
      print "$sql\n\n" if ($debug);

      $dbh->do ($sql) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot dbh->do: $sql", $logger, $debug);
    }

    if ( $debug ) {
      foreach my $columnName ( @{$columnSequence} ) { print "$columnName\n"; };
      print "\n";
    }

    return $dbh;
  } else {
    return undef;
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub CSV_insert_into_table {
  my ($rv, $dbh, $tableName, $columnSequence, $tableValues, $columnNameAutoincrement, $logger, $debug) = @_;

  if ( defined $dbh and $rv ) {
	my ($column, $placeholders, @values);

    foreach my $columnName ( @{$columnSequence} ) { 
	    $column .= $columnName .',';
      $placeholders .= '?,';
	    push ( @values, ( ( $columnName eq $columnNameAutoincrement ) ? '' : $tableValues->{$columnName} ) );
    }

    if ( defined $column and defined $placeholders) {
      chop $column; chop $placeholders;
      my $sql = "INSERT INTO $tableName ($column) VALUES ($placeholders)";
      print "$sql\n\n@values\n\n" if ($debug);
      $dbh->do ($sql, undef, @values) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot dbh->do: $sql, @values", $logger, $debug);
    }
  }

  return $rv;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub CSV_import_from_table {
  my ($rv, $dbh, $tableName, $columnSequence, $columnNameAutoincrement, $force, $logger, $debug) = @_;

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _do_action_SQL {
    my ($rv, $dbhASNMTAP, $tableName, $columnSequence, $columnNameCount, $columnNameAutoincrement, $ref, $logger, $debug) = @_;

    my ($actionSQL, $set, $where, $sql) = ('I', ' SET ', ' WHERE ');

    if ( $tableName eq $SERVERTABLEVENTS ) {
      $where .= 'catalogID = "' .$$ref->{lc('catalogID')}. '" and uKey = "' .$$ref->{lc('uKey')}. '" and step <> "0" and timeslot = "' .$$ref->{lc('timeslot')}. '" order by id desc limit 1';
      $sql = 'SELECT SQL_NO_CACHE status FROM ' . $SERVERTABLEVENTS . $where;
    }

    print "$sql\n\n" if ($debug);

    my $sthASNMTAP = $dbhASNMTAP->prepare($sql) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sthASNMTAP->prepare: $sql", $logger, $debug);
    $sthASNMTAP->execute() or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sthASNMTAP->execute", $logger, $debug);

    if ($rv) {
      while (my $refASNMTAP = $sthASNMTAP->fetchrow_hashref()) {
	    $actionSQL = ( ( $refASNMTAP->{status} eq '<NIHIL>' or $refASNMTAP->{status} eq 'OFFLINE' or $refASNMTAP->{status} eq 'NO TEST' ) ? 'U' : 'S' );
      }

      if ($actionSQL eq 'S') {
        print "SKIP\n" if ($debug);
      } else {
        foreach my $columnName ( @{$columnSequence} ) { 
          if ( $$columnNameCount{lc($columnName)} == 2 and $columnNameAutoincrement ne $columnName ) {
		    $set .= $columnName .'='. $dbhASNMTAP->quote($$ref->{lc($columnName)}) .',';
          }
		}

        chop $set;

        if ( $tableName eq $SERVERTABLEVENTS ) {
	      if ($actionSQL eq 'I') {
            $sql = 'INSERT INTO ' . $SERVERTABLEVENTS . $set;
          } elsif ($actionSQL eq 'U') {
            $sql = 'UPDATE ' . $SERVERTABLEVENTS . $set . $where;
          }
        }

        print "$sql\n\n" if ($debug);
        $dbhASNMTAP->do ($sql) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot dbhASNMTAP->do: $sql", $logger, $debug);
      }

      $sthASNMTAP->finish() or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sthASNMTAP->finish", $logger, $debug);
    }

    return $rv;
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  if ( defined $dbh and $rv ) {
    my $sql = "SELECT * FROM $tableName";
    print "$sql\n\n" if ($debug);
    my $sth = $dbh->prepare($sql) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sth->prepare: $sql", $logger, $debug);
    $sth->execute() or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sth->execute", $logger, $debug);

    if ( $rv ) {
      my $dbhASNMTAP = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot connect to the database", $logger, $debug);

      $sql = "SELECT * from $tableName limit 1";
      my $sthASNMTAP = $dbhASNMTAP->prepare($sql) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sthASNMTAP->prepare: $sql", $logger, $debug);
      $sthASNMTAP->execute() or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sthASNMTAP->execute", $logger, $debug);

      if ( $rv ) {
        my @columnSequenceASNMTAP = ();
        my $columnNamesASNMTAP = $sthASNMTAP->{NAME};
        my $NUM_OF_FIELDS = $sthASNMTAP->{NUM_OF_FIELDS};

        while ( my $ref = $sthASNMTAP->fetchrow_arrayref ) {
          for (my $item=0; $item < $NUM_OF_FIELDS; $item++) { push ( @columnSequenceASNMTAP, $$columnNamesASNMTAP[$item]); }
        }

        print "$tableName: NUM_OF_FIELDS CSV '" .@{$columnSequence}. "' & MySQL '$NUM_OF_FIELDS'\n" if ($debug);

        my %columnNameCount = ();
	    my ($errorDiff, $errorCount) = ('', 0);
        foreach my $item (@{$columnSequence}, @columnSequenceASNMTAP) { $columnNameCount{lc($item)}++;}

        foreach my $item (keys %columnNameCount) {
          unless ($columnNameCount{$item} == 2) {
            $errorDiff .= "    DIFF: $item\n";
            $errorCount++;
            $rv = 0;
          }
        }

        if ( $force ) {
          if ( $errorCount >= @{$columnSequence} ) {
            CSV_error_message (*EMAILREPORT, "$tableName: HEADER ?\n$errorDiff", $debug) unless ( $rv );
          } else {
            $rv = 1;
          }
        } else {
          CSV_error_message (*EMAILREPORT, "$tableName: NUM_OF_FIELDS CSV '" .@{$columnSequence}. "' <> MySQL '$NUM_OF_FIELDS'\n$errorDiff", $debug) unless ( $rv );
        }

        $sthASNMTAP->finish() or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sthASNMTAP->finish", $logger, $debug);

        if ( $rv ) {
          while (my $ref = $sth->fetchrow_hashref) {
            if ($debug) {
              foreach my $columnName ( @{$columnSequence} ) { print "$columnName = ", $ref->{lc($columnName)}, "\n"; }
            }

            $rv = _do_action_SQL ($rv, $dbhASNMTAP, $tableName, $columnSequence, \%columnNameCount, $columnNameAutoincrement, \$ref, $debug);
          }
        }
      }

      $dbhASNMTAP->disconnect;
    }

    $sth->finish() or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sth->finish", $logger, $debug);
  }

  return $rv;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub CSV_cleanup_table {
  my ($dbh, $logger, $debug) = @_;

  $dbh->disconnect if (defined $dbh);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub CSV_error_message {
  my ($EMAILREPORT, $error_message, $logger, $debug) = @_;

  use Scalar::Util qw(openhandle);
  my $error = "  > CSV Error:\n    $error_message\n";
  if ( ! $debug and defined $EMAILREPORT and openhandle($EMAILREPORT) ) { print $EMAILREPORT $error; } else { print $error; }
  $$logger->info("CSV Error: $error_message") if ( defined $$logger and $$logger->is_info() );
  return 0;
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub DBI_connect {
  my ($database, $server, $port, $user, $passwd, $alarm, $DBI_error_trap, $DBI_error_trap_Arguments, $logger, $debug, $boolean_debug_all) = @_;

  $$logger->info(" IN: DBI_connect: port: $port - alarm: $alarm") if ( defined $$logger and $$logger->is_info() );

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _DBI_handle_error {
    my ($error, $dbh) = @_;

    no warnings;
    print "     _DBI_handle_error: $error\n";
    $$logger->error("     _DBI_handle_error: $error");
    use warnings;
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my ($rv, $dbh, $alarmMessage) = 1;

  unless ( $alarm ) {
    $$logger->info("     DBI_connect: NO SIGNAL") if ( defined $$logger and $$logger->is_info() );

    if ( $boolean_debug_all ) {
      $dbh = DBIx::Log4perl->connect("dbi:mysql:$database:$server:$port", "$user", "$passwd", { RaiseError => 0, PrintError => 1, ShowErrorStatement => 1 } ) or $rv = $DBI_error_trap->(@{$DBI_error_trap_Arguments}, $logger, $debug);
      $dbh->dbix_l4p_getattr('dbix_l4p_logger'); # $$logger = $dbh->dbix_l4p_getattr('dbix_l4p_logger');
    } else {
      $dbh = DBI->connect("dbi:mysql:$database:$server:$port", "$user", "$passwd", { RaiseError => 1, PrintError => 0, ShowErrorStatement => 1 } ) or $rv = $DBI_error_trap->(@{$DBI_error_trap_Arguments}, $logger, $debug);
    }
  } else {
    $$logger->info("     DBI_connect: SIGNAL") if ( defined $$logger and $$logger->is_info() );

    use POSIX ':signal_h';
    my $DBI_CONNECT_ALARM_OFF = 0;
    my $_mask      = POSIX::SigAction->new ( SIGALRM ); # list of signals to mask in the handler
    my $_actionNew = POSIX::SigAction->new ( sub { $DBI_CONNECT_ALARM_OFF = $alarm; die "DBI_CONNECT_ALARM_OFF = $alarm\n"; }, $_mask );
    my $_actionOld = POSIX::SigAction->new ();
    sigaction ( SIGALRM, $_actionNew, $_actionOld );

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    eval {
      $DBI_CONNECT_ALARM_OFF = 1;
      alarm($alarm);

      if ( $boolean_debug_all ) {
        $dbh = DBIx::Log4perl->connect("dbi:mysql:$database:$server:$port", "$user", "$passwd", { RaiseError => 0, PrintError => 1, ShowErrorStatement => 1 } ) or $rv = $DBI_error_trap->(@{$DBI_error_trap_Arguments}, $logger, $debug);
        $dbh->dbix_l4p_getattr('dbix_l4p_logger'); # $$logger = $dbh->dbix_l4p_getattr('dbix_l4p_logger');
      } else {
        $dbh = DBI->connect("dbi:mysql:$database:$server:$port", "$user", "$passwd", { RaiseError => 1, PrintError => 0, ShowErrorStatement => 1 } ) or $rv = $DBI_error_trap->(@{$DBI_error_trap_Arguments}, $logger, $debug);
      }

      alarm(0);
      $DBI_CONNECT_ALARM_OFF = 0;
    };

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    alarm(0);
    sigaction( SIGALRM, $_actionOld ); # restore original signal handler

    if ( $DBI_CONNECT_ALARM_OFF ) {
      $dbh = undef;
      $rv = $DBI_error_trap->(@{$DBI_error_trap_Arguments}, $logger, $debug);
      $alarmMessage = "DBI_CONNECT_ALARM_OFF = $DBI_CONNECT_ALARM_OFF";
      $$logger->debug("     DBI_CONNECT_ALARM_OFF: Connection to '$database' timed out") if ( defined $$logger and $$logger->is_debug() );
    }
  }

  # set up error handling
  $dbh->{HandleError} = sub { _DBI_handle_error(@_) } if ( defined $dbh and $rv );

  $$logger->info('OUT: DBI_connect') if ( defined $$logger and $$logger->is_info() );
  return ($dbh, $rv, $alarmMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub DBI_do {
  my ($rv, $dbh, $statement, $alarm, $DBI_error_trap, $DBI_error_trap_Arguments, $logger, $debug) = @_;

  $$logger->info(" IN: DBI_do: rv: $rv - alarm: $alarm") if ( defined $$logger and $$logger->is_info() );
  my ($affected, $alarmMessage) = (0);

  if ( $rv ) {
    unless ( $alarm ) {
      $$logger->info("     DBI_do: NO SIGNAL") if ( defined $$logger and $$logger->is_info() );
      $affected = $$dbh->do($statement) or $rv = $DBI_error_trap->(@{$DBI_error_trap_Arguments}, $logger, $debug);
    } else {
      $$logger->info("     DBI_do: SIGNAL") if ( defined $$logger and $$logger->is_info() );

      use POSIX ':signal_h';
      my $DBI_DO_ALARM_OFF = 0;
      my $_mask      = POSIX::SigAction->new ( SIGALRM ); # list of signals to mask in the handler
      my $_actionNew = POSIX::SigAction->new ( sub { $DBI_DO_ALARM_OFF = $alarm; die "DBI_DO_ALARM_OFF = $alarm\n"; }, $_mask );
      my $_actionOld = POSIX::SigAction->new ();
      sigaction ( SIGALRM, $_actionNew, $_actionOld );

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      eval {
        $DBI_DO_ALARM_OFF = 1;
        alarm($alarm);
        $affected = $$dbh->do($statement) or $rv = $DBI_error_trap->(@{$DBI_error_trap_Arguments}, $logger, $debug);
        alarm(0);
        $DBI_DO_ALARM_OFF = 0;
      };

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      alarm(0);
      sigaction( SIGALRM, $_actionOld ); # restore original signal handler

      if ( $DBI_DO_ALARM_OFF ) {
        $rv = $DBI_error_trap->(@{$DBI_error_trap_Arguments}, $logger, $debug);
        $alarmMessage = "DBI_DO_ALARM_OFF = $DBI_DO_ALARM_OFF";
        $$logger->debug("     DBI_DO_ALARM_OFF: dbh->do timed out") if ( defined $$logger and $$logger->is_debug() );
      }
    }
  }

  $$logger->info("OUT: DBI_do") if ( defined $$logger and $$logger->is_info() );
  return ( $rv, $alarmMessage, $affected );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub DBI_execute {
  my ($rv, $sth, $alarm, $DBI_error_trap, $DBI_error_trap_Arguments, $logger, $debug) = @_;

  $$logger->info(" IN: DBI_execute: rv: $rv - alarm: $alarm") if ( defined $$logger and $$logger->is_info() );
  my $alarmMessage;

  if ( $rv ) {
    unless ( $alarm ) {
      $$logger->info("     DBI_execute: NO SIGNAL") if ( defined $$logger and $$logger->is_info() );
      $$sth->execute() or $rv = $DBI_error_trap->(@{$DBI_error_trap_Arguments}, $logger, $debug);
    } else {
      $$logger->info("     DBI_execute: SIGNAL") if ( defined $$logger and $$logger->is_info() );

      use POSIX ':signal_h';
      my $DBI_EXECUTE_ALARM_OFF = 0;
      my $_mask      = POSIX::SigAction->new ( SIGALRM ); # list of signals to mask in the handler
      my $_actionNew = POSIX::SigAction->new ( sub { $DBI_EXECUTE_ALARM_OFF = $alarm; die "DBI_EXECUTE_ALARM_OFF = $alarm\n"; }, $_mask );
      my $_actionOld = POSIX::SigAction->new ();
      sigaction ( SIGALRM, $_actionNew, $_actionOld );

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      eval {
        $DBI_EXECUTE_ALARM_OFF = 1;
        alarm($alarm);
        $$sth->execute() or $rv = $DBI_error_trap->(@{$DBI_error_trap_Arguments}, $logger, $debug);
        alarm(0);
        $DBI_EXECUTE_ALARM_OFF = 0;
      };

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      alarm(0);
      sigaction( SIGALRM, $_actionOld ); # restore original signal handler

      if ( $DBI_EXECUTE_ALARM_OFF ) {
        $rv = $DBI_error_trap->(@{$DBI_error_trap_Arguments}, $logger, $debug);
        $alarmMessage = "DBI_EXECUTE_ALARM_OFF = $DBI_EXECUTE_ALARM_OFF";
        $$logger->debug("     DBI_EXECUTE_ALARM_OFF: sth->execute timed out") if ( defined $$logger and $$logger->is_debug() );
      }
    }
  }

  $$logger->info("OUT: DBI_execute") if ( defined $$logger and $$logger->is_info() );
  return ( $rv, $alarmMessage );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub DBI_error_trap {
  my ($EMAILREPORT, $error_message, $logger, $debug) = @_;

  use Scalar::Util qw(openhandle);
  my $error = "  > DBI Error:\n" .$error_message. "\nERROR: $DBI::err ($DBI::errstr)\n";
  if ( ! $debug and defined $EMAILREPORT and openhandle($EMAILREPORT) ) { print $EMAILREPORT $error; } else { print $error; }
  $$logger->info("DBI Error:" .$error_message. "ERROR: $DBI::err ($DBI::errstr)") if ( defined $$logger and $$logger->is_info() );
  return 0;
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub LOG_init_log4perl {
  my ($item, $config, $boolean_debug_all) = @_;

  my $logger;

  if ( $boolean_debug_all ) {
    eval {
      use Log::Log4perl qw(get_logger);
      use DBIx::Log4perl;

      if ( -e "$APPLICATIONPATH/log4perl.cnf" ) {
        Log::Log4perl->init_and_watch("$APPLICATIONPATH/log4perl.cnf", 'HUP');
      } else {
        my $log4perl_cnf;

        if ( defined $config ) {
          $log4perl_cnf = $config;
        } else {
          $log4perl_cnf = qq(
            log4perl.logger                       = TRACE, LOGFILE, LOGSCREEN

            log4perl.appender.LOGFILE             = Log::Log4perl::Appender::File
            log4perl.appender.LOGFILE.filename    = $LOGPATH/root.log
            log4perl.appender.LOGFILE.mode        = append
            log4perl.appender.LOGFILE.Threshold   = ERROR
            log4perl.appender.LOGFILE.layout      = PatternLayout
            log4perl.appender.LOGFILE.layout.ConversionPattern = [%d] %F %L %c - %m%n

            log4perl.appender.LOGSCREEN           = Log::Log4perl::Appender::Screen
            log4perl.appender.LOGSCREEN.stderr    = 0
            log4perl.appender.LOGSCREEN.layout    = PatternLayout
            log4perl.appender.LOGSCREEN.layout.ConversionPattern = [%d] %F %L %c - %m%n

            log4perl.logger.DBIx.Log4perl         = TRACE, MySQL
            log4perl.appender.MySQL               = Log::Log4perl::Appender::File
            log4perl.appender.MySQL.filename      = $LOGPATH/MySQL.log
            log4perl.appender.MySQL.mode          = append
            log4perl.appender.MySQL.layout        = Log::Log4perl::Layout::SimpleLayout
          );
        }

        Log::Log4perl->init( \$log4perl_cnf );
      }

      $logger = get_logger($item);
    }
  }

  return ( $logger );
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Applications is a Perl module that provides a nice object oriented interface for ASNMTAP Applications

=head1 Description

ASNMTAP::Asnmtap::Applications Subclass of ASNMTAP::Asnmtap

=head1 SEE ALSO

ASNMTAP::Asnmtap, ASNMTAP::Asnmtap::Applications::CGI, ASNMTAP::Asnmtap::Applications::Collector, ASNMTAP::Asnmtap::Applications::Display

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
