# This -*- perl -*- script writes the Makefile for ASNMTAP
# $Id: Makefile.PL, v3.2.3 2010/xx/xx 18:14:00 Alex Peeters Exp $

use 5.008000;
use strict;

# - - - - - - - - - - UPDATE VERSION EVERY NEW RELEASE: - - - - - - - - -

# Prepare new release ---------------------------------------------------
# copy current release '3.002.003' to '3.002.004'
#                       3.002.xxx      3.001.yyy

# replace 'Version      : 3.002.xxx'  with `3.002.yyy;`

# rename `MANIFEST-3.002.xxx` with `MANIFEST-3.002.yyy.sql`
# rename `asnmtap-3.002.xxx.sql` with `asnmtap-3.002.yyy.sql`

# replace `asnmtap-3.002.xxx` with `asnmtap-3.002.yyy`

# replace `(q$Revision: 3.002.xxx$ =~ /\d+/g)` with `(q$Revision: 3.002.yyy$ =~ /\d+/g)`
# replace `v3.002.xxx;` with `v3.002.yyy;`
# replace `'3.002.xxx'` with `'3.002.yyy'`
# replace ASNMTAP 3.002.xxx postfix; nl-BE; rv:3.002.xxx) Gecko/yyyymmdd with ASNMTAP 3.002.yyy postfix; nl-BE; rv:3.002.yyy) Gecko/2010....

# Upload new release ----------------------------------------------------
# replace 'Latest update: dd month 2011' with 'Latest update: .. ... 2010'
# replace `# 2010/mm/dd, v` with `# 2010/../.., v`

# Module section  - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Config qw(%Config);
use ExtUtils::MakeMaker qw(WriteMakefile prompt);

my $module  = 'ExtUtils::MakeMaker';
my $version = '6.32';

unless ( eval ( "require $module; Exporter::require_version ( '$module', $version );" ) ) {
  print "\n$module v$version, required for 'perl Makefile.PL' via CPAN\n";
  print "\nperl -MCPAN -e 'install $module'\n\n";
  exit;
}

# $module  = 'ExtUtils::Autoconf';
# $version = '0.02';

# unless ( eval ( "require $module; Exporter::require_version ( '$module', $version );" ) ) {
#   print "\n$module v$version, required for 'perl Makefile.PL' via CPAN\n";
#   print "\nperl -MCPAN -e 'install $module'\n\n";
#   exit;
# }

# Configuration section - - - - - - - - - - - - - - - - - - - - - - - - -

my $VERSION = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

my $PERL_AUTOINSTALL     = exists $ENV{PERL_AUTOINSTALL}     ? $ENV{PERL_AUTOINSTALL}     : 0;
my $ASNMTAP_APPLICATIONS = exists $ENV{ASNMTAP_APPLICATIONS} ? $ENV{ASNMTAP_APPLICATIONS} : 0;
my $ASNMTAP_PLUGINS      = exists $ENV{ASNMTAP_PLUGINS}      ? $ENV{ASNMTAP_PLUGINS}      : 0;
my $ASNMTAP_UID          = exists $ENV{ASNMTAP_UID}          ? $ENV{ASNMTAP_UID}          : '500';
my $ASNMTAP_GID          = exists $ENV{ASNMTAP_GID}          ? $ENV{ASNMTAP_GID}          : '500';
my $ASNMTAP_PATH         = exists $ENV{ASNMTAP_PATH}         ? $ENV{ASNMTAP_PATH}         : '/opt/asnmtap';
my $ASNMTAP_PROXY        = exists $ENV{ASNMTAP_PROXY}        ? $ENV{ASNMTAP_PROXY}        : '0.0.0.0';

# End Configuration - You should not have to change anything below this line

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# This hash will contain a list of all Application System Network Monitoring Toolkit Alex Peeters files
my %PM;

$PM{'lib/ASNMTAP/PseudoHash.pm'}                      = '$(INST_LIBDIR)/ASNMTAP/PseudoHash.pm';
$PM{'lib/ASNMTAP/PseudoHash.pod'}                     = '$(INST_LIBDIR)/ASNMTAP/PseudoHash.pod';

$PM{'lib/ASNMTAP/Time.pm'}                            = '$(INST_LIBDIR)/ASNMTAP/Time.pm';
$PM{'lib/ASNMTAP/Time.pod'}                           = '$(INST_LIBDIR)/ASNMTAP/Time.pod';

$PM{'lib/ASNMTAP/Asnmtap.pm'}                         = '$(INST_LIBDIR)/ASNMTAP/Asnmtap.pm';
$PM{'lib/ASNMTAP/Asnmtap.pod'}                        = '$(INST_LIBDIR)/ASNMTAP/Asnmtap.pod';

