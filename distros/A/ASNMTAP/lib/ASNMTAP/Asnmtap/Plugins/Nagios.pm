# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Asnmtap::Plugins::Nagios Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

# Class name  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
package ASNMTAP::Asnmtap::Plugins::Nagios;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

no warnings 'deprecated';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(carp);
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS :COMMANDS :_HIDDEN);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Plugins::Nagios::ISA         = qw(Exporter ASNMTAP::Asnmtap::Plugins);

  %ASNMTAP::Asnmtap::Plugins::Nagios::EXPORT_TAGS = (ALL       => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO
                                                                       $CAPTUREOUTPUT
                                                                       $PREFIXPATH $PLUGINPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                                       %ERRORS %STATE %TYPE

                                                                       $CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND

                                                                       &convert_to_KB &convert_from_KB_to_metric ) ],

                                                      NAGIOS   => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO
                                                                       $CAPTUREOUTPUT
                                                                       $PREFIXPATH $PLUGINPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                                       %ERRORS %STATE %TYPE

                                                                       &convert_to_KB &convert_from_KB_to_metric ) ],

                                                      COMMANDS => [ qw($CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND) ] );

  @ASNMTAP::Asnmtap::Plugins::Nagios::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Plugins::Nagios::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Plugins::Nagios::VERSION     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub convert_to_KB;
sub convert_from_KB_to_metric;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs without TAGS  = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub convert_to_KB {
  my ($metric, $value) = @_;

  my $result = ( ($metric =~ /^[Gg]$/) ? ($value * (1024 * 1024)) : ( ($metric =~ /^[Mm]$/) ? ($value * 1024) : $value ) );
  return ( $result )
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub convert_from_KB_to_metric {
  my ($metric, $value) = @_;

  my $result = ( ($metric eq 'GB') ? ($value / (1024 * 1024)) : ( ($metric eq 'MB') ? ($value / 1024) : $value ) );
  $result = sprintf("%.2f", $result) if ($metric ne 'kB');
  return ( $result )
}

# Constructor & initialisation  - - - - - - - - - - - - - - - - - - - - -

sub _init {
  $_[0]->SUPER::_init($_[1]);
  carp ('ASNMTAP::Asnmtap::Plugins::Nagios: _init') if ( $_[0]->{_debug} );

  $_[0]->{_programUsageSuffix} = ' [-o|--ostype <OSTYPE>] [-m|--metric <METRIC>] '. $_[0]->{_programUsageSuffix};

  $_[0]->{_programHelpSuffix} = "
-o, --ostype=<OSTYPE>
-m, --metric=<k|M|G>,
  k=kB (default), M=MB or G=GB
" . $_[0]->{_programHelpSuffix};

  push (@{ $_[0]->{_programGetOptions} }, 'ostype|o:s', 'metric|m:s');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _getOptions {
  $_[0]->SUPER::_getOptions();
  carp ('ASNMTAP::Asnmtap::Plugins::Nagios: _getOptions') if ( $_[0]->{_debug} );

  my $osType = ( exists $_[0]->{_getOptionsArgv}->{ostype} ) ? $_[0]->{_getOptionsArgv}->{ostype} : undef;
  $osType = ( defined $osType ? $osType : ( defined $^O ? $^O : 'Linux' ) );

  my $osVersion = ( exists $_[0]->{_getOptionsArgv}->{osversion} ) ? $_[0]->{_getOptionsArgv}->{osversion} : undef;

  for ( $osType ) {
    /aix/i                   && do { $osType = 'AIX';     last; };
    /cygwin/i                && do { $osType = 'Cygwin';  last; };
    /freebsd/i               && do { $osType = 'FreeBSD'; last; };
    /linux/i                 && do { $osType = 'Linux';   last; };
    /hp-ux/i                 && do { $osType = 'HP-UX';   last; };
    /irix/i                  && do { $osType = 'Irix';    last; };
    /macos/i                 && do { $osType = 'MacOS';   last; };
    /(?:FreeMiNt|MiNT)/i     && do { $osType = 'MiNT';    last; };
    /netbsd/i                && do { $osType = 'NetBSD';  last; };
    /netware/i               && do { $osType = 'NetWare'; last; };
    /openbsd/i               && do { $osType = 'OpenBSD'; last; };
    /os2/i                   && do { $osType = 'OS2';     last; };
    /sco/i                   && do { $osType = 'SCO';     last; };
    /solaris/i               && do { $osType = 'Solaris'; last; };
    /stratus/i               && do { $osType = 'Stratus'; last; };
    /unix/i                  && do { $osType = 'Unix';    last; };
    /vms/i                   && do { $osType = 'VMS';     last; };
    /mswin32/i               && do { $osType = 'Win32';   last; };
  }

  $_[0]->{_getOptionsValues}->{osType}    = $osType;
  $_[0]->{_getOptionsValues}->{osVersion} = $osVersion;

  my $metric = (exists $_[0]->{_getOptionsArgv}->{metric}) ? $_[0]->{_getOptionsArgv}->{metric} : 'kB';
  $_[0]->printUsage ('Invalid metric option: '. $metric) unless ($metric =~ /^k|M|G$/);
  $_[0]->{_getOptionsValues}->{metric} = ($metric eq 'M') ? 'MB' : ($metric eq 'G') ? 'GB' : 'kB';
}

# Object accessor methods - - - - - - - - - - - - - - - - - - - - - - - -

# Class accessor methods  - - - - - - - - - - - - - - - - - - - - - - - -

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Destructor  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub DESTROY {
  print (ref ($_[0]), "::DESTROY: ()\n") if ( $_[0]->{_debug} );
  $_[0]->SUPER::DESTROY;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Nagios provides a nice object oriented interface for building Nagios (http://www.nagios.org) compatible plugins.

=head1 Description

ASNMTAP::Asnmtap::Plugins::Nagios Subclass of ASNMTAP::Asnmtap::Plugins

=head1 SEE ALSO

ASNMTAP::Asnmtap, ASNMTAP::Asnmtap::Plugins

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
