## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Logger.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA::CAB logging (using Log::Log4perl)

package DTA::CAB::Logger;
use DTA::CAB::Utils ':profile';
use Carp;
use Log::Log4perl;
use File::Basename;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw();

our ($MIN_LEVEL);       ##-- minimum log level
our (%defaultLogOpts);  ##-- default log options
BEGIN {
  $MIN_LEVEL = $Log::Log4perl::Level::LEVELS{(sort {$a<=>$b} keys(%Log::Log4perl::Level::LEVELS))[0]};
  %defaultLogOpts =
      (
       l4pfile   => undef, ##-- formerly $logConfigFile
       watch     => undef, ##-- watch l4pfile (undef or secs)?
       rootLevel => ($^W ? 'WARN' : 'FATAL'),
       twLevel   => 'INFO', ##-- log level for DTA::TokWrap (used by DTA::CAB::Format::TEI)
       level     => ($^W ? $MIN_LEVEL : 'INFO'),
       stderr    => 1,
       logdate   => 0,
       logtime   => 0,
       file      => undef,
       rotate    => undef, ##-- default: haveFileRotate()
       syslog    => 0,
       sysLevel  => ($^W ? 'debug' : 'info'),
       sysName   => File::Basename::basename($0),
       sysIdent  => undef,     ##-- default=$opts{sysName}
       sysFacility => ($0 =~ m/(?:server|daemon)/i ? 'daemon' : 'user'),
      );
}