$PM{'lib/ASNMTAP/Asnmtap/Applications.pm'}            = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Applications.pm';
$PM{'lib/ASNMTAP/Asnmtap/Applications.pod'}           = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Applications.pod';
$PM{'lib/ASNMTAP/Asnmtap/Applications/CGI.pm'}        = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Applications/CGI.pm';
$PM{'lib/ASNMTAP/Asnmtap/Applications/CGI.pod'}       = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Applications/CGI.pod';
$PM{'lib/ASNMTAP/Asnmtap/Applications/Collector.pm'}  = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Applications/Collector.pm';
$PM{'lib/ASNMTAP/Asnmtap/Applications/Collector.pod'} = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Applications/Collector.pod';
$PM{'lib/ASNMTAP/Asnmtap/Applications/Display.pm'}    = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Applications/Display.pm';
$PM{'lib/ASNMTAP/Asnmtap/Applications/Display.pod'}   = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Applications/Display.pod';

$PM{'lib/ASNMTAP/Asnmtap/Plugins.pm'}                 = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins.pm';
$PM{'lib/ASNMTAP/Asnmtap/Plugins.pod'}                = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins.pod';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/IO.pm'}              = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/IO.pm';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/IO.pod'}             = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/IO.pod';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/Mail.pm'}            = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/Mail.pm';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/Mail.pod'}           = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/Mail.pod';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/Modem.pm'}           = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/Modem.pm';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/Modem.pod'}          = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/Modem.pod';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/Nagios.pm'}          = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/Nagios.pm';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/Nagios.pod'}         = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/Nagios.pod';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/NPTest.pm'}          = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/NPTest.pm';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/SOAP.pm'}            = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/SOAP.pm';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/SOAP.pod'}           = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/SOAP.pod';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/WebTransact.pm'}     = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/WebTransact.pm';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/WebTransact.pod'}    = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/WebTransact.pod';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/XML.pod'}            = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/XML.pod';
$PM{'lib/ASNMTAP/Asnmtap/Plugins/XML.pm'}             = '$(INST_LIBDIR)/ASNMTAP/Asnmtap/Plugins/XML.pm';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my @man3pods = qw (
  Asnmtap
  Time
  Asnmtap/Applications
  Asnmtap/Applications/CGI
  Asnmtap/Applications/Collector
  Asnmtap/Applications/Display
  Asnmtap/Plugins
  Asnmtap/Plugins/IO
  Asnmtap/Plugins/Mail
  Asnmtap/Plugins/Modem
  Asnmtap/Plugins/Nagios
  Asnmtap/Plugins/SOAP
  Asnmtap/Plugins/WebTransact
  Asnmtap/Plugins/XML
);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my @prerequisites = (
# [ '<level>', '<feature>',                '<installed module>',                  <dependency hash>, <install by default: 0 = no, 1 = yes, 2 = always, 3 = reserved and 4 = info>, [[<files>, <x|r>], ...] ];
  [ '*00',     'Package ASNMTAP::Asnmtap', 'ASNMTAP::Asnmtap',                    { 'CPAN' => '1.9205', 'CPANPLUS' => '0.84', 'Config::General' => '2.38', 'Config::General::Interpolated' => '2.07', 'Data::Dumper' => '2.121','Dumpvalue' => '1.11', 'Getopt::Long' => '2.37', 'IO::CaptureOutput' => '1.0801', 'Test::Pod::Coverage' => '1.08', 'Test::Simple' => '0.80', 'Time::Local' => '1.17' }, 2, 
   [
    [ 'Changes',                        'r' ],
    [ 'AUTHORS',                        'r' ],
    [ 'INSTALL',                        'r' ],
    [ 'README',                         'r' ],
    [ 'Asnmtap.cnf',                    'R' ],
    [ 'log',                            'd' ],
    [ 'pid',                            'd' ],
   ]
  ],
  [ '*02',     'Time',                     'ASNMTAP::Time',                       { 'ASNMTAP::Asnmtap' => '*00', 'Date::Calc' => '5.4', 'Time::Local' => '1.17' }, 2, [], [] ],
  [ '*0010',   'Subclass Applications',    'ASNMTAP::Asnmtap::Applications',      { 'ASNMTAP::Asnmtap' => '*00', 'Bundle::DBI' => '1.604', 'Bundle::DBD::mysql' => '4.004', 'Config::General' => '2.38', 'Config::General::Interpolated' => '2.07', 'DBD::CSV' => '0.26', 'DBIx::Log4perl' => '0.18', 'Getopt::Long' => '2.37', 'HTML::Entities' => '1.35', 'Log::Log4perl' => '1.26', 'Mail::Sendmail' => '0.79', 'Text::CSV' => '1.16', 'Time::Local' => '1.17' }, 1,
   [
    [ 'fixRights.sh',                   'X' ],

    [ 'applications/*.pl',              'x' ],
    [ 'applications/*.sh',              'X' ],
    [ 'applications/*.cnf',             'R' ],

    [ 'applications/bin/*.pl',          'x' ],
    [ 'applications/bin/*.sh',          'X' ],

    [ 'applications/sbin/*.pl',         'x' ],
    [ 'applications/sbin/*.sh',         'X' ],

    [ 'applications/custom/*.pm-orig',  'r' ],

    [ 'applications/tools/mysql/*.sql', 'r' ],
    [ 'applications/tools/mysql/*.sh',  'x' ],

    [ 'applications/etc',               'd' ],
    [ 'applications/slave',             'd' ],
    [ 'applications/master',            'd' ],
    [ 'applications/htmlroot/nav',      'd' ],

    [ 'applications/tmp',               'd' ],
    [ 'applications/tmp/config',        'd' ],
    [ 'applications/tmp/cgisess',       'd' ],

    [ 'results',                        'd' ],
   ]
  ],
  [ '*001000', 'Subclass CGI Interface',   'ASNMTAP::Asnmtap::Applications::CGI', { 'ASNMTAP::Asnmtap::Applications' => '*0010', 'CGI::Session' => '4.30', 'Date::Calc' => '5.4', 'Proc::ProcessTable' => '0.42', 'NetAddr::IP' => '4.007', 'Time::Local' => '1.17' }, 0,
   [
    [ 'applications/htmlroot/*.css',                   'r' ],
    [ 'applications/htmlroot/*.js',                    'x' ],

    [ 'applications/htmlroot/cgi-bin/*.pl',            'x' ],
    [ 'applications/htmlroot/cgi-bin/*.book',          'R' ],
    [ 'applications/htmlroot/cgi-bin/*.sh',            'x' ],

    [ 'applications/htmlroot/cgi-bin/admin/*.pl',      'x' ],

    [ 'applications/htmlroot/cgi-bin/moderator/*.pl',  'x' ],

    [ 'applications/htmlroot/cgi-bin/sadmin/*.pl',     'x' ],

    [ 'applications/htmlroot/img/*.gif',               'r' ],
    [ 'applications/htmlroot/img/*.jpg',               'r' ],
    [ 'applications/htmlroot/img/*.png',               'r' ],
    [ 'applications/htmlroot/img/fw0/*.gif',           'r' ],
    [ 'applications/htmlroot/img/logos/bodyimage.gif', 'R' ],

    [ 'applications/htmlroot/pdf/*.pdf',               'r' ],

    [ 'applications/htmlroot/sound/*.wav',             'r' ],

    [ 'applications/tools/resources/*.js',             'r' ],

    [ 'applications/tools/templates/*.sh',             'x' ],
    [ 'applications/tools/templates/*.html',           'r' ],

    [ 'applications/tools/templates/master/*.sh',      'x' ],

    [ 'applications/tools/templates/slave/*.conf',     'r' ],
    [ 'applications/tools/templates/slave/*.sh',       'x' ],


    [ 'applications/htmlroot/snmptraps/*.php',                         'r' ],

    [ 'applications/htmlroot/snmptraps/etc/config.ini.php',            'R' ],

    [ 'applications/htmlroot/snmptraps/images/kde3/*.db',              'r' ],
    [ 'applications/htmlroot/snmptraps/images/kde3/*.png',             'r' ],

    [ 'applications/htmlroot/snmptraps/images/nuovo/*.db',             'r' ],
    [ 'applications/htmlroot/snmptraps/images/nuovo/*.png',            'r' ],

    [ 'applications/htmlroot/snmptraps/images/nuvola_1/*.db',          'r' ],
    [ 'applications/htmlroot/snmptraps/images/nuvola_1/*.png',         'r' ],

    [ 'applications/htmlroot/snmptraps/images/nuvola_2/*.db',          'r' ],
    [ 'applications/htmlroot/snmptraps/images/nuvola_2/*.png',         'r' ],

    [ 'applications/htmlroot/snmptraps/include/classes/*.php',         'r' ],

    [ 'applications/htmlroot/snmptraps/include/css/*.css',             'r' ],

    [ 'applications/htmlroot/snmptraps/include/js/*.js',               'r' ],

    [ 'applications/htmlroot/snmptraps/include/xml/language/DE/*.xml', 'r' ],

    [ 'applications/htmlroot/snmptraps/include/xml/language/EN/*.xml', 'r' ],
   ] 
  ],
  [ '*0011',   'Subclass Plugins',         'ASNMTAP::Asnmtap::Plugins',           { 'ASNMTAP::Asnmtap' => '*00', 'Date::Calc' => '5.4', 'Time::HiRes' => '1.9705' }, 2,
   [
    [ 'plugins/*.pl',                    'x' ],

    [ 'plugins/*.SQL',                   'r' ],

    [ 'plugins/jUnit/*.pl',              'x' ],

    [ 'plugins/snmptt/*.pl',             'x' ],

    [ 'plugins/templates/*.pl',          'x' ],

    [ 'plugins/templates/dtd/*.dtd',     'r' ],

    [ 'plugins/templates/jUnit/*.*',     'r' ],

    [ 'plugins/templates/snmptt/*.*',    'r' ],

    [ 'plugins/templates/ssl/crt/*.crt', 'r' ],

    [ 'plugins/templates/ssl/key/*.key', 'r' ],

    [ 'plugins/templates/xml/*.xml',     'r' ],

    [ 'plugins/tools/*.pl',              'x' ],

    [ 'plugins/tmp',                     'd' ]
   ]
  ],
  [ '*001100', 'Subclass Nagios', 'ASNMTAP::Asnmtap::Plugins::Nagios', { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'Time::Local' => '1.17', 'Net::Ifconfig::Wrapper' => '0.09' }, 1,
   [
    [ 'plugins/nagios/*.pl',                  'x' ],

    [ 'plugins/nagios/templates/*.pl',        'x' ],

    [ 'plugins/nagios/templates/dtd/*.dtd',   'r' ],

    [ 'plugins/nagios/templates/xml/*.xml',   'r' ],
    [ 'plugins/nagios/templates/xml/*.xml-*', 'r' ],
   ]
  ],
  [ '*011101', 'IO support',          'ASNMTAP::Asnmtap::Plugins::IO',          { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'IO' => '1.23' }, 1, [], [] ],
  [ '*001102', 'Mail support',        'ASNMTAP::Asnmtap::Plugins::Mail',        { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'Date::Calc' => '5.4', 'Email::Simple' => '2.003', 'IO::String' => '1.08', 'Mail::POP3Client' => '2.18', 'Mail::Sendmail' => '0.79', 'MIME::Base64' => '3.08', 'MIME::Tools' => '5.420', 'Net::IMAP::Simple' => '1.17', 'Time::Local' => '1.17' }, 1, [], [] ],
  [ '*001103', 'Modem support',       'ASNMTAP::Asnmtap::Plugins::Modem',       { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'IO' => '1.23', ( $^O eq 'MSWin32' ? ('Win32::SerialPort' => '0.19', 'Win32::API' => '0.41', 'Win32::RASE' => '1.01') : ('Device::SerialPort' => '1.002', 'Net::Ifconfig::Wrapper' => '0.09') ), 'Device::Modem' => '1.47' }, 0,
   [
    [ '/etc/chatscripts/ASNMTAP', 'R' ],
    [ '/etc/ppp/pap-secrets',     'R' ],
    [ '/etc/ppp/peers/ASNMTAP',   'R' ],
    [ '/etc/ppp/resolv/ASNMTAP',  'R' ],
    [ '/usr/bin/plog',            'R' ],
    [ '/usr/bin/poff',            'R' ],
    [ '/usr/bin/pon',             'R' ],
   ]
  ],
  [ '*001104', 'SOAP support',        'ASNMTAP::Asnmtap::Plugins::SOAP',        { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'SOAP::Lite' => '0.710.08', 'WSRF::Lite' => '0.8.2.7', 'DateTime' => '0.37', 'DateTime::Format::Epoch' => '0.10', 'DateTime::Format::W3CDTF' => '0.04', 'Digest::SHA1' => '2.12', 'Crypt::OpenSSL::RSA' => '0.26', 'Crypt::OpenSSL::X509' => '1.2', 'HTTP::Daemon::SSL' => '1.04', 'Sys::Hostname::Long' => '1.4', 'MIME::Base64' => '3.08', 'XML::CanonicalizeXML' => '0.03', 'XML::DOM' => '1.44' }, 1, [], [] ],
  [ '*001105', 'WebTransact support', 'ASNMTAP::Asnmtap::Plugins::WebTransact', { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'Bundle::LWP' => '1.11', 'CGI' => '3.37', 'Compress::Zlib' => '2.010', 'Crypt::SSLeay' => '0.56', 'Digest::MD5' => '2.36', 'IO::Socket::SSL' => '1.33', 'MIME::Base64' => '3.08', 'Net::FTP' => '2.75', 'Net::SSLeay' => '1.32', 'URI' => '1.36' }, 1, [], [] ],
  [ '*001106', 'XML support',         'ASNMTAP::Asnmtap::Plugins::XML',         { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'XML::Parser' => '2.36', 'XML::LibXML' => '1.70', 'XML::Simple' => '2.18' }, 2, [], [] ],
  [ '*001199', 'Testing Templates',   'ASNMTAP::Asnmtap::Plugins::NPTest',      { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'Cwd' => '3.25', 'Data::Dumper' => '2.121', 'File::Basename' => '2.73', 'IO' => '1.23' }, 1, [], [] ],
  [ '', 'unbless data structure',     'Data::Structure::Util',                  { 'Test::Builder::Tester' => '1.13', 'Test::Pod' => '1.22', 'Clone' =>'0.18', 'File::Find::Rule' => '0.28', 'Data::Structure::Util' => '0.11' }, 4, [], [] ],
  [ '', 'FTP template',               'check_template-ftp.pl',                  { 'Net::FTP' => '2.75' }, 4, [], [] ],
  [ '', 'LDAP template',              'check_template-ldap.pl',                 { 'Convert::ASN1' => '0.19', 'URI::ldap' => '1.11', 'Digest::MD5' => '2.36', 'XML::Parser' => '2.36', 'Net::LDAP' => '0.34' }, 4, [], [] ],
  [ '', 'MySQL template',             'check_MySQL-database-replication.pl',    { 'Bit::Vector' => '6.3', 'Date::Calc' => '5.4', 'Bundle::DBI' => '1.604', 'Bundle::DBD::mysql' => '4.004', 'DBIx::Log4perl' => '0.18', 'Log::Log4perl' => '1.26' }, 4, [], [] ],
  [ '', 'SFTP template',              'check_template-sftp.pl',                 { 'Net::SFTP::Foreign' => '1.61' }, 4, [], [] ]
);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my %has_module_cache = ();

# Allow us to suppress all program installation with the -n (library only) option.
# This is for those that don't want to mess with the configuration section of this file.
use Getopt::Std;
use vars qw ( $opt_n );
unless ( getopts ('n') ) { die "Usage: $0 [-n]\n"; }
my $prompt = ( $opt_n ) ? 0 : 1;

unlink ('t/APPLICATIONS_ENABLED')        if ( -e 't/APPLICATIONS_ENABLED' );
unlink ('t/APPLICATIONS_CGI_ENABLED')    if ( -e 't/APPLICATIONS_CGI_ENABLED' );

unlink ('t/PLUGINS_ENABLED')             if ( -e 't/PLUGINS_ENABLED' );
unlink ('t/PLUGINS_NPTEST_ENABLED')      if ( -e 't/PLUGINS_NPTEST_ENABLED' );
unlink ('t/PLUGINS_MAIL_ENABLED')        if ( -e 't/PLUGINS_MAIL_ENABLED' );
unlink ('t/PLUGINS_MODEM_ENABLED')       if ( -e 't/PLUGINS_MODEM_ENABLED' );
unlink ('t/PLUGINS_NAGIOS_ENABLED')      if ( -e 't/PLUGINS_NAGIOS_ENABLED' );
unlink ('t/PLUGINS_SOAP_ENABLED')        if ( -e 't/PLUGINS_SOAP_ENABLED' );
unlink ('t/PLUGINS_WEBTRANSACT_ENABLED') if ( -e 't/PLUGINS_WEBTRANSACT_ENABLED' );
unlink ('t/PLUGINS_XML_ENABLED')         if ( -e 't/PLUGINS_XML_ENABLED' );

