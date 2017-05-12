#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_sendAndReceiveMail.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS %STATE);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_sendAndReceiveMail.pl',
  _programDescription => 'Send and Receive Mail',
  _programVersion     => '3.002.003',
  _programGetOptions  => ['username|u|loginname=s', 'password|p|passwd=s', 'interval|i=i', 'environment|e:s', 'timeout|t:i', 'trendline|T=i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $username    = $objectPlugins->getOptionsArgv ('username');
my $password    = $objectPlugins->getOptionsArgv ('password');
my $interval    = $objectPlugins->getOptionsArgv ('interval');
my $trendline   = $objectPlugins->getOptionsArgv ('trendline');
my $environment = $objectPlugins->getOptionsArgv ('environment');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Mail v3.002.003;

my $body = "

This is the body of the email !!!

";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($objectMAIL, $returnCode, $responseTime, $number1OfMatches, $number2OfMatches, $receivingMails, $sendingMails);

# Receiving Fingerprint Mails - - - - - - - - - - - - - - - - - - - - - -

$objectMAIL = ASNMTAP::Asnmtap::Plugins::Mail->new (
  _asnmtapInherited => \$objectPlugins,
  _SMTP             => { smtp => [ qw( smtp.citap.be smtp.citap.com ) ], mime => 0 },
  _POP3             => { pop3 => 'pop3.citap.com', username => $username, password => $password },
  _mailType         => 0,
  _mail             => {
                         from   => 'postmaster@citap.com',
                         to     => 'asnmtap@citap.com',
                         status => 'DELIVERY FAILURE: 550 Mailbox unavailable <unknown.mailbox@citap.com>',
                         body   => '_TBD_'
                       }
  );

no warnings 'deprecated';
$objectMAIL->{_subject_} = 'DELIVERY FAILURE: 550 Mailbox unavailable <unknown.mailbox@citap.com>';
($returnCode, $number1OfMatches) = $objectMAIL->receiving_fingerprint_mails( custom => \&actionOnMailBody, checkFingerprint => 0, receivedState => 0, outOfDate => $interval, perfdataLabel => 'email(s) received from citap.com' );
undef $objectMAIL;

$objectMAIL = ASNMTAP::Asnmtap::Plugins::Mail->new (
  _asnmtapInherited => \$objectPlugins,
  _SMTP             => { smtp => [ qw( smtp.citap.be smtp.citap.com ) ], mime => 0 },
  _POP3             => { pop3 => 'pop3.citap.com', username => $username, password => $password },
  _mailType         => 0,
  _mail             => {
                         from   => 'postmaster@citap.com',
                         to     => 'asnmtap@citap.com',
                         status => 'DELIVERY FAILURE: 553 User does not exist',
                         body   => '_TBD_'
                       }
  );

no warnings 'deprecated';
$objectMAIL->{_subject_} = 'DELIVERY FAILURE: 553 User does not exist';
($returnCode, $number2OfMatches) = $objectMAIL->receiving_fingerprint_mails( custom => \&actionOnMailBody, checkFingerprint => 0, receivedState => 0, outOfDate => $interval, perfdataLabel => 'email(s) received from citap.be' );
undef $objectMAIL;

$receivingMails = ($number1OfMatches or $number2OfMatches) ? ($number1OfMatches + $number2OfMatches) : 0;

# Sending Fingerprint Mail  - - - - - - - - - - - - - - - - - - - - - - -

$objectMAIL = ASNMTAP::Asnmtap::Plugins::Mail->new (
  _asnmtapInherited => \$objectPlugins,
  _SMTP             => { smtp => [ qw( smtp.citap.be smtp.citap.com ) ], mime => 0 },
  _POP3             => { pop3 => 'pop3.citap.com', username => $username, password => $password },
  _mailType         => 1,
  _text             => { SUBJECT => 'uKey=MAIL_'. $environment .'_0006' },
  _mail             => {
                         from   => 'asnmtap@citap.com',
                         to     => 'unknown.mailbox@citap.com',
                         status => 'DELIVERY FAILURE: 550 Mailbox unavailable <unknown.mailbox@citap.com>',
                         body   => $body
                       }
  );

$sendingMails++ if ( $objectMAIL->sending_fingerprint_mail( perfdataLabel => 'email send to citap.com' ) );
undef $objectMAIL;

$objectMAIL = ASNMTAP::Asnmtap::Plugins::Mail->new (
  _asnmtapInherited => \$objectPlugins,
  _SMTP             => { smtp => [ qw( smtp.citap.be smtp.citap.com ) ], mime => 0 },
  _POP3             => { pop3 => 'pop3.citap.com', username => $username, password => $password },
  _mailType         => 1,
  _text             => { SUBJECT => 'uKey=MAIL_'. $environment .'_0006' },
  _mail             => {
                         from   => 'asnmtap@citap.com',
                         to     => 'unknown.mailbox@citap.be',
                         status => 'DELIVERY FAILURE: 553 User does not exist',
                         body   => $body
                       }
  );

$sendingMails++ if ( $objectMAIL->sending_fingerprint_mail( perfdataLabel => 'email send to citap.be' ) );
undef $objectMAIL;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValue ( stateValue => $ERRORS{OK} ) if ($receivingMails && $sendingMails == 2);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# Function needed by receiving_fingerprint_mail ! - - - - - - - - - - - -

sub actionOnMailBody {
  my ($self, $asnmtapInherited, $pop3, $msgnum) = @_;

  no warnings 'deprecated';
  $pop3->Delete( $msgnum ) unless ( $$asnmtapInherited->getOptionsValue ('debug') or $$asnmtapInherited->getOptionsValue ('onDemand') );
  $self->{defaultArguments}->{numberOfMatches}++;

  my $returnCode = $ERRORS{OK};
  return ( $returnCode );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

