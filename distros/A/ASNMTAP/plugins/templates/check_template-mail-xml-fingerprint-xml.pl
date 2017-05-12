#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-mail-xml-fingerprint-xml.pl
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
  _programName        => 'check_template-mail-xml-fingerprint-xml.pl',
  _programDescription => "XML fingerprint Mail XML plugin template for testing the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programGetOptions  => ['username|u|loginname=s', 'password|p|passwd=s', 'interval|i=i', 'environment|e=s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $username = $objectPlugins->getOptionsArgv ('username');
my $password = $objectPlugins->getOptionsArgv ('password');
my $interval = $objectPlugins->getOptionsArgv ('interval');

my $environment     = $objectPlugins->getOptionsArgv ('environment');
my $environmentText = $objectPlugins->getOptionsValue ('environment');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Mail v3.002.003;

my %environment = ( P => 'PROD', A => 'ACC' , S => 'SIM', T => 'TEST', D => 'DEV', L => 'LOCAL' );

my $body = "
<?xml version=\"1.0\" encoding=\"UTF-8\"?>

<BaseServiceReport>
  <Ressource>
    <Server>Production-Server</Server>
    <Name>Name Service to Report</Name>
    <Date>yyyy/mm/dd</Date>
    <Time>hh:mm:ss</Time>
    <Environment>". $environment{$environment} ."</Environment>
	<ErrorStack><![CDATA[ErrorStack .1.]]></ErrorStack>
    <ErrorDetail><![CDATA[ErrorDetail .1.]]></ErrorDetail>
  </Ressource>
</BaseServiceReport>
";

my $objectMAIL = ASNMTAP::Asnmtap::Plugins::Mail->new (
  _asnmtapInherited => \$objectPlugins,
  _SMTP             => { smtp => [ qw(smtp.citap.be) ], mime => 0 },
  _POP3             => { pop3 => 'pop3.citap.be', username => $username, password => $password },
  _mailType         => 1,
  _text             => { SUBJECT => 'uKey=MAIL_'. $environment .'_0004' },
  _mail             => {
                         from   => 'alex.peeters@citap.com',
                         to     => 'asnmtap@citap.com',
                         status => $APPLICATION .' Status UP',
                         body   => $body
                       }
  );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($returnCode, $numberOfMatches, $debugfileMessage, @xml);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Receiving Fingerprint Mails - - - - - - - - - - - - - - - - - - - - - -

use constant HEADER  => '<?xml version="1.0" encoding="UTF-8"?>';
use constant FOOTER  => '</BaseServiceReport>';

$debugfileMessage  = "\n<HTML><HEAD><TITLE>Mail XML plugin template \@ $APPLICATION</TITLE></HEAD><BODY><HR><H1 style=\"margin: 0px 0px 5px; font: 125% verdana,arial,helvetica\">Mail XML plugin template @ $APPLICATION</H1><HR>\n";
$debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR style=\"font: normal 68% bold verdana,arial,helvetica; text-align:left; background:#a6caf0;\"><TH>Server</TH><TH>Name</TH><TH>Environment</TH><TH>First Occurence Date</TH><TH>First Occurence Time</TH><TH>Errors</TH></TR>\n";
$debugfileMessage .= "<H3 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">$environmentText</H3>";

($returnCode, $numberOfMatches) = $objectMAIL->receiving_fingerprint_mails( custom => \&actionOnMailBody, customArguments => \{ xml => \@xml, header => HEADER, footer => FOOTER, validateDTD => 0, filenameDTD => '' }, receivedState => 0, outOfDate => $interval, perfdataLabel => 'email(s) received' );

if ( defined $numberOfMatches and $numberOfMatches ) {
  my $debug = $objectPlugins->getOptionsValue ('debug');
  my $fixedAlert = "+";

  foreach my $xml (@xml) {
    $debugfileMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:purple;\"><TD>$xml->{Ressource}->{Server}</TD><TD>$xml->{Ressource}->{Name}</TD><TD>$xml->{Ressource}->{Environment}</TD><TD>$xml->{Ressource}->{Date}</TD><TD>$xml->{Ressource}->{Time}</TD><TD>$xml->{Ressource}->{Errors}</TD></TR>\n";
    $debugfileMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD valign=\"top\">Error Stack</TD><TD colspan=\"6\">$xml->{Ressource}->{ErrorStack}</TD></TR>\n";
    $debugfileMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD valign=\"top\">Error Detail</TD><TD colspan=\"6\">$xml->{Ressource}->{ErrorDetail}</TD></TR>\n" if ( $debug >= 2 );
    $fixedAlert       .= "$xml->{Ressource}->{Server}-$xml->{Ressource}->{Name}+";
  }

  $objectPlugins->pluginValues ( { alert => $fixedAlert }, $TYPE{COMMA_APPEND} ) if ($fixedAlert ne "+");
}