if ( $prompt ) {
  print <<EOT;

Note that you can avoid these questions by passing the '-n' option 
to 'Makefile.PL'.

The DEFAULT AUTO for automatic installation of dependencies via CPAN is '$PERL_AUTOINSTALL'.

The Applications are installed when the value equals 1.
The DEFAULT APPLICATIONS for the the plugin templates is '$ASNMTAP_APPLICATIONS'.

The Plugin templates are installed when the value equals 1.
The DEFAULT PLUGINS for the the plugin templates is '$ASNMTAP_PLUGINS'.

The DEFAULT PATH for the applications and/or plugins is '$ASNMTAP_PATH'.

The DEFAULT UID for the applications and plugins is '$ASNMTAP_UID'.

The DEFAULT GID for the applications and plugins is '$ASNMTAP_GID'.

The DEFAULT PROXY for testing the plugins is '$ASNMTAP_PROXY'.

With the environment variables PERL_AUTOINSTALL, ASNMTAP_APPLICATIONS,
ASNMTAP_PLUGINS, ASNMTAP_PATH, ASNMTAP_UID, ASNMTAP_GID and ASNMTAP_PROXY
you can change this.

EOT

  $PERL_AUTOINSTALL = ( ExtUtils::MakeMaker::prompt( "\nAutomatic installation of dependencies via CPAN?" => ( $PERL_AUTOINSTALL ? 'yes' : 'no' ) ) =~ /^\s*(y)/i );
  $ENV{PERL_AUTOINSTALL} = $PERL_AUTOINSTALL;

  $ASNMTAP_APPLICATIONS = ( ExtUtils::MakeMaker::prompt( "\nDo you want to install the Applications?" => ( $ASNMTAP_APPLICATIONS ? 'yes' : 'no' ) ) =~ /^\s*(y)/i );

  $ASNMTAP_PLUGINS = ( ExtUtils::MakeMaker::prompt( "\nDo you want to install the Plugin templates?" => ( $ASNMTAP_PLUGINS ? 'yes' : 'no' ) ) =~ /^\s*(y)/i );

  if ( $ASNMTAP_APPLICATIONS or $ASNMTAP_PLUGINS ) {
    $ASNMTAP_UID = prompt ("\nThe wanted UID for the applications and/or plugins?", $ASNMTAP_UID);
    $ASNMTAP_GID = prompt ("\nThe wanted GID for the applications and/or plugins?", $ASNMTAP_GID);

    do {
      $ASNMTAP_PATH = prompt ("\nWhere do want to install the applications and/or plugins?", $ASNMTAP_PATH);
      unless ( -d $ASNMTAP_PATH ) { mkdir $ASNMTAP_PATH or print "- invalid directory: '$ASNMTAP_PATH'\n" };
    } while ( ! -d $ASNMTAP_PATH );
  }

} else {
  if ( $ASNMTAP_APPLICATIONS or $ASNMTAP_PLUGINS ) {
    print "\nCreate directory: '$ASNMTAP_PATH':\n";
    unless ( -d $ASNMTAP_PATH ) { mkdir $ASNMTAP_PATH or die "- invalid directory '$ASNMTAP_PATH'\n"; }
  }
}

