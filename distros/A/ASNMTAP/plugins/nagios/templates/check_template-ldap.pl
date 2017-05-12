#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-ldap.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.002.003;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins::Nagios->new (
  _programName        => 'check_template-ldap.pl',
  _programDescription => 'LDAP Nagios Template',
  _programVersion     => '3.002.003',
  _programGetOptions  => ['host|H=s', 'port|P=i', 'dn=s', 'dnPass=s', 'base=s', 'scope=s', 'filter=s', 'username|u|loginname:s', 'password|p|passwd=s', 'environment|e:s'],
  _programUsagePrefix => '-0|--dn <dn> -1|--dnPass <dn pass> -b|--base <base> -s|--scope <scope> -f|--filter <filter>',
  _programHelpPrefix  => "-0, --dn=<DN>
-1, --dnPass=<DN PASS>
-b, --base=<BASE>
-s, --scope=<SCOPE>
-f, --filter=<FILTER>",
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $ldapserver = $objectNagios->getOptionsArgv ('host');
my $ldapport   = $objectNagios->getOptionsArgv ('port');
my $PASS       = $objectNagios->getOptionsArgv ('password');

my $DN = $objectNagios->getOptionsArgv ('dn') ? $objectNagios->getOptionsArgv ('dn') : undef;
$objectNagios->printUsage ('Missing command line argument dn') unless (defined $DN);

my $DN_PASS = $objectNagios->getOptionsArgv ('dnPass') ? $objectNagios->getOptionsArgv ('dnPass') : undef;
$objectNagios->printUsage ('Missing command line argument dnPass') unless (defined $DN_PASS);

my $BASE = $objectNagios->getOptionsArgv ('base') ? $objectNagios->getOptionsArgv ('base') : undef;
$objectNagios->printUsage ('Missing command line argument base') unless (defined $BASE);

my $SCOPE = $objectNagios->getOptionsArgv ('scope') ? $objectNagios->getOptionsArgv ('scope') : undef;
$objectNagios->printUsage ('Missing command line argument scope') unless (defined $SCOPE);

my $FILTER = $objectNagios->getOptionsArgv ('filter') ? $objectNagios->getOptionsArgv ('filter') : undef;
$objectNagios->printUsage ('Missing command line argument filter') unless (defined $FILTER);

my $USER = $objectNagios->getOptionsArgv ('username') ? $objectNagios->getOptionsArgv ('username') : undef;

my $debug = $objectNagios->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Net::LDAP;
use Net::LDAP::Util qw( ldap_error_name ldap_error_text );

my ($returnValue, $authenticated) = (1, 0);
my $ldap = Net::LDAP->new ($ldapserver, port => $ldapport, version => 2) or $returnValue = 0;

if ($returnValue) {
  my $messageLDAP;

  if ($DN ne '' && $DN_PASS ne '') {
    $messageLDAP = $ldap->bind($DN, password => $DN_PASS);
    $authenticated = ldapStatusOk ('Wrong username or password, dude..', $messageLDAP, $debug);
  } else {
    $messageLDAP = $ldap->bind();
    $authenticated = ldapStatusOk ('Annonymous', $messageLDAP, $debug);
  }

  if ($authenticated) {
    if ($debug) {
      print "WhooHoo, authentication is good!\n";
      my ($namingContexts, $supportedLDAPVersions);

      my $dse = $ldap->root_dse();

      my @contexts = $dse->get_value('namingContexts');
      $namingContexts = join (', ', @contexts);
      print "namingContexts: $namingContexts\n" if (defined $namingContexts);

      my @supportedLDAPVersion = $dse->get_value('supportedLDAPVersion');
      $supportedLDAPVersions = join (', ', @supportedLDAPVersion);
      print "supportedLDAPVersions: $supportedLDAPVersions\n" if (defined $supportedLDAPVersions);
    }
  
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $messageLDAP = $ldap->search ( base => $BASE, scope => $SCOPE, filter => $FILTER );

    if (ldapStatusOk ("Ooooopes, can't search", $messageLDAP, $debug)) {
      $objectNagios->pluginValues ( { stateValue => $ERRORS{OK}, alert => 'Search is good' }, $TYPE{APPEND} ); 

      if ($messageLDAP->count() != 0) {
        my $dn = ($messageLDAP->entry(0))->dn();
        print "\nDN: $dn\n" if ($debug);

        if ($debug >= 2) {
          my $entry = $messageLDAP->entry(0);
          foreach my $attribute ($entry->attributes) { print $attribute, ": ", $entry->get_value($attribute), "\n"; }
        }

        $ldap->unbind();

        if ($dn ne '' && defined $PASS && $PASS ne '') {
          # Now let's verify the authentication credentials, by rebinding with the users DN and password.
          my $ldap = Net::LDAP->new ($ldapserver, port => $ldapport, version => 2) or $returnValue = 0;

          if ($returnValue) {
            $messageLDAP = $ldap->bind($dn, password => $PASS);

            if (ldapStatusOk ('Wrong username or password', $messageLDAP, $debug)) {
              $ldap->unbind();
              $objectNagios->pluginValues ( { stateValue => $ERRORS{OK}, alert => "Search and Authentication is good" }, $TYPE{APPEND} );
            }
          } else {
            $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Can't get a connection to ldapserver '$ldapserver:$ldapport'" }, $TYPE{APPEND} );
          }
        } else {
          $objectNagios->pluginValues ( { stateValue => $ERRORS{OK}, alert => "Search is good" }, $TYPE{APPEND} ); 
        }
      } else {
        $ldap->unbind();
        $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Nothing found for 'base: $BASE - scope: $SCOPE - filter: $FILTER'" }, $TYPE{APPEND} ); 
      }
    }
  } else {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Can't bind to ldapserver '$ldapserver:$ldapport' for DN '$DN'" }, $TYPE{APPEND} ); 
  }
} else {
  $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Can't get a connection to ldapserver '$ldapserver:$ldapport'" }, $TYPE{APPEND} ); 
}

$objectNagios->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub ldapStatusOk {
  my ($error_message, $messageLDAP, $debug) = @_;

  if ( $messageLDAP->code) {
    print "-> $error_message\n" if ($debug);

    if ($debug >= 2) {
      print "Return code : ", $messageLDAP->code, "\n";
      print "Message     : ", ldap_error_name ($messageLDAP->code), ": ", ldap_error_text ($messageLDAP->error);
      print "MessageID   : ", $messageLDAP->mesg_id, "\n"      if (defined $messageLDAP->mesg_id);
      print "DN          : ", $messageLDAP->dn, "\n"           if (defined $messageLDAP->dn);
      print "Server error:",  $messageLDAP->server_error, "\n" if (defined $messageLDAP->server_error);
    }

    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $error_message .': '. $messageLDAP->code .' - '. $messageLDAP->error, result => '' }, $TYPE{APPEND} ); 
    return (0);
  } else {
    return (1);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Nagios

check_template-ldap.pl

LDAP Nagios Template

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