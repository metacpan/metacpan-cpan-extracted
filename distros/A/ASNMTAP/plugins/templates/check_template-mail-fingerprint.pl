#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-mail-fingerprint.pl
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
  _programName        => 'check_template-mail-fingerprint.pl',
  _programDescription => "Mail with fingerprint plugin template for testing the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programGetOptions  => ['username|u|loginname=s', 'password|p|passwd=s', 'environment|e=s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $username    = $objectPlugins->getOptionsArgv ('username');
my $password    = $objectPlugins->getOptionsArgv ('password');
my $environment = $objectPlugins->getOptionsArgv ('environment');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Mail v3.002.003;

my $body = "

This is the body of the email !!!

";

my $objectMAIL = ASNMTAP::Asnmtap::Plugins::Mail->new (
  _asnmtapInherited => \$objectPlugins,
  _SMTP             => { smtp => [ qw(smtp.citap.be) ], mime => 0 },
  _POP3             => { pop3 => 'pop3.citap.be', username => $username, password => $password },
  _mailType         => 0,
  _text             => { SUBJECT => 'uKey=MAIL_'. $environment .'_0000' },
  _mail             => {
                         from   => 'alex.peeters@citap.com',
                         to     => 'asnmtap@citap.com',
                         status => $APPLICATION .' Status UP',
                         body   => $body
                       }
  );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($returnCode, $numberOfMatches);

# Receiving Fingerprint Mails - - - - - - - - - - - - - - - - - - - - - -

($returnCode, $numberOfMatches) = $objectMAIL->receiving_fingerprint_mails( custom => \&actionOnMailBody, checkFingerprint => 0, receivedState => 0, perfdataLabel => 'email(s) received' );

# Sending Fingerprint Mail  - - - - - - - - - - - - - - - - - - - - - - -

$returnCode = $objectMAIL->sending_fingerprint_mail( perfdataLabel => 'email send' );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Function needed by receiving_fingerprint_mail ! - - - - - - - - - - - -

sub actionOnMailBody {
  my ($self, $asnmtapInherited, $pop3, $msgnum) = @_;

  no warnings 'deprecated';
  my $returnCode = $ERRORS{OK};

  # put here your code regarding the MailBody - - - - - - - - - - - - - -
  # print "\n\n". $self->{defaultArguments}->{result}. "\n\n";

  $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => 'OKIDO' }, $TYPE{REPLACE} );

  # put here your code for deleting the email from the Mailbox  - - - - -
  $pop3->Delete( $msgnum ) unless ( $$asnmtapInherited->getOptionsValue ('debug') or $$asnmtapInherited->getOptionsValue ('onDemand') );
  $self->{defaultArguments}->{numberOfMatches}++;
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  return ( $returnCode );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-mail-fingerprint.pl

Mail without fingerprint plugin template for testing the 'Application Monitoring'

The ASNMTAP plugins come with ABSOLUTELY NO WARRANTY.

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut
