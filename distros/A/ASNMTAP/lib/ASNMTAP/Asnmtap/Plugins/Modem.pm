# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Asnmtap::Plugins::Modem Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

# Class name  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
package ASNMTAP::Asnmtap::Plugins::Modem;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(%ERRORS %TYPE $CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $LOGPATH);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Plugins::Modem::ISA         = qw(Exporter ASNMTAP::Asnmtap);

  %ASNMTAP::Asnmtap::Plugins::Modem::EXPORT_TAGS = ( ALL => [ qw(&get_modem_request) ] );

  @ASNMTAP::Asnmtap::Plugins::Modem::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Plugins::Modem::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Plugins::Modem::VERSION     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_modem_request {
  my %defaults = ( asnmtapInherited => undef,
                   custom           => undef,
                   customArguments  => undef,
                   windows          => undef,
                   phonenumber      => undef,
                   port             => '/dev/ttyS0',
                   baudrate         => 19200,
                   databits         => 8,
                   initString       => 'H0 Z S7=45 S0=0 Q0 V1 E0 &C0 X4',
                   parity           => 'none',
                   stopbits         => 1,
                   timeout          => 30,
                   phonebook        => undef,
                   username         => undef,
                   password         => undef,
                   defaultGateway   => undef,
                   defaultInterface => undef,
                   defaultDelete    => 1,
                   pppInterface     => 'ppp0',
                   pppTimeout       => 60,
                   pppPath          => '/etc/ppp',
                   logtype          => 'syslog',
                   loglevel         => 'emerg'
                 );

  my %parms = (%defaults, @_);

  my $asnmtapInherited = $parms{asnmtapInherited};
  unless ( defined $asnmtapInherited ) { cluck ( 'ASNMTAP::Asnmtap::Plugins::XML: asnmtapInherited missing' ); exit $ERRORS{UNKNOWN} }

  my $debug = $$asnmtapInherited->getOptionsValue ( 'debug' ) || 0;

  unless ( defined $parms{phonenumber} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing phonenumber' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{phonenumber} =~ /^[.0-9]+$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid phonenumber: '. $parms{phonenumber} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  if ( $^O eq 'MSWin32' or ( defined $parms{windows} and $parms{windows} ) ) {
    eval "use Win32::RASE";
    $parms{windows} = 1;

    unless ( $parms{port} =~ /^com[1-4]$/ ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid Windows port: '. $parms{port} }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  } else {                                             # running on Linix
    eval "use Net::Ifconfig::Wrapper";
    $parms{windows} = 0;

    unless ( $parms{port} =~ /^\/dev\/ttyS[0-3]$/ ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid Linux port: '. $parms{port} }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  }

  unless ( $parms{baudrate} =~ /^(?:300|1200|2400|4800|9600|19200|38400|57600|115200)$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid baudrate: '. $parms{baudrate} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{databits} =~ /^[5-8]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid databits: '. $parms{databits} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{parity} =~ /^(?:none|odd|even)$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid : parity'. $parms{parity} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{stopbits} =~ /^[12]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid stopbits: '. $parms{stopbits} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{timeout} =~ /^\d+$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid timeout: '. $parms{timeout} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $modem_not_ras = ( defined $parms{phonebook} ) ? 0 : 1;

  unless ( $modem_not_ras ) {
    unless ( defined $parms{phonebook} and defined $parms{username} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing phonebook' }, $TYPE{APPEND} ) unless ( defined $parms{phonebook} );
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing username' },  $TYPE{APPEND} ) unless ( defined $parms{username} );
      return ( $ERRORS{UNKNOWN} );
    }

    if ( $parms{windows} and ! defined $parms{password} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing password' },  $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  }

  unless ( $parms{defaultDelete} =~ /^(?:[01])$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid defaultDelete: '. $parms{defaultDelete} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{pppInterface} =~ /^(?:ppp[0-3])$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid pppInterface: '. $parms{pppInterface} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{pppTimeout} =~ /^(?:[1-9]\d*)$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid pppTimeout: '. $parms{pppTimeout} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{logtype} =~ /^(?:file|syslog)$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid logtype: '. $parms{logtype} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{loglevel} =~ /^(?:debug|info|notice|warning|err|crit|alert|emerg)$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Invalid loglevel: '. $parms{loglevel} }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  use Device::Modem;

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _ppp_interface_info {
    my ($asnmtapInherited, $info, $pppInterface, $debug) = @_;

    my $pppStatus = ( $info->{$pppInterface}->{status} ) ? 'UP' : 'DOWN';
    my $pppInterfaceInfo = $pppInterface .': '. $pppStatus ."\n";

    if ( $pppStatus eq 'UP' ) {
      while ( my ($pppIp, $pppMask) = each( %{ $info->{$pppInterface}->{inet} } ) ) { 
        $pppInterfaceInfo .= sprintf ("inet %-15s mask $pppMask\n", $pppIp);
        $$asnmtapInherited->pluginValues ( { alert => "$pppInterface $pppStatus - inet $pppIp mask $pppMask" }, $TYPE{APPEND} );
      };

      $pppInterfaceInfo .= 'ether '. $info->{$pppInterface}->{ether} ."\n" if ( $info->{$pppInterface}->{ether} );
      $pppInterfaceInfo .= 'descr '. $info->{$pppInterface}->{descr} ."\n" if ( $info->{$pppInterface}->{descr} );
    }

    print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_ppp_interface_info: $pppInterfaceInfo" if ($debug);
    return ( $pppStatus );
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _error_trap_modem {
    my ($error_message, $ras_message, $debug) = @_;

    print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_error_trap_modem: $error_message, $ras_message\n" if ($debug);
    return (0);
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _test_modem {
    my ( $asnmtapInherited, $parms, $modem, $ok, $answer, $not_connected_guess, $test_modem, $debug ) = @_;

    my $log = 'syslog';

    if ( $$parms{logtype} eq 'file' ) {
      $$asnmtapInherited->call_system ( 'mkdir '. $LOGPATH ) unless ( -e "$LOGPATH" );
      my $logfile = $LOGPATH .'/'. $$asnmtapInherited->programName() .'.log';
      $log = 'file,'. $logfile;
    }

    if ($debug) {                              # test syslog/file logging
      $$modem = Device::Modem->new ( port => $$parms{port}, log => $log, loglevel => 'debug' );
    } else {
      $$modem = Device::Modem->new ( port => $$parms{port}, log => $log, loglevel => $$parms{loglevel} );
    }

    if ($debug) {
      print 'ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_test_modem::Device::Modem::new: '. $$modem ."\n";
      print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_test_modem::Device::Modem::connect: baudrate => $$parms{baudrate}, databits => $$parms{databits}, initString => $$parms{initString}, parity => $$parms{parity}, stopbits => $$parms{stopbits}\n";
    }

    if ( $$modem->connect ( baudrate => $$parms{baudrate}, databits => $$parms{databits}, initString => $$parms{initString}, parity => $$parms{parity}, stopbits => $$parms{stopbits} ) ) {
      print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_test_modem: Modem is connected to ". $$parms{port} ." serial port\n" if ($debug);
    } else {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Cannot connect to '. $$parms{port} ." serial port!: $!" }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    if ( $$modem->is_active () ) {
      print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_test_modem: Modem is active\n" if ($debug);
    } else {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Modem is turned off, or not functioning ...' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

	if ( $test_modem ) {
      # Try with AT escape code, send `attention' sequence (+++)
      $$answer = $$modem->attention();
      $$answer = '<no answer>' unless ( defined $$answer );
      print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_test_modem: Sending attention, modem says '$$answer'\n" if ($debug);

      unless ( $$answer eq '<no answer>' ) {
        $$asnmtapInherited->pluginValues ( { alert => "Sending attention, modem says '$$answer'" }, $TYPE{APPEND} );
        $$not_connected_guess++;
      }

      # Send empty AT command
      $$answer = undef;
      $$modem->atsend('AT'. Device::Modem::CR);
      $$answer = $$modem->answer();
      $$answer = '<no answer>' unless ( defined $$answer );
      print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_test_modem: Sending AT, modem says '$$answer'\n" if ($debug);

      unless ( $$answer =~ /OK/ ) {
        $$asnmtapInherited->pluginValues ( { alert => "Sending AT, modem says '$$answer'" }, $TYPE{APPEND} );
        $$not_connected_guess++;
      }

      # This must generate an error!
      $$answer = undef;
      $$modem->atsend('AT@x@@!$#'. Device::Modem::CR);
      $$answer = $$modem->answer();
      $$answer = '<no answer>' unless ( defined $$answer );
      print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_test_modem: Sending erroneous AT command, modem says '$$answer'\n" if ($debug);

      unless ( $$answer =~ /ERROR/ ) {
        $$asnmtapInherited->pluginValues ( { alert => "Sending erroneous AT command, modem says '$$answer'" }, $TYPE{APPEND} );
        $$not_connected_guess++;
      }

      $$answer = undef;
      $$modem->atsend('AT'. Device::Modem::CR);
      $$answer = $$modem->answer();
      $$answer = '<no answer>' unless ( defined $$answer );
      print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_test_modem: Sending AT command, modem says '$$answer'\n" if ($debug);

      $$answer = undef;
      $$modem->atsend('ATZ'. Device::Modem::CR);
      $$answer = $$modem->answer();
      $$answer = '<no answer>' unless ( defined $$answer );
      print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_test_modem: Sending ATZ reset command, modem says '$$answer'\n" if ($debug);

      unless ( $$answer =~ /OK/ ) {
        $$asnmtapInherited->pluginValues ( { alert => "Sending ATZ reset command, modem says '$$answer'" }, $TYPE{APPEND} );
        $$not_connected_guess++;
      }

      $$answer = undef;
      ($$ok, $$answer) = $$modem->dial( $$parms{phonenumber}, $$parms{timeout} );
      $$answer = '<no answer>' unless ( defined $$answer );

      print 'ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::_test_modem: ', ( $$ok ? 'Dialed' : 'Cannot Dial' ), '['. $$parms{phonenumber} ."], answer: $$answer\n" if ($debug);
    } else {
      $$modem = undef;
    }

    sleep (1);
    return ( $ERRORS{OK} );
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my ($returnCode, $hrasconn, $modem, $ok, $answer);
  my $not_connected_guess = 0;

  return ( $returnCode ) if ( $returnCode = _test_modem ( $asnmtapInherited, \%parms, \$modem, \$ok, \$answer, \$not_connected_guess, $modem_not_ras, $debug ) );

  unless ( $modem_not_ras ) {
    my ($pppStatus, $exit);

    if ( $parms{windows} ) {
      eval { no strict 'subs'; $hrasconn = RasDial( $parms{phonebook}, $parms{phonenumber}, $parms{username}, $parms{password} ) or _error_trap_modem ( 'Cannot Dial to '. $parms{phonenumber}, Win32::RASE::FormatMessage, $debug ) };
    } else {
      $$asnmtapInherited->call_system ( $ROUTECOMMAND .' del default' ) if ( $parms{defaultDelete} );

      my $ATZ= ''; # APE: there are modems that have problems with the command 'ATZ' ! # ' ATZ OK';
      my $command = 'cd '. $parms{pppPath} .'; '. $PPPDCOMMAND .' '. $parms{port} .' '. $parms{baudrate} .' debug user '. $parms{username} .' call '. $parms{phonebook} ." connect \"$CHATCOMMAND -v ABORT BUSY ABORT 'NO CARRIER' ABORT VOICE ABORT 'NO DIALTONE' ABORT 'NO DIAL TONE' ABORT 'NO ANSWER' ABORT DELAYED ''". $ATZ ." ATDT". $parms{phonenumber} ." CONNECT '\\d\\c'\" defaultroute";
      print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::pppd: $command\n" if ($debug);

      if ( $$asnmtapInherited->call_system ( "$command" ) ) {
        $$asnmtapInherited->pluginValues ( { alert => "'$command' failed" }, $TYPE{APPEND} );
        $not_connected_guess++;
      } else {
        $SIG{ALRM} = sub { alarm (0); $exit = 1 };
        alarm ( $parms{pppTimeout} ); $exit = 0;

        do {
          my $info; eval { $info = Net::Ifconfig::Wrapper::Ifconfig ('list') };

          if ( defined $info ) {
            $pppStatus = _ppp_interface_info ( $asnmtapInherited, $info, $parms{pppInterface}, $debug );

            if ( $pppStatus eq 'UP' ) {
              $hrasconn = $parms{phonebook};
            } else {
              $not_connected_guess++
            }

            undef $info;
          } else {
            $$asnmtapInherited->pluginValues ( { alert => "info '". $parms{phonebook} ."' not defined" }, $TYPE{APPEND} );
            $not_connected_guess++
          }

          sleep (1);
        } until (defined $hrasconn || $exit);

        alarm (0); $SIG{ALRM} = 'DEFAULT';

        unless ( defined $hrasconn ) {
          sleep (1);
          $$asnmtapInherited->pluginValues ( { alert => "pppd call '". $parms{phonebook} ."' failed" }, $TYPE{APPEND} );
          $$asnmtapInherited->call_system ( $KILLALLCOMMAND .' -HUP pppd' );
          $not_connected_guess++;
        }
      }

      $$asnmtapInherited->call_system ( $ROUTECOMMAND .' -n' );
    }

    if ( defined $hrasconn ) {
	  $ok = 1;
      $not_connected_guess = 0;
      print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request: Connected to $hrasconn\n" if ($debug);
    } else {                                                 # modem test
      return ( $returnCode ) if ( $returnCode = _test_modem ( $asnmtapInherited, \%parms, \$modem, \$ok, \$answer, \$not_connected_guess, ! $modem_not_ras, $debug ) );

      if ( $parms{windows} ) {
        $$asnmtapInherited->pluginValues ( { alert => "Cannot Dial to '" .$parms{phonenumber}. "'" }, $TYPE{APPEND} );
        $not_connected_guess++;
      }
    }
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $returnCode = $ERRORS{OK};

  if ( ( $modem_not_ras and defined $ok ) or ( defined $ok and $ok and ! $not_connected_guess ) ) {
    if ( defined $parms{custom} ) {
      $returnCode = ( defined $parms{customArguments} ) ? $parms{custom}->($$asnmtapInherited, \%parms, \$modem, \$ok, \$answer, \$not_connected_guess, $parms{customArguments}) : $parms{custom}->($$asnmtapInherited, \%parms, \$modem, \$ok, \$answer, \$not_connected_guess);
    } else {
      print 'ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request: ', $$asnmtapInherited->{_programDescription}, "\n" if ($debug);
    }
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  unless ( defined $parms{phonebook} ) {
    if ( $ok and $answer ne 'SKIP HANGUP' ) {
      sleep (1);
      $ok = $modem->hangup();

      if( $ok =~ /OK/ ) {
        print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::modem::hangup: Hanging up done\n" if ($debug);
      } else {
        print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::modem::hangup: Cannot Hanging up\n" if ($debug);
        $$asnmtapInherited->pluginValues ( { alert => 'Cannot Hanging up' }, $TYPE{APPEND} );
        $not_connected_guess++;
      }
    }
  } elsif ( $parms{windows} ) {
    eval {
      no strict 'subs';

      if ( RasHangUp($hrasconn, 3) ) {
        print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::RAS: RAS connection was terminated successfully.\n" if ($debug);
      } elsif ( ! Win32::RASE::GetLastError ) {
        print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::RAS: Timeout. RAS connection is still active.\n" if ($debug);
        $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Timeout. RAS connection is still active.' }, $TYPE{APPEND} );
      } else {
        print "ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::RAS: ", Win32::RASE::FormatMessage, "\n";
        $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => ' '. Win32::RASE::FormatMessage }, $TYPE{APPEND} );
      }
    }
  } else {
    $$asnmtapInherited->call_system ( $ROUTECOMMAND .' del default' ) if ( $parms{defaultDelete} );
    $$asnmtapInherited->call_system ( $KILLALLCOMMAND .' -HUP pppd' );
    $$asnmtapInherited->call_system ( $ROUTECOMMAND .' add default gw '. $parms{defaultGateway} .' dev '. $parms{defaultInterface} ); # if ( $parms{defaultDelete} );
  }

  $returnCode = ( $not_connected_guess ) ? $ERRORS{UNKNOWN} : $returnCode;
  $$asnmtapInherited->pluginValue ( stateValue => $returnCode );
  return ( $returnCode );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Modem is a Perl module that provides Modem functions used by ASNMTAP-based plugins.

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
