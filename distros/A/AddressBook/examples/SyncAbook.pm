#!/usr/bin/perl

package SyncAbook;
use AddressBook;

sub conduitInit {
  my $self = shift;
}

sub conduitSync {
  my $self = shift;
  my ($pilot_sock,$info) = @_;
 PilotMgr::status("Opening Pilot AddressBook",0);
  $self->{ldap} = AddressBook->new(source => "LDAP:localhost"
				   ) || die;
  $self->{pilot} = AddressBook->new(source => "PDB",
				  config=>$self->{ldap}->{config},	
				  dlp=>$pilot_sock,
				  );
 PilotMgr::status("Starting Synchronization",10);
 AddressBook::sync(master=>$self->{ldap},slave=>$self->{pilot},msg_function=>\&PilotMgr::msg);
 PilotMgr::status("Synchronization Complete",100);
  $self->{ldap} = undef;
  $self->{pilot} = undef;
  return;
}

sub conduitQuit {
  return;
}

sub conduitInfo {
  my $ret = {
              version => "0.100",
	      author => "David L. Leigh",
	      email => "dleigh\@sameasiteverwas.net",
	    };
  return $ret;
}


sub conduitConfigure {
  return;
}

1;