## $DEFAULT_LOG_CONF = PACKAGE->defaultLogConf(%opts)
##  + default configuration for Log::Log4perl
##  + see Log::Log4perl(3pm), Log::Log4perl::Config(3pm) for details
##  + %opts:
##     rootLevel => $LEVEL_OR_UNDEF,  ##-- min root log level (default='WARN' or 'FATAL', depending on $^W)
##     level     => $LEVEL_OR_UNDEF,  ##-- min log level (default=$MIN_LEVEL or 'INFO', depending on $^W)
##     stderr    => $bool,            ##-- whether to log to stderr (default=1)
##     logtime   => $bool,            ##-- whether to log time-stamps on stderr (default=0)
##     logdate   => $bool,            ##-- whether to log date+time-stamps on stderr (default=0)
##     file      => $filename,        ##-- log to $filename if true
##     rotate    => $bool,            ##-- use Log::Dispatch::FileRotate if available and $filename is true
##     syslog    => $bool,            ##-- use Log::Dispatch::Syslog if available and true (default=false)
##     sysLevel  => $level,           ##-- minimum level for syslog (default='debug' or 'info', depending on $^W)
##                                    ##   : available levels: debug,info,notice,warning,error,critical,alert,emergency (== 0..7)
##     sysName   => $sysName,         ##-- name for syslog (default=basename($0))
##     sysIdent  => $sysIdent,        ##-- ident string for syslog (default=$sysName)
##     sysFacility => $facility,      ##-- facility for syslog (default='daemon')
sub defaultLogConf {
  my ($that,%opts) = @_;
  %opts = (%defaultLogOpts,%opts);
  $opts{rotate}   = haveFileRotate() if (defined($opts{file}) && !defined($opts{rotate}));
  $opts{sysIdent} = $opts{sysName}   if (!defined($opts{sysIdent}));


  ##-- generate base config
  my $cfg = "
##-- Loggers
log4perl.oneMessagePerAppender = 1     ##-- suppress duplicate messages to the same appender
";

  if ($opts{rootLevel} && $opts{rootLevel} ne 'OFF') {
    ##-- root logger
    $cfg .= "log4perl.rootLogger = $opts{rootLevel}, AppStderr\n";
  }

  if ($opts{stderr} || $opts{file} || $opts{syslog}) {
    ##-- tokwrap logger
    $cfg .= "log4perl.logger.DTA.TokWrap = $opts{twLevel}, ".join(", ",
								  ($opts{stderr} ? 'AppStderr' : qw()),
								  ($opts{file}   ? 'AppFile'   : qw()),
								  ($opts{syslog} ? 'AppSyslog' : qw()),
								 )."\n"
								   if ($opts{twLevel});
    ##-- local package logger
    $cfg .= "log4perl.logger.DTA.CAB = $opts{level}, ".join(", ",
							    ($opts{stderr} ? 'AppStderr' : qw()),
							    ($opts{file}   ? 'AppFile'   : qw()),
							    ($opts{syslog} ? 'AppSyslog' : qw()),
							   )."\n"
							     if ($opts{level});

    ##-- avoid duplicate messages
    $cfg .= "log4perl.additivity.DTA = 0\n";
  }

  ##-- appenders: utils
  $cfg .= "
##-- Appenders: Utilities
log4perl.PatternLayout.cspec.G = sub { return File::Basename::basename(\"$::0\"); }
";

  ##-- appender: stderr
  my $stderr_date = ($opts{logdate} ? '%d{yyyy-MM-dd HH:mm:ss} '
		     : ($opts{logtime} ? '%d{HH:mm:ss} ' : ''));
  $cfg .= "
##-- Appender: AppStderr
log4perl.appender.AppStderr = Log::Log4perl::Appender::Screen
log4perl.appender.AppStderr.stderr = 1
log4perl.appender.AppStderr.binmode = :utf8
log4perl.appender.AppStderr.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.AppStderr.layout.ConversionPattern = ${stderr_date}%G[%P] %p: %c: %m%n
";

  ##-- appender: syslog
  if ($opts{syslog}) {
    eval 'use Log::Dispatch::Syslog;';
    die "could not use Log::Dispatch::Syslog: $@" if ($@);
    $cfg .= "
log4perl.appender.AppSyslog = Log::Dispatch::Syslog
log4perl.appender.AppSyslog.name = $opts{sysName}
log4perl.appender.AppSyslog.ident = $opts{sysIdent}
log4perl.appender.AppSyslog.min_level = $opts{sysLevel}
log4perl.appender.AppSyslog.facility = $opts{sysFacility}
log4perl.appender.AppSyslog.logopt = pid
log4perl.appender.AppSyslog.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.AppSyslog.layout.ConversionPattern = (%p) %c: %m%n
";
  }

  if ($opts{file} && $opts{rotate}) {
    ##-- rotating file appender
    eval 'use Log::Dispatch::FileRotate;';
    die "could not use Log::Dispatch::FileRotate: $@" if ($@);
    $cfg .= "
##-- Appender: AppFile: rotating file appender
log4perl.appender.AppFile = Log::Dispatch::FileRotate
log4perl.appender.AppFile.min_level = debug
log4perl.appender.AppFile.filename = $opts{file}
log4perl.appender.AppFile.binmode = :utf8
log4perl.appender.AppFile.mode = append
log4perl.appender.AppFile.size = 10485760
log4perl.appender.AppFile.max  = 10
log4perl.appender.AppFile.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.AppFile.layout.ConversionPattern = %d{yyyy-MM-dd HH:mm:ss} [%P] (%p) %c: %m%n
";
  }
  elsif ($opts{file}) {
    ##-- raw file appender
    $cfg .= "
##-- Appender: AppFile: raw file appender (no automatic log rotation)
log4perl.appender.AppFile = Log::Log4perl::Appender::File
log4perl.appender.AppFile.filename = $opts{file}
log4perl.appender.AppFile.mode = append
log4perl.appender.AppFile.utf8 = 1
log4perl.appender.AppFile.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.AppFile.layout.ConversionPattern = %d{yyyy-MM-dd HH:mm:ss} [%P] (%p) %c: %m%n
";
  }

  #print STDERR "$cfg\n"; ##--debug
  return $cfg;
}

## $bool = CLASS::haveFileRotate()
##  + returns true if Log::Dispatch::FileRotate is available
sub haveFileRotate {
  return 1 if (defined($Log::Dispatch::FileRotate::VERSION));
  eval "use Log::Dispatch::FileRotate;";
  return 1 if (defined($Log::Dispatch::FileRotate::VERSION) && !$@);
  $@='';
  return 0;
}

## $bool = CLASS::haveSyslog()
##  + returns true if Log::Dispatch::Syslog is available
sub haveSyslog {
  return 1 if (defined($Log::Dispatch::Syslog::VERSION));
  eval "use Log::Dispatch::Syslog;";
  return 1 if (defined($Log::Dispatch::Syslog::VERSION) && !$@);
  $@='';
  return 0;
}

##==============================================================================
## Functions: Initialization
##==============================================================================

## undef = PACKAGE->logInit(%opts)  ##-- use default configuration with %opts
##  + %opts: see defaultLogConf()
##  + all log calls in the DTA::CAB namespace should use a subcategory of 'DTA::CAB'
##  + only needs to be called once; see Log::Log4perl->initialized()
sub logInit {
  my $that = shift;
  my %opts = (%defaultLogOpts,@_);
  binmode(\*STDERR,':utf8');
  if (!defined($opts{l4pfile})) {
    my $confstr = $that->defaultLogConf(%opts);
    Log::Log4perl::init(\$confstr);
  } else {
    eval 'use Log::Dispatch::Syslog;';
    eval 'use Log::Dispatch::FileRotate;';
    if (defined($opts{watch})) {
      Log::Log4perl::init_and_watch($opts{l4pfile},$opts{watch});
    } else {
      Log::Log4perl::init($opts{l4pfile});
    }
  }
  #__PACKAGE__->info("initialized logging facility");
}

## undef = PACKAGE->ensureLog(@args)        ##-- ensure a Log::Log4perl has been initialized
sub ensureLog {
  my $that = shift;
  $that->logInit(@_) if (!Log::Log4perl->initialized);
}

##==============================================================================
## Methods: get logger
##==============================================================================

## $logger = $class_or_obj->logger()
## $logger = $class_or_obj->logger($category)
##  + wrapper for Log::Log4perl::get_logger($category)
##  + $category defaults to ref($class_or_obj)||$class_or_obj
sub logger { Log::Log4perl::get_logger(ref($_[0])||$_[0]); }

##==============================================================================
## Methods: messages
##==============================================================================

## undef = $class_or_obj->trace(@msg)
##   + be sure you have called Log::Log4perl::init() or similar first
##     - e.g. DTA::CAB::Logger::logInit()
sub trace { $_[0]->logger->trace(@_[1..$#_]); }
sub debug { $_[0]->logger->debug(@_[1..$#_]); }
sub info  { $_[0]->logger->info(@_[1..$#_]); }
sub warn  { $_[0]->logger->warn(@_[1..$#_]); }
sub error { $_[0]->logger->error(@_[1..$#_]); }
sub fatal { $_[0]->logger->fatal(@_[1..$#_]); }

## undef = $class_or_obj->llog($level, @msg)
##  + $level is some constant exported by Log::Log4perl::Level
sub llog { $_[0]->logger->log(@_[1..$#_]); }

## undef = $class_or_obj->vlog($methodname_or_coderef_or_undef, @msg)
##  + calls $methodname_or_coderef_or_undef($class_or_obj,@msg) if defined
##  + e.g. $class_or_obj->vlog('trace', @msg)
sub vlog {
  return if (!defined($_[1]));
  my $sub = UNIVERSAL::isa($_[1],'CODE') ? $_[1] : (UNIVERSAL::can($_[0],$_[1]) || UNIVERSAL::can($_[0],lc($_[1])));
  return if (!defined($sub));
  return $sub->($_[0],@_[2..$#_]);
}

##==============================================================================
## Methods: carp & friends
##==============================================================================

## undef = $class_or_obj->logcroak(@msg)
sub logwarn { $_[0]->logger->logwarn(@_[1..$#_]); }     # warn w/o stack trace
sub logcarp { $_[0]->logger->logcarp(@_[1..$#_]); }     # warn w/ 1-level stack trace
sub logcluck { $_[0]->logger->logcluck(@_[1..$#_]); }   # warn w/ full stack trace

sub logdie { $_[0]->logger->logdie(@_[1..$#_]); }         # die w/o stack trace
sub logcroak { $_[0]->logger->logcroak(@_[1..$#_]); }     # die w/ 1-level stack trace
sub logconfess { $_[0]->logger->logconfess(@_[1..$#_]); } # die w/ full stack trace


##==============================================================================
## Utils: Getopt::Long specification
##==============================================================================

## %getoptLongHash = $PACKAGE->cabLogOptions(%localOpts)
##  + %localOpts
##     verbose => $bool,   ##-- if true, add 'verbose|v' as alias for 'log-level'
##  + adds support for logging options:
##    'log-level|loglevel|ll|L=s' => \$defaultLogOpts{level},
##    'log-config|logconfig|log4perl-config|l4p-config|l4p=s' => \$defaultLogOpts{l4pfile},
##    'log-watch|logwatch|watch|lw=s' => \$defaultLogOpts{watch},
##    'nolog-watch|nologwatch|nowatch|nolw' => sub { $defaultLogOpts{watch}=undef; },
##    'log-stderr|stderr|lse!' => \$defaultLogOpts{stderr},
##    'log-file|lf=s' => \$defaultLogOpts{file},
##    'nolog-file|nolf' => sub { $defaultLogOpts{file}=undef; },
##    'log-rotate|rotate|lr!' => \$defaultLogOpts{rotate},
##    'log-syslog|syslog|ls!' => \$defaultLogOpts{syslog},
##    'log-option|logopt|lo=s' => \%defaultLogOpts,
sub cabLogOptions {
  my ($that,%opts) = @_;
  return
    (##-- Logging Options
     ($opts{verbose} ? ('verbose|v=s' => sub { $defaultLogOpts{level}=uc($_[1]); }) : qw()),
     'log-level|loglevel|ll|L=s'  => sub { $defaultLogOpts{level}=uc($_[1]); },
     'log-config|logconfig|log4perl-config|l4p-config|l4p=s' => \$defaultLogOpts{l4pfile},
     'log-watch|logwatch|watch|lw=s' => \$defaultLogOpts{watch},
     'nolog-watch|nologwatch|nowatch|nolw' => sub { $defaultLogOpts{watch}=undef; },
     'log-stderr|stderr|lse!' => \$defaultLogOpts{stderr},
     'log-file|lf=s' => \$defaultLogOpts{file},
     'nolog-file|nolf' => sub { $defaultLogOpts{file}=undef; },
     'log-rotate|rotate|lr!' => \$defaultLogOpts{rotate},
     'log-syslog|syslog|ls!' => \$defaultLogOpts{syslog},
     'log-option|logopt|lo=s%' => \%defaultLogOpts,
    );
}

##==============================================================================
## Utils: Profiling
##==============================================================================

## undef = $logger->logProfile($level, $elapsed_secs, $ntoks, $nchrs)
sub logProfile {
  $_[0]->vlog($_[1], profile_str(@_[2..$#_]));
}


1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl and edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Logger - DTA::CAB logging facility using Log::Log4perl

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Logger;
 
 ##========================================================================
 ## Gobals
 
 $DTA::CAB::Logger::defaultLogOpts{$opt} = $val;
 $DTA::CAB::Logger::MIN_LEVEL = $min_log_level;
 
 ##========================================================================
 ## Functions: Initialization
 
 DTA::CAB::Logger->logInit(%opts);
 DTA::CAB::Logger->ensureLog(%opts);
 $DEFAULT_LOG_CONF = DTA::CAB::Logger->defaultLogConf(%opts)
 $bool = $CLASS_OR_OJECT->logInitialized();
 
 ##========================================================================
 ## Methods: get logger
 
 $logger = $class_or_obj->logger();
 
 ##========================================================================
 ## Methods: messages
 
 $class_or_obj->trace (@msg);  ##-- 'TRACE'-level message
 $class_or_obj->debug (@msg);  ##-- 'DEBUG'-level message
 $class_or_obj->info  (@msg);  ##-- 'INFO'-level message
 $class_or_obj->warn  (@msg);  ##-- 'WARN'-level message
 $class_or_obj->error (@msg);  ##-- 'ERROR'-level message
 $class_or_obj->fatal (@msg);  ##-- 'FATAL'-level message
 
 $class_or_obj->llog($level, @msg);  ##-- variable-level message (numeric)
 $class_or_obj->vlog($how,   @msg);  ##-- variable-level message (symbolic)
 
 ##========================================================================
 ## Methods: carp, croak & friends
 
 $class_or_obj->logwarn  (@msg);   ##-- warn w/o stack trace
 $class_or_obj->logcarp  (@msg);   ##-- warn w/ 1-level stack trace
 $class_or_obj->logcluck (@msg);   ##-- warn w/ full stack trace
 
 $class_or_obj->logdie    (@msg);  ##-- die w/o stack trace
 $class_or_obj->logcroak  (@msg);  ##-- die w/ 1-level stack trace
 $class_or_obj->logconfess(@msg);  ##-- die w/ full stack trace

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Logger provides an abstract base class for
object-oriented access to the Log::Log4perl logging facility.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Logger: Globals
=pod

=head2 Globals

=over 4

=item $DTA::CAB::Logger::MIN_LEVEL

Minimum log level.  Default is minimum-keyed value in %LOG::Log4perl::Level::LEVELS if $^W
is set, otherwise 'INFO'.

=item %DTA::CAB::Logger::defaultLogOpts

Default logging options.  See defaultLogConf().

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Logger: Functions: Initialization
=pod

=head2 Functions: Initialization

=over 4

=item logInit

 $PACKAGE->logInit(%opts)

Initialize the logging facility.

%opts:

 l4pfile   => undef,            ##-- alternate Log4perl config file
 watch     => undef,            ##-- watch l4pfile (SECONDS delay or SIGNAL)? (default=undef: false)
 rootLevel => $LEVEL_OR_UNDEF,  ##-- min root log level (default='WARN' or 'FATAL', depending on $^W)
 level     => $LEVEL_OR_UNDEF,  ##-- min log level (default=$MIN_LEVEL or 'INFO', depending on $^W)
 stderr    => $bool,            ##-- whether to log to stderr (default=1)
 file      => $filename,        ##-- log to $filename if true
 rotate    => $bool,            ##-- use Log::Dispatch::FileRotate if available and $filename is true
 syslog    => $bool,            ##-- use Log::Dispatch::Syslog if available and true (default=false)
 sysLevel  => $level,           ##-- minimum level for syslog (default='debug' or 'info', depending on $^W)
                                ##   available levels: debug,info,notice,warning,error,critical,alert,emergency (== 0..7)
 sysName   => $sysName,         ##-- name for syslog (default=basename($0))
 sysIdent  => $sysIdent,        ##-- ident string for syslog (default=$sysName)
 sysFacility => $facility,      ##-- facility for syslog (default='daemon')

All log calls in the 'DTA::CAB' namespace should use a subcategory of 'DTA::CAB'.
This function only needs to be called once; see
L<Log::Log4perl-E<gt>initialized()|Log::Log4perl> for details.

=item ensureLog

 PACKAGE->ensureLog(%opts)

Ensures that L<Log::Log4perl|Log::Log4perl> has been initialized.

=item defaultLogConf

 $DEFAULT_LOG_CONF = PACKAGE->defaultLogConf(%opts)

Returns default L<Log::Log4perl|Log::Log4perl> configuration string for %opts.

=item logInitialized

 $bool = CLASS_OR_OBJECT->logInitialized();

Wrapper for L<Log::Log4perl|Log::Log4perl>-E<gt>initialized().

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Logger: Methods: get logger
=pod

=head2 Methods: get logger

=over 4

=item logger

 $logger = $class_or_obj->logger();
 $logger = $class_or_obj->logger($category)

Wrapper for L<Log::Log4perl|Log::Log4perl>::get_logger($category).

$category defaults to ref($class_or_obj)||$class_or_obj

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Logger: Methods: messages
=pod

=head2 Methods: messages

=over 4

=item trace

=item debug

=item info

=item warn

=item error

=item fatal

 $class_or_obj->trace (@msg);  ##-- 'TRACE'-level message
 $class_or_obj->debug (@msg);  ##-- 'DEBUG'-level message
 $class_or_obj->info  (@msg);  ##-- 'INFO'-level message
 $class_or_obj->warn  (@msg);  ##-- 'WARN'-level message
 $class_or_obj->error (@msg);  ##-- 'ERROR'-level message
 $class_or_obj->fatal (@msg);  ##-- 'FATAL'-level message

Log messages at an explicit log-level.

Be sure you have called L<Log::Log4perl|Log::Log4perl>::init() or similar first,
e.g. L<DTA::CAB::Logger::logInit()|/logInit>.


=item llog

 $class_or_obj->llog($level, @msg);

Log message @msg at log-level $level, which should be a (numeric)
constant exported by Log::Log4perl::Level.

=item vlog

 $class_or_obj->vlog($how, @msg);

Log message @msg at log-level $how, which may be one of the
following:

=over 4

=item *

a CODE reference (e.g. $how=\&logsub) will cause
$how-E<gt>($class_or_obj,@msg) to be called.

=item *

a method name (e.g. $how='trace') will case
calls $class_or_obj-E<gt>${how}(@msg) to be called.

=item *

anything else (e.g. $how='none', $how=undef, ...)
will be ignored.

=back

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Logger: Methods: carp & friends
=pod

=head2 Methods: carp, croak & friends

=over 4

=item logwarn

=item logcarp

=item logcluck

 $class_or_obj->logwarn  (@msg);   ##-- warn w/o stack trace
 $class_or_obj->logcarp  (@msg);   ##-- warn w/ 1-level stack trace
 $class_or_obj->logcluck (@msg);   ##-- warn w/ full stack trace

=item logdie

=item logcroak

=item logconfess

 $class_or_obj->logdie    (@msg);  ##-- die w/o stack trace
 $class_or_obj->logcroak  (@msg);  ##-- die w/ 1-level stack trace
 $class_or_obj->logconfess(@msg);  ##-- die w/ full stack trace

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
