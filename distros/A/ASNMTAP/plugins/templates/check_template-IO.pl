#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-IO.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_template-IO.pl',
  _programDescription => "IO plugin template for the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programUsagePrefix => '--service <service> --protocol <protocol> --request <request>',
  _programHelpPrefix  => '--service=<service>
--protocol=<protocol>
--request=<request>',
  _programGetOptions  => ['host|H=s', 'port|P=i', 'service:s', 'protocol:s', 'request:s', 'username|u|loginname:s', 'password|p|passwd:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

my $host     = $objectPlugins->getOptionsArgv ('host');
my $port     = $objectPlugins->getOptionsArgv ('port');
my $service  = $objectPlugins->getOptionsArgv ('service');
my $protocol = $objectPlugins->getOptionsArgv ('protocol');
my $request  = $objectPlugins->getOptionsArgv ('request');
my $username = $objectPlugins->getOptionsArgv ('username');
my $password = $objectPlugins->getOptionsArgv ('password');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::IO v3.002.003;
use ASNMTAP::Asnmtap::Plugins::IO qw(:SOCKET);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $returnCode = scan_socket_info (
  asnmtapInherited => \$objectPlugins,
  protocol         => $protocol,
  host             => $host,
  port             => $port,
  service          => $service,
  request          => $request,
  socketTimeout    => 5,
  POP3             => {
    username          => $username, 
    password          => $password, 
    serviceReady      =>  "[XMail [0-9.]+ POP3 Server] service ready",
    passwordRequired  => 'Password required for',
    mailMessages      => "Maildrop has [0-9.]+ messages",
    closingSession    =>  "[XMail [0-9.]+ POP3 Server] closing session"
                      }
);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-IO.pl

IO plugin template for the 'Application Monitor'

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