if ( $ASNMTAP_APPLICATIONS or $ASNMTAP_PLUGINS ) {
  print "- created (when not already exists): '$ASNMTAP_PATH'\n\n";
  chown ( $ASNMTAP_UID, $ASNMTAP_GID, $ASNMTAP_PATH ) or die "- chown $ASNMTAP_UID:$ASNMTAP_GID $ASNMTAP_PATH failed: $!";

  if ( $ASNMTAP_APPLICATIONS ) {
    unlink <$ASNMTAP_PATH/applications/htmlroot/nav/*/reports-*.html> if ( -e "$ASNMTAP_PATH/applications/htmlroot/nav" );

    if ( -e "$ASNMTAP_PATH/results" ) {
      unlink <$ASNMTAP_PATH/results/FOOTER.html>;
      unlink <$ASNMTAP_PATH/results/*/FOOTER.html>;
      unlink <$ASNMTAP_PATH/results/*/debug/FOOTER.html>;
      unlink <$ASNMTAP_PATH/results/*/reports/FOOTER.html>;

      unlink <$ASNMTAP_PATH/results/HEADER.html>;
      unlink <$ASNMTAP_PATH/results/*/HEADER.html>;
      unlink <$ASNMTAP_PATH/results/*/debug/HEADER.html>;
      unlink <$ASNMTAP_PATH/results/*/reports/HEADER.html>;
    }
  }
}

my $intro = <<EOI;
This Build comes with some package that I can install.

We are about to install ASNMTAP::Asnmtap and for your convenience will
provide you with list of modules and prerequisites,  so you'll be able
to choose only modules you need for your configuration.

EOI

if ( $prompt ) {
  ExtUtils::MakeMaker::prompt( $intro . "Press <enter> to see the detailed list." );
} else {
  print "These are the modules that will get installed:\n\n";
}

# This hash will contain a list of all perl modules we would like to explicitly depend upon in our Makefile
my %PREREQ_PM;

# Maintains a cache of what 3rd party modules you have installed
sub has_module {
  my ($module, $version) = @_;

  $version ||= '';
  return ( ( $version =~ /^\*\d{2,2}(?:\d{2,2}(?:\d{2,2})?)?$/ ) ? 2 : ( $has_module_cache { "$module$version" } ||= eval ( "require $module; Exporter::require_version ( '$module', $version ) if ( $version ); 1" ) ) );
}

# Print a single prerequisite to the screen
sub generate_PREREQ_PM {
  my ($feature, $dependency, $modules, $install) = @_;
  my $buffer;
  my $i = 0;

  foreach (keys %$modules) {
    my $detected = has_module ( $_, $modules->{$_} );

    $buffer .= sprintf ( "%-24s [%s] %-32s %-8s\n", ( $i++ ? '' : $feature), ($detected >= 2 ? '+' : ( $detected ? '*' : ' ') ), $_ . ( $modules->{ $_ } and $modules->{ $_ } !~ /^\*\d{2,2}(?:\d{2,2}(?:\d{2,2})?)?$/ ? " (v$modules->{$_})" : '' ), ( $i == 1 ? ( $install ? $install == 4 ? 'info' : ( ( $install == 3 ? 'reserved' : ($install == 2 ? 'always' : '[ yes ]') ) ) : '[ no ]') : '' ) ); 
  }

  return $buffer;
}

# Print the entire prerequisites table
sub generate_PREREQ_PM_table {
  my $buffer = sprintf ( "%-24s %-36s %-8s\n", 'Feature', 'Prerequisites', 'Install?' );
  $buffer   .= sprintf ( "%s %s %s\n","-" x 24,"-" x 36,"-" x 8 );
  foreach my $prerequisites ( @prerequisites ) { $buffer .= generate_PREREQ_PM ( @$prerequisites[1..4] ); }
  $buffer   .= "\n<- An asterix [*] indicates if the module is currently installed.\n";
  return $buffer;
}

# Update the entire prerequisites table
sub update_prerequisites_table {
  my ($u_level, $u_default) = @_;

  return if ( $u_default > 2 );

  my ($action, $u1, $u2, $u3);
  ($u1, $u2, $u3) = $u_level =~ /^\*(\d{2,2})(?:(\d{2,2})(\d{2,2})?)?$/;

  if ( defined $u3 ) {
    return unless ( $u_default );  $action = 3;
  } elsif ( defined $u2 ) {
    return if ( $u_default );      $action = 2;
  } elsif ( defined $u1 ) {
    return unless ( $u1 eq '00' ); $action = 1;
  } else {
    return;                        $action = 0;
  }

  foreach my $prerequisite ( @prerequisites ) {
    my ($level, $default) = ( @{$prerequisite}[0], @{$prerequisite}[4] );
    if ( $action == 1 and $u_level eq $level ) { @{$prerequisite}[4] = 2; last; }
    next if ( $default >= 2 );

    if ( $u_level ne $level ) {
      if ( $u_default ) {
        next unless ( $action == 3 and length($u_level) == 7 and length($level) == 5 and $u_level =~ /^$level/ );
      } else {
        next unless ( $action == 2 and length($u_level) == 5 and length($level) == 7 and $level =~ /^$u_level/ );
      }
    }

    @{$prerequisite}[4] = $u_default;
  }
}

# Initialize the entire prerequisites table
foreach my $prerequisites ( @prerequisites ) { update_prerequisites_table( @$prerequisites[0], @$prerequisites[4] ); }

my $proceed = 0;

do {
  print "\n". generate_PREREQ_PM_table() ."\n";
  $proceed = ( $prompt ? ExtUtils::MakeMaker::prompt( "Do you want to proceed with this configuration?" => 'yes' ) =~ /^\s*y/i : 1 );
  print "\nActivate test:\n" if ($proceed);
  %PREREQ_PM = ();

  foreach my $prerequisite ( @prerequisites ) {
    my ($level, $feature, $dependency, $modules, $default) = @{$prerequisite}[0..4];
    next unless ( $dependency ne '' );

    unless ( $proceed || $default >= 2 ) {
      $default = ( ( ExtUtils::MakeMaker::prompt( "Do you plan to use ${feature}?" => ( $default ? 'yes' : 'no' ) ) =~ /^\s*(y)/i ) ? 1 : 0 );
      @{$prerequisite}[4] = $default;
    }

    update_prerequisites_table( $level, $default );

    if ( $proceed and ( $default == 1 || $default == 2 ) ) {
      if ( $dependency =~ /^ASNMTAP::Asnmtap::/ ) {
        my $t = uc($');
        $t =~ s/::/_/g;
        my $enabled = 't/'. $t .'_ENABLED';
        open (ENABLED, ">$enabled") or die "- activate test '$enabled' failed: $!\n";
        close (ENABLED);
        print "- activated test: '$enabled'\n";
      }

      foreach ( keys %$modules ) {
        my $version = $modules->{$_};
        next if ( $version =~ /^\*\d{2,2}(?:\d{2,2}(?:\d{2,2})?)?$/ );
        $PREREQ_PM{$_} = $version unless ( defined $PREREQ_PM{$_} and $PREREQ_PM{$_} >= $version );
      }
    }
  }
} while (! $proceed);

print "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ( $ASNMTAP_PLUGINS or $ASNMTAP_APPLICATIONS ) {
  foreach my $prerequisite ( @prerequisites ) {
    my ($feature, $default, $files) = ( @{$prerequisite}[1], @{$prerequisite}[4..5] );

    if ( $default == 1 || $default == 2 ) {
      if ( defined $files ) {
        foreach ( @$files ) {
          my $file  = @$_[0];
          my $mode  = @$_[1];
          my @files = glob($file);

          foreach my $file (@files) {
            my $destination = ( $file =~ /^\// ? $file : $ASNMTAP_PATH .'/'. $file );
            $destination .= '-orig' if ( $mode =~ /^[RX]$/ );
            $file = substr($file, 1) if ( $file =~ /^\// );

            if ( $mode =~ /^[dD]$/ ) {
              $file .= '/.exists';
			        $destination .= '/.exists';
            }

            $PM{$file} = $destination;
          }
        }
      }
    }
  }

  print "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ( $PERL_AUTOINSTALL ) {
  my ($module, $version, $installed);
  $module    = 'Module::AutoInstall';
  $version   = '1.03';
  $installed = eval ( "require $module; Exporter::require_version ( '$module', $version );" );

  if ( $installed ) {
    print "\nAutomatic install of dependencies via CPAN\n";

    eval ( "
       use Module::AutoInstall ( -config => { force => 1, do_once => 1 } ); 
       Module::AutoInstall->install( [], %PREREQ_PM );
    " );

    print "\n";
  } else {
    print "\n$module required for automatic install of dependencies via CPAN\n";
    print "\nperl -MCPAN -e 'install $module'\n\n";
  }
}

# Ok, now it is time to really generate the Makefile  - - - - - - - - - -

# my $ac = ExtUtils::Autoconf->new;
# $ac->configure;

WriteMakefile(
  NAME              => 'ASNMTAP',
  AUTHOR            => "alex.peeters\@citap.be",
  ABSTRACT          => "Application System Network Monitoring Toolkit Alex Peeters",
  VERSION           => $VERSION,
  LICENSE           => 'perl',
  PM                => \%PM,
  MAN3PODS          => { map { my $man3pod = $_; $man3pod =~ s/\//::/g; ("lib/ASNMTAP/$_.pod" => "\$(INST_MAN3DIR)/ASNMTAP::$man3pod.\$(MAN3EXT)") } @man3pods },
  PREREQ_PM         => \%PREREQ_PM,
  ($] >= 5.005 ?
    (ABSTRACT       => 'Application System Network Monitoring Toolkit Alex Peeters',
     AUTHOR         => 'Alex Peeters <alex.peeters@citap.com>') : ()
    ),
  'dist'            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
# 'dist'            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', PREOP => q{$(PERLRUN) -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_autogen'} },
);


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

package MY;

# What happens when we say 'make ...' - - - - - - - - - - - - - - - - - -

# sub postamble {
#   return <<"EOM";
# autogen :
# \t\$(PERLRUN) -MExtUtils::Autoconf -e 'ExtUtils::Autoconf->run_autogen'

# configure :
# \t\$(PERLRUN) -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_configure'

# autoclean :
# \t\$(PERLRUN) -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_realclean'

# realclean purge ::
# \t\$(PERLRUN) -MExtUtils::Autoconf -e 'ExtUtils::Autoconf->run_realclean'

# clean ::
# \t\$(PERLRUN) -MExtUtils::Autoconf -e 'ExtUtils::Autoconf->run_clean'
# EOM
# }

# What happens when we say 'make test'  - - - - - - - - - - - - - - - - -

sub test {
  q(
TEST_VERBOSE=0

test: all
	$(FULLPERL) t/TEST $(TEST_VERBOSE)
  );
}

# Determine things that should *not* be installed - - - - - - - - - - - -

sub libscan {
  my ($self, $path) = @_;

  return '' if $path =~ m:\betc\/:;
  return '' if $path =~ m:\busr\/:;
  return '' if $path =~ m:\bCVS\/:;
  $path;
}

# Pass ASNMTAP version number to pod2man  - - - - - - - - - - - - - - - -

sub manifypods {
  my $self = shift;

  my $version = $self->{VERSION} || $VERSION;
  local ($_) = $self->SUPER::manifypods(@_);
  s/pod2man\s*$/pod2man --release ASNMTAP-$version/m;
  $_;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
