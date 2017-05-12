#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_nagiosv3-comments-cleanup.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $echo        = 1;
my $cleanupChar = '\*';   # we don't cleanup comments that start with ...

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.002.003;
use ASNMTAP::Time qw(&get_datetimeSignal);

use ASNMTAP::Asnmtap::Applications v3.002.003;
use ASNMTAP::Asnmtap::Applications qw(&sending_mail $SERVERLISTSMTP $SENDMAILFROM);

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS $SENDEMAILTO);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectAsnmtap = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_nagiosv3-comments-cleanup.pl',
  _programDescription => 'Nagios v3.x Comments Cleanup',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[--nagiosPath <nagios path>] [--statusFile <status file>] [--commandFile <command file>] [-E|--email <boolean>]',
  _programHelpPrefix  => "--nagiosPath=<nagios path>
--statusFile=<status file>
--commandFile=<command file>
-E, --email=<boolean>
    BOOLEAN: 0 = FALSE and 1 = TRUE",
  _programGetOptions  => ['nagiosPath:s', 'statusFile:s', 'commandFile:s', 'email|E:f'],
  _timeout            => 30,
  _debug              => 0);

my $nagiosPath = $objectAsnmtap->getOptionsArgv ('nagiosPath');
$nagiosPath = '/opt/monitoring/nagios' unless ( defined $nagiosPath );

my $statusFile = $objectAsnmtap->getOptionsArgv ('statusFile');
$statusFile = '/var/status.dat' unless ( defined $statusFile );
$statusFile = $nagiosPath . $statusFile;

my $commandFile = $objectAsnmtap->getOptionsArgv ('commandFile');
$commandFile = '/var/rw/nagios.cmd' unless ( defined $commandFile );
$commandFile = $nagiosPath . $commandFile;

my $email = $objectAsnmtap->getOptionsArgv ('email');

if ( defined $email ) {
  $objectAsnmtap->printUsage ('Invalid email value!') unless ($email =~ /^0|1$/);
} else {
  $email = 0;
}

my $debug = $objectAsnmtap->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

unless (-e "$statusFile") {
  $objectAsnmtap->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "The file '$statusFile' doesn't exist!" }, $TYPE{APPEND} );
  $objectAsnmtap->exit (7);
}