$debugfileMessage .= "\n</TABLE><P style=\"font: normal 68% verdana,arial,helvetica;\" ALIGN=\"left\">Generated on: ". scalar(localtime()) ."</P>\n</BODY>\n</HTML>";
$objectPlugins->write_debugfile ( \$debugfileMessage, 0 );

# Sending Fingerprint Mail  - - - - - - - - - - - - - - - - - - - - - - -

$returnCode = $objectMAIL->sending_fingerprint_mail( perfdataLabel => 'email send' );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Function needed by receiving_fingerprint_mail ! - - - - - - - - - - - -

sub actionOnMailBody {
  my ($self, $asnmtapInherited, $pop3, $msgnum, $arguments) = @_;

  my $debug = $$asnmtapInherited->getOptionsValue ('debug');

  unless ( defined $arguments and ref $arguments eq 'REF' and ref $$arguments eq 'HASH' ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'actionOnMailBody: arguments need to be an REF HASH!!!' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  no warnings 'deprecated';

  if ( $debug ) {
    print "\n\nactionOnMailBody:\n". $self->{defaultArguments}->{result} ."\n\n"; 
    while (my ($key, $value) = each %{ $$arguments } ) { print "actionOnMailBody: $key => $value\n"; }
    print "\n";
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);
  my ($returnCode, $xml) = extract_XML ( asnmtapInherited => $asnmtapInherited, resultXML => $self->{defaultArguments}->{result}, headerXML => ${$$arguments}{header}, footerXML => ${$$arguments}{footer}, validateDTD => ${$$arguments}{validateDTD}, filenameDTD => ${$$arguments}{filenameDTD} );

  unless ( $returnCode ) {
    if ( $debug ) {
      print "<->\n", $xml->{Ressource}->{Server}, "\n";
      print "<->\n", $xml->{Ressource}->{Name}, "\n";
      print "<->\n", $xml->{Ressource}->{Date}, "\n";
      print "<->\n", $xml->{Ressource}->{Time}, "\n";
      print "<->\n", $xml->{Ressource}->{Environment}, "\n";
    }

    my $tXml = ${$$arguments}{xml};
    my $environment = $$asnmtapInherited->getOptionsArgv('environment');
    my %environment = ( P => 'PROD', A => 'ACC' , S => 'SIM', T => 'TEST', D => 'DEV', L => 'LOCAL' );

    if ( $xml->{Ressource}->{Environment} =~ /^$environment{$environment}$/i ) {
      my $push = 0;

      foreach my $tmpXML (@{$tXml}) {
        $push = ($tmpXML->{Ressource}->{Server} eq $xml->{Ressource}->{Server}) &&
                ($tmpXML->{Ressource}->{Name} eq $xml->{Ressource}->{Name}) &&
                ($tmpXML->{Ressource}->{Environment} eq $xml->{Ressource}->{Environment}) &&
                ($tmpXML->{Ressource}->{ErrorStack} eq $xml->{Ressource}->{ErrorStack});

        if ($push && $debug >= 2) { $push = ($tmpXML->{Ressource}->{ErrorDetail} eq $xml->{Ressource}->{ErrorDetail}); }

        if ($push) {
          $tmpXML->{Ressource}->{Errors}++;
          last;
        }
      }

      unless ( $push ) {
        $xml->{Ressource}->{Errors} = 1;
        push (@{$tXml}, $xml);
      }

      $xml->{Ressource}->{ErrorDetail} = '' if ( $debug != 2 );
      $pop3->Delete( $msgnum ) unless ( $debug or $$asnmtapInherited->getOptionsValue ('onDemand') );
      $self->{defaultArguments}->{numberOfMatches}++;
    }

    if ( $debug ) {
      foreach my $xml (@{$tXml}) {
        print "\n+++(out)+++\n$xml->{Ressource}->{Name}\n$xml->{Ressource}->{Date}\n$xml->{Ressource}->{Time}\n$xml->{Ressource}->{Errors}\n";
      }
    }
  } else {
    $pop3->Delete( $msgnum ) unless ( $debug >= 4 and $$asnmtapInherited->getOptionsValue ('onDemand') );
  }

  return ( $returnCode );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-mail-xml-fingerprint-xml.pl

XML fingerprint Mail XML plugin template for testing the 'Application Monitoring'

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


