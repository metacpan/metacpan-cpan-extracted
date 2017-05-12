# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Asnmtap::Plugins::IO
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Asnmtap::Plugins::IO;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(%STATE %ERRORS %TYPE);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Plugins::IO::ISA         = qw(Exporter ASNMTAP::Asnmtap);

  %ASNMTAP::Asnmtap::Plugins::IO::EXPORT_TAGS = ( ALL    => [ qw(&scan_socket_info) ],

                                                  SOCKET => [ qw(&scan_socket_info) ] );

  @ASNMTAP::Asnmtap::Plugins::IO::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Plugins::IO::EXPORT_TAGS{ALL} } );
  
  $ASNMTAP::Asnmtap::Plugins::IO::VERSION     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub scan_socket_info {
  my %defaults = ( asnmtapInherited  => undef,
                   custom            => undef,
                   customArguments   => undef,
                   protocol          => undef,
                   host              => undef,
                   port              => undef,
                   service           => undef,
                   request           => undef,
                   socketTimeout     => undef,
                   timeout           => 10,
                   POP3              => {}
                 );

  my %parms = (%defaults, @_);
  
  my $asnmtapInherited = $parms{asnmtapInherited};
  unless ( defined $asnmtapInherited ) { cluck ( 'ASNMTAP::Asnmtap::Plugins::IO: asnmtapInherited missing' ); exit $ERRORS{UNKNOWN} }

  unless ( defined $parms{protocol} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing attribute protocol' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{protocol} =~ /(?:tcp|udp)/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Wrong value for attribute protocol: '. $parms{protocol} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $parms{host} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing attribute host' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{host} =~ /^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[a-zA-Z][-a-zA-Z0-9]+(\.[a-zA-Z][-a-zA-Z0-9]+)*)$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Wrong value for attribute host: '. $parms{host} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $parms{port} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing attribute port' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{port} =~ /^([1-9]?(?:\d*))$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Wrong value for attribute port: '. $parms{port} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $parms{service} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing attribute service' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  if ( $parms{port} == 110 and $parms{service} eq 'pop3' ) {
    unless ( defined $parms{POP3}{username} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing attribute username' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    unless ( defined $parms{POP3}{password} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing attribute password' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    unless ( defined $parms{POP3}{serviceReady} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing attribute serviceReady' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    unless ( defined $parms{POP3}{passwordRequired} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing attribute passwordRequired' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    unless ( defined $parms{POP3}{mailMessages} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing attribute mailMessages' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    unless ( defined $parms{POP3}{closingSession} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing attribute closingSession' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  }

  if ( defined $parms{socketTimeout} ) {
    unless ( $parms{socketTimeout} =~ /^([1-9]?(?:\d*))$/ ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Wrong value for attribute socketTimeout: '. $parms{socketTimeout} }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  }

  unless ( $parms{timeout} =~ /^([1-9]?(?:\d*))$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Wrong value for attribute timeout: '. $parms{timeout} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $debug = $$asnmtapInherited->getOptionsValue ( 'debug' ) || 0;

  if ( $debug >= 2 ) {
    print 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::protocol: ', $parms{protocol}, "\n";
    print 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::host: ', $parms{host}, "\n";
    print 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::port: ', $parms{port}, "\n";
    print 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::service: ', $parms{service}, "\n";
    print 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::request: ', $parms{request}, "\n" if ( defined $parms{request} );
    print 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::socketTimeout: ', $parms{socketTimeout}, "\n";
    print 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::timeout: ', $parms{timeout}, "\n";
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my ($exit, $action, $INET);
  $exit   = 0;
  $action = '<NIHIL>';

  $SIG{ALRM} = sub { alarm (0); $exit = 1 };
  alarm ( $parms{timeout} ); $exit = 0;

  use IO::Socket;

  if ( defined $parms{socketTimeout} ) {
    $INET = IO::Socket::INET->new ( Proto => $parms{protocol}, PeerAddr => $parms{host}, PeerPort => $parms{port} );
  } else {
    $INET = IO::Socket::INET->new ( Proto => $parms{protocol}, PeerAddr => $parms{host}, PeerPort => $parms{port}, Timeout => $parms{socketTimeout} );
  }

  if ( $INET ) {
    print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::action::IO::Socket::INET: $INET\n" if ( $debug >= 2 );
  } else {
    print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::action::IO::Socket::INET: Cannot connect to ${parms{host}}:${parms{service}}\n" if ( $debug >= 2 );
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "Cannot connect to ${parms{host}}:${parms{service}}" }, $TYPE{APPEND} );
    return ( $ERRORS{CRITICAL} );
  }

  $INET->autoflush ( 1 );

  if ( $INET && ($parms{protocol} eq 'tcp') ) {
    if ( $parms{port} == 25 and $parms{service} eq 'smtp' ) {
      print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::action::smtp(25): wait for answer\n" if ( $debug >= 2 );

      while ( <$INET> ) {
        chomp;

        print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::action::smtp(25): <$_>\n" if ( $debug >= 2 );
        if ( $exit ) { $action = '<TIMEOUT>'; last; }

        SWITCH: {
          if ( $_ =~ /^220 / ) { print $INET "HELP\n"; }
          if ( $_ =~ /^211 / ) { print $INET "QUIT\n"; $action = 'OK (211)'; }
          if ( $_ =~ /^214 / ) { print $INET "QUIT\n"; $action = 'OK (214)'; }
          if ( $_ =~ /^250 / ) { print $INET "QUIT\n"; $action = 'OK (250)'; }
          if ( $_ =~ /^421 / ) { print $INET "QUIT\n"; $action = 'OK (421)'; }
          if ( $_ =~ /^500 / ) { print $INET "QUIT\n"; $action = 'OK (500)'; }
          if ( $_ =~ /^501 / ) { print $INET "QUIT\n"; $action = 'OK (501)'; }
          if ( $_ =~ /^502 / ) { print $INET "QUIT\n"; $action = 'OK (502)'; }
          if ( $_ =~ /^504 / ) { print $INET "QUIT\n"; $action = 'OK (504)'; }
          if ( $_ =~ /^221 / ) { $action = 'OK (221)'; last; }
        }
      }
    } elsif ( $parms{port} == 110 and $parms{service} eq 'pop3' ) {
      print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::action::pop3(110): wait for answer\n" if ( $debug >= 2 );

      while ( <$INET> ) {
        chomp;

        print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::action::pop3(110): <$_>\n" if ( $debug >= 2 );
        if ( $exit ) { $action = "<TIMEOUT>"; last; }

        if ($_ =~ /^\+OK /) {
          SWITCH: {
 			if ( $_ =~ /${parms{POP3}{serviceReady}}/ )     { $action = 'USER (POP3)'; print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::action: $action\n" if ( $debug >= 2 ); print $INET "USER ${parms{POP3}{username}}\r\n"; }
            if ( $_ =~ /${parms{POP3}{passwordRequired}}/ ) { $action = 'PASS (POP3)'; print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::action: $action\n" if ( $debug >= 2 ); print $INET "PASS ${parms{POP3}{password}}\r\n"; }
            if ( $_ =~ /${parms{POP3}{mailMessages}}/ )     { $action = 'QUIT (POP3)'; print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::action: $action\n" if ( $debug >= 2 ); print $INET "QUIT\r\n"; }
            if ( $_ =~ /${parms{POP3}{closingSession}}/ )   { $action = 'OK (POP3)';   print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::action: $action\n" if ( $debug >= 2 ); last; }
          }
        } elsif ($_ =~ /^\-ERR /){ $action = "<$_>"; print $INET "HELP\n"; last; }
      }
    } else {
      print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::tcp: no RFC implementation: ${parms{protocol}} ${parms{service}}(${parms{port}})\n" if ( $debug >= 2 );
    }
  } elsif ( $INET && $parms{protocol} eq 'udp' ) {
    print "ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::udp: no RFC implementation: ${parms{protocol}} ${parms{service}}(${parms{port}})\n" if ( $debug >= 2 );
  }

  if ( defined $parms{custom} ) {
    ( defined $parms{customArguments} ) ? $parms{custom}->($$asnmtapInherited, \%parms, \$INET, \$action, $parms{customArguments}) : $parms{custom}->($$asnmtapInherited, \%parms, \$INET, \$action);
  } else {
    print 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info: ', $$asnmtapInherited->{_programDescription}, "\n" if ($debug);
  }

  alarm (0); $SIG{ALRM} = 'DEFAULT';
  close ( $INET );

  $INET = ( defined $parms{request} ? $parms{request} : "${parms{service}}(${parms{port}})" );

  if ( $INET eq $action ) {
    $$asnmtapInherited->pluginValue ( stateValue => $ERRORS{OK} );
    return ( $ERRORS{OK} );
  } else {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "Wrong answer from ${parms{host}} ${parms{service}}: $action" }, $TYPE{APPEND} );
    return ( $ERRORS{CRITICAL} );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::IO is a Perl module that provides IO functions used by ASNMTAP-based plugins.

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