#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_nagios-comments-cleanup.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $echo        = 1;
my $cleanupChar = '\*';   # we don't cleanup comments that start with ...

my $nagiosPath  = '/opt/monitoring/nagios';
my $statusFile  = $nagiosPath .'/var/status.dat';
my $commentFile = $nagiosPath .'/var/comments.dat';
my $commandFile = $nagiosPath .'/var/rw/nagios.cmd';

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
  _programName        => 'check_nagios-comments-cleanup.pl',
  _programDescription => 'Nagios v2.x Comments Cleanup',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[-E|--email <boolean>]',
  _programHelpPrefix  => "-E, --email=<boolean>
    BOOLEAN: 0 = FALSE and 1 = TRUE",
  _programGetOptions  => ['email|E:f'],
  _timeout            => 30,
  _debug              => 0);

my $email = $objectAsnmtap->getOptionsArgv ('email');

if ( defined $email ) {
  $objectAsnmtap->printUsage ('Invalid email value!') unless ($email =~ /^0|1$/);
} else {
  $email = 0 unless ( defined $email );
}

my $debug = $objectAsnmtap->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my %statusHost    = ();
my %statusService = ();
my $returnCode = parse_nagios_status_file (\$objectAsnmtap, $statusFile, $debug);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($cleanupList, $message);
$returnCode = process_nagios_comment_file (\$objectAsnmtap, $commentFile, \$cleanupList, \$message, $debug) unless ($returnCode);

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
  my ($objectInherited, $filename, $debug) = @_;

  unless (-e "$filename") {
    $$objectInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "The file '$filename' doesn't exist!" }, $TYPE{APPEND} );
    $$objectInherited->exit (7);
  }

  my $rvOpen = open(READ, "$filename");

  unless ($rvOpen) {
    $$objectInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Can't open '$filename' file!" }, $TYPE{APPEND} );
    $$objectInherited->exit (7);
  }

  my ($startBlok, $endBlok) = (0, 0);
  my %status = ();

  while (<READ>) {
    s/(^\s*|\r*|\n*|\s*$)//g;
    next if ( ! $_ or $_ =~ /^#/ );
    my $line = $_;

    unless ($startBlok) {
      $startBlok = 1 if ($line =~ /^\s*(?:host|service)\s*{\s*$/i);
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
      # if ($debug) {
      #   ( exists $status{service_description} ) ? print "service {\n" : print "host {\n";
      #   foreach my $label ( sort keys ( %status ) ) { print "  $label = ". $status{$label} ."\n"; }
      #   print "}\n\n";
      # }

      if ( (! $status{current_state}) and ($status{active_checks_enabled} or $status{passive_checks_enabled}) and (! $status{scheduled_downtime_depth}) ) {
        unless ( exists $status{service_description} ) {
          foreach ( keys ( %status ) ) { $statusHost{$status{host_name}}{$_} = $status{$_}; }
        } else {
          foreach ( keys ( %status ) ) { $statusService{$status{host_name}}{$status{service_description}}{$_} = $status{$_}; }
        }
      }

      %status = ();
      $startBlok = $endBlok = 0;
    } elsif (! $startBlok and $endBlok) {
      $$objectInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "import problem with '$filename' file!" }, $TYPE{APPEND} );
      $$objectInherited->exit (7);
    }
  }

  close(READ);
  return (0);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub process_nagios_comment_file {
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

  my ($startBlok, $endBlok) = (0, 0);
  my %comment = ();

  while (<READ>) {
    s/(^\s*|\r*|\n*|\s*$)//g;
    next if ( ! $_ or $_ =~ /^#/ );
    my $line = $_;

    unless ($startBlok) {
      $startBlok = 1 if ($line =~ /^\s*(?:hostcomment|servicecomment)\s*{\s*$/i);
    } elsif (! $endBlok) {
      unless ($line =~ /^\s*}\s*$/i) {
        my ($label, $value) = split (/=/, $line, 2);
        $label =~ s/(^\s*|\s*$)//g;
        $value =~ s/(^\s*|\s*$)//g if (defined $value);
        $comment{$label} = $value;
      } else {
        $endBlok = 1;
      }
    }

    if ($startBlok and $endBlok) {
      # if ($debug) {
      #   ( exists $comment{service_description} ) ? print "servicecomment {\n" : print "hostcomment {\n";
      #   foreach my $label ( sort keys ( %comment ) ) { print "  $label = ". $comment{$label} ."\n"; }
      #   print "}\n\n";
      # }

      if ( ! ($comment{expires} + $comment{expire_time}) and $comment{author} ne '(Nagios Process)' and $comment{comment_data} !~ /^$cleanupChar\s+/ ) {
        unless ( exists $comment{service_description} ) {
          if (exists $statusHost{$comment{host_name}}) {
            writeNagiosCmd ( 'DEL_HOST_COMMENT', $comment{comment_id}, $cleanupList, $message, $debug );

            if ( $email ) {
              $$message .= 'Host       : '. $comment{host_name} ."\n";
              $$message .= 'Entry Type : '. $comment{entry_type} ."\n";
              $$message .= 'Comment ID : '. $comment{comment_id} ."\n";
              $$message .= 'Source     : '. $comment{source} ."\n";
              $$message .= 'Persistent : '. $comment{persistent} ."\n";
              $$message .= 'Entry Time : '. $comment{entry_time} ."\n";
              $$message .= 'Expires    : '. $comment{expires} ."\n";
              $$message .= 'Expire Time: '. $comment{expire_time} ."\n";
              $$message .= 'Author     : '. $comment{author} ."\n";
              $$message .= 'Comment    : '. $comment{comment_data} ."\n\n";
            }
          }
        } else {
          if (exists $statusService{$comment{host_name}}{$comment{service_description}}) {
            writeNagiosCmd ( 'DEL_SVC_COMMENT', $comment{comment_id}, $cleanupList, $message, $debug );

            if ( $email ) {
              $$message .= 'Host       : '. $comment{host_name} ."\n";
              $$message .= 'Service    : '. $comment{service_description} ."\n";
              $$message .= 'Entry Type : '. $comment{entry_type} ."\n";
              $$message .= 'Comment ID : '. $comment{comment_id} ."\n";
              $$message .= 'Source     : '. $comment{source} ."\n";
              $$message .= 'Persistent : '. $comment{persistent} ."\n";
              $$message .= 'Entry Time : '. $comment{entry_time} ."\n";
              $$message .= 'Expires    : '. $comment{expires} ."\n";
              $$message .= 'Expire Time: '. $comment{expire_time} ."\n";
              $$message .= 'Author     : '. $comment{author} ."\n";
              $$message .= 'Comment    : '. $comment{comment_data} ."\n\n";
            }
          }
        }
      }

      %comment = ();
      $startBlok = $endBlok = 0;
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
      system ("echo \"$nagiosCmd\" >> $commandFile");
    } else {
      open(NAGIOSHEAP, ">>$commandFile") || die "Cannot append: $!";
        print NAGIOSHEAP "$nagiosCmd\n";
      close(NAGIOSHEAP);
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