system ("rm \"$statusFile-cleanup\"");
system ("cp \"$statusFile\" \"$statusFile-cleanup\"");
$statusFile .= '-cleanup';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my %statusHost    = ();
my %statusService = ();
my ($cleanupList, $message);
my $returnCode = parse_nagios_status_file (\$objectAsnmtap, $statusFile, \$cleanupList, \$message, $debug);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ($email and defined $message) {
  my $subject = 'Nagios Comment Cleanup: '. get_datetimeSignal();

  unless ( sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $message, $debug ) ) {
    $objectAsnmtap->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Problem sending email to the System Administrators" }, $TYPE{APPEND} );
    $objectAsnmtap->exit (7);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectAsnmtap->pluginValues ( { stateValue => $ERRORS{OK}, alert => ( defined $cleanupList ? 'LIST: +'. $cleanupList : 'DONE' ) }, $TYPE{APPEND} );
$objectAsnmtap->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub parse_nagios_status_file {
  my ($objectInherited, $filename, $cleanupList, $message, $debug) = @_;

  unless (-e "$filename") {
    $$objectInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "The file '$filename' doesn't exist!" }, $TYPE{APPEND} );
    $$objectInherited->exit (7);
  }

  my $rvOpen = open(READ, "$filename");

  unless ($rvOpen) {
    $$objectInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Can't open '$filename' file!" }, $TYPE{APPEND} );
    $$objectInherited->exit (7);
  }

  my ($startBlok, $endBlok, $statusBlok, $commentBlok) = (0, 0, 0, 0);
  my %status = ();

  while (<READ>) {
    s/(^\s*|\r*|\n*|\s*$)//g;
    next if ( ! $_ or $_ =~ /^#/ );
    my $line = $_;

    unless ($startBlok) {
      if ($line =~ /^\s*(?:hoststatus|servicestatus)\s*{\s*$/i) {
        $startBlok = $statusBlok = 1;
        $commentBlok = 0;
      } elsif ($line =~ /^\s*(?:hostcomment|servicecomment)\s*{\s*$/i) {
        $startBlok = $commentBlok = 1;
        $statusBlok = 0;
      }
    } elsif (! $endBlok) {
      unless ($line =~ /^\s*}\s*$/i) {
        my ($label, $value) = split (/=/, $line, 2);
        $label =~ s/(^\s*|\s*$)//g;
        $value =~ s/(^\s*|\s*$)//g if (defined $value);
        $status{$label} = $value;
      } else {
        $endBlok = 1;
      }
    }

    if ($startBlok and $endBlok) {
      if ( $statusBlok ) {
        if ($debug) {
          ( exists $status{service_description} ) ? print "servicestatus {\n" : print "hoststatus {\n";
          foreach my $label ( sort keys ( %status ) ) { print "  $label = ". $status{$label} ."\n"; }
          print "}\n\n";
        }

        if ( (! $status{current_state}) and ($status{active_checks_enabled} or $status{passive_checks_enabled}) and (! $status{scheduled_downtime_depth}) ) {
          unless ( exists $status{service_description} ) {
            foreach ( keys ( %status ) ) { $statusHost{$status{host_name}}{$_} = $status{$_}; }
          } else {
            foreach ( keys ( %status ) ) { $statusService{$status{host_name}}{$status{service_description}}{$_} = $status{$_}; }
          }
        }
      } elsif ( $commentBlok ) {
        if ($debug) {
          ( exists $status{service_description} ) ? print "servicecomment {\n" : print "hostcomment {\n";
          foreach my $label ( sort keys ( %status ) ) { print "  $label = ". $status{$label} ."\n"; }
          print "}\n\n";
        }

        if ( ! ($status{expires} + $status{expire_time}) and $status{author} ne '(Nagios Process)' and $status{comment_data} !~ /^$cleanupChar\s+/ ) {
          unless ( exists $status{service_description} ) {
            if (exists $statusHost{$status{host_name}}) {
              writeNagiosCmd ( 'DEL_HOST_COMMENT', $status{comment_id}, $cleanupList, $message, $debug );

              if ( $email ) {
                $$message .= 'Host       : '. $status{host_name} ."\n";
                $$message .= 'Entry Type : '. $status{entry_type} ."\n";
                $$message .= 'Comment ID : '. $status{comment_id} ."\n";
                $$message .= 'Source     : '. $status{source} ."\n";
                $$message .= 'Persistent : '. $status{persistent} ."\n";
                $$message .= 'Entry Time : '. $status{entry_time} ."\n";
                $$message .= 'Expires    : '. $status{expires} ."\n";
                $$message .= 'Expire Time: '. $status{expire_time} ."\n";
                $$message .= 'Author     : '. $status{author} ."\n";
                $$message .= 'Comment    : '. $status{comment_data} ."\n\n";
              }
            }
          } else {
            if (exists $statusService{$status{host_name}}{$status{service_description}}) {
              writeNagiosCmd ( 'DEL_SVC_COMMENT', $status{comment_id}, $cleanupList, $message, $debug );

              if ( $email ) {
                $$message .= 'Host       : '. $status{host_name} ."\n";
                $$message .= 'Service    : '. $status{service_description} ."\n";
                $$message .= 'Entry Type : '. $status{entry_type} ."\n";
                $$message .= 'Comment ID : '. $status{comment_id} ."\n";
                $$message .= 'Source     : '. $status{source} ."\n";
                $$message .= 'Persistent : '. $status{persistent} ."\n";
                $$message .= 'Entry Time : '. $status{entry_time} ."\n";
                $$message .= 'Expires    : '. $status{expires} ."\n";
                $$message .= 'Expire Time: '. $status{expire_time} ."\n";
                $$message .= 'Author     : '. $status{author} ."\n";
                $$message .= 'Comment    : '. $status{comment_data} ."\n\n";
              }
            }
          }
        }
      }

      %status = ();
      $startBlok = $endBlok = $statusBlok = $commentBlok = 0;
    } elsif (! $startBlok and $endBlok) {
      $$objectInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "import problem with '$filename' file!" }, $TYPE{APPEND} );
      $$objectInherited->exit (7);
    }
  }

  close(READ);
  return (0);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub writeNagiosCmd {
  my ($command, $comment_id, $cleanupList, $message, $debug) = @_;

  my $nagiosCmd = '['. time() .'] '. $command .';'. $comment_id;
  $$cleanupList .= $comment_id .'+';
  $$message .= $nagiosCmd ."\n\n" if ( $email );

  if ( $debug ) {
    print "$nagiosCmd\n";
  } else {
    if ( $echo ) {
      system ("echo \"$nagiosCmd\" > $commandFile");
    } else {
      open(NAGIOSHEAP, "> $commandFile") || die "Cannot append: $!";
        print NAGIOSHEAP "$nagiosCmd\n";
      close(NAGIOSHEAP);
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

