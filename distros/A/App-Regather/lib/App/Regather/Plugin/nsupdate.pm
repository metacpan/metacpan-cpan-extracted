# -*- mode: cperl; mode: follow; -*-
#

package App::Regather::Plugin::nsupdate;

=head1 NAME

nsupdate - RFC2136 complaint DNS zone update

=cut

=head1 DESCRIPTION

plugin to update dynamis DNS zone

logics is this:

    1. get target ip address from LDAP obj
    2. get name server/s from reverse zone for network, ip belongs to
    3. get list of zones to be updated
    3.1. from config file
         first ns_zone record is used for PTR

    3.2. from reverse zone TXT records
         get TXT records from reverse zone for network, ip belongs to, and
         a) here we assume, all related zones are served by the same name server/s
         b) each TXT record to suply zone names, should be prefixed

            prefix format is: `PART1:PART2:` where
            PART1 is config file value for 'service' -> 'service-name' -> 'ns_txt_pfx'
            PART2 is index number 0-9 to prioritize zones (0 is the highest priority)
            both parts should end with colon character

            so, zone name in TXT record value starts with offset = length(PART1)+3

            zone with priority 0 is used for PTR
         c) reverse zone name is pushed to the end of list of zones to be updated

    4. check existance and get if exist, A and PTR records for LDAP obj
    4.1. if not exists, then add new either record and return
    4.2. if exists, then check them against LDAP obj data
    4.2.1. if match, then return
    4.2.2. if not match then delete allr records and -> 4.1.

=cut

use strict;
use warnings;
use diagnostics;

use Data::Printer caller_info => 1, class => { expand => 2 }; # temporary stuff, to be removed

use Socket;
use Net::DNS;
use Net::DNS::RR::TSIG;
use Net::LDAP;
use Net::LDAP::Constant qw( LDAP_SYNC_ADD
			    LDAP_SYNC_MODIFY
			    LDAP_SYNC_DELETE );

use constant { UPDATE_UNKNOWN => 0,
	       UPDATE_SUCCESS => 1,
	       UPDATE_ERROR   => 2  };

=head1 METHODS

=head2 new

Creates an instance of the class and saves a reference to its
arguments for further use.

=cut

sub new {
  my $class = shift;
  local %_ = %{$_[0]};

  $_{log}->cc( pr => 'debug', fm => "%s: service %s; called for dn: %s",
	       ls => [ __PACKAGE__, $_{s}, $_{obj}->dn, ] ) if $_{v} > 2;

  my $ns_txt_pfx = $_{cf}->get('service', $_{s}, 'ns_txt_pfx');
  my $re    = qr/^$ns_txt_pfx/;
  my $ip    = (split(/ /, $_{obj}->get_value('umiOvpnCfgIfconfigPush')))[0]; # add check for empty
  my $ptr_z = sprintf("%s.in-addr.arpa",
		      join('.', splice( @{[ reverse( @{[ split(/\./, $ip) ]} ) ]},
					1)
			   )
		     );

  my $resolver = new Net::DNS::Resolver;
  my ( @z, @zones, $query, $zone, @rr, @servers );

  if ($_{cf}->is_set('service', $_{s}, 'ns_zone')) {
    push @zones, $_{cf}->get('service', $_{s}, 'ns_zone');
  } else {
    $query = $resolver->query($ptr_z, "TXT");
    if ($query) {
      foreach $zone ( $query->answer ) {
	push @z, substr($zone->txtdata,length($ns_txt_pfx)) if $zone->txtdata =~ /$re/;
      }

      @zones = map { if ( index($_,':') > -1 )
		       { substr($_, index($_,':')); }
		     else { $_; }
		   } sort @z;

    } else {
      $_{log}->cc( pr => 'err', fm => "%s: can't get TXT for zone: %s; %s",
		   ls => [ __PACKAGE__, $ptr_z, $resolver->errorstring, ] );
    }
  }

  ####### to fix this
  if ( ! scalar(@zones) ) {
    $_{log}->cc( pr => 'err', fm => "%s: imposible to get zone/s", ls => [ __PACKAGE__ ] );
    return;
  }

  push @zones, $ptr_z;
  
  if ($_{cf}->is_section('service', $_{s}, 'ns_server')) {
    push @servers, $_{cf}->getnode('service', $_{s}, 'ns_server');
  } else {
    $query = $resolver->query($ptr_z, "SOA");
    if ($query) {
      @rr = $query->answer;
      push @servers, $rr[0]->mname;
    } else {
      $_{log}->cc( pr => 'err', fm => "%s: can't get SOA for zone: %s; %s",
		   ls => [ __PACKAGE__, $ptr_z, $resolver->errorstring, ] );
    }
  }

  $resolver->nameservers(
			 map {
			   if (my @addrs = gethostbyname($_)) {
			     my @ret = map { inet_ntoa($_) } @addrs[4 .. $#addrs];
			   } else { $_ }
			 } @servers
			);

  # ?? whether to do anything on force ?? $_{s} = LDAP_SYNC_MODIFY if $_{force};

  bless {
	 cf       => delete $_{cf},
	 force    => delete $_{force},
	 log      => delete $_{log},
	 obj      => delete $_{obj},
	 service  => delete $_{s},
	 st       => delete $_{st},
	 v        => delete $_{v},

	 ip       => $ip,
	 ptr_z    => $ptr_z,
	 resolver => $resolver,
	 zones    => \@zones,

	 rest     => \%_,
	}, $class;

}

sub cf        { shift->{cf} }
sub force     { shift->{force} }
sub ip        { shift->{ip} }
sub log       { shift->{log} }
sub obj       { shift->{obj} }
sub ptr_z     { shift->{ptr_z} }
sub resolver  { shift->{resolver} }
sub service   { shift->{service} }
sub syncstate { shift->{st} }
sub v         { shift->{v} }
sub zones     { shift->{zones} }

=head2 ldap_sync_add_modify

performs nsupdate: add new, delete or modify existent records,
according LDAP sync state

=cut

sub ldap_sync_add_modify {
  my $self = shift;

  my $d_nam = $self->obj->get_value($self->cf->get('service', $self->service, 'ns_attr'));
  my ( $update, $fqdn_a, $fqdn_ptr, $query, @rr, $ptr, $a, $tmp, $reply);

  $self->log->cc( pr => 'debug', fm => "%s: object reverse zone: %s",
		  ls => [ __PACKAGE__, $self->ptr_z ]) if $self->v > 2;

  $self->log->cc( pr => 'debug', fm => "%s: object hostname: %s",
		  ls => [ __PACKAGE__, $d_nam, ] ) if $self->v > 2;

  my ( $zone, $param );
  foreach $zone ( @{$self->zones} ) {
    if ( $zone =~ /^.*\.in-addr\.arpa$/ ) {
      $param->{type} = 'PTR';
      $param->{byte4} = (split(/\./, $self->ip))[3];
      $param->{fqdn} = $param->{byte4};
      $param->{reverse} = sprintf("%s.%s", $param->{byte4}, $zone);
      $param->{rr_add} = sprintf("%s %s %s %s.", $param->{reverse},
				 $self->cf->get('service', $self->service, 'ns_ttl'),
				 $param->{type},
				 sprintf("%s.%s", $d_nam, $self->zones->[0]) );
    } else {
      $param->{type} = 'A';
      $param->{fqdn} = sprintf("%s.%s", $d_nam, $zone);
      $param->{rr_add} = sprintf("%s. %s %s %s", $param->{fqdn},
				 $self->cf->get('service', $self->service, 'ns_ttl'),
				 $param->{type},
				 $self->ip);
    }

    $update = new Net::DNS::Update($zone);
    $self->log->cc( pr => 'debug', fm => "%s: object expected %s record: %s",
		    ls => [ __PACKAGE__, $param->{type},
			    $param->{type} eq 'A' ? $param->{fqdn} : $param->{reverse}, ] );

    $query = $self->resolver->query($param->{type} eq 'A' ? $param->{fqdn} : $param->{reverse},
				    $param->{type});
    if ($query) {
      @rr = $query->answer;
      $param->{rr} = $param->{type} eq 'A' ? $rr[0]->address : $rr[0]->ptrdname;

      $self->log->cc( pr => 'debug', fm => "%s: query type: %s; RR: %s",
		      ls => [ __PACKAGE__, $param->{type}, $param->{rr} ] ) if $self->v > 2;

    } else {
      $self->log->cc( pr => 'err', fm => "%s: unable to resolve %s record: %s; error: %s",
		      ls => [ __PACKAGE__,$param->{type},
			      $param->{type} eq 'A' ? $param->{fqdn} : $param->{reverse},
			      $self->resolver->errorstring, ] );
    }


    if ( $self->syncstate == LDAP_SYNC_ADD && ! defined $param->{rr} ) {

      $update->push( pre => nxrrset( sprintf("%s. %s",
					     $param->{type} eq 'A' ? $param->{fqdn} : $param->{reverse},
					     $param->{type}) ) );
      $update->push( update => rr_add(  $param->{rr_add} ) );

    } elsif ( ($self->syncstate == LDAP_SYNC_ADD || $self->syncstate == LDAP_SYNC_MODIFY) &&
	      ( ! defined $param->{rr} ||
		($param->{type} eq 'A' && defined $param->{rr} && $param->{rr} ne $self->ip) ||
		($param->{type} eq 'PTR' && defined $param->{rr} &&
		 $param->{rr} ne sprintf("%s.%s", $d_nam, $self->zones->[0]))
	      )
	    ) {

      $update->push( update => rr_del( $param->{type} eq 'A' ? $param->{fqdn} : $param->{reverse} ) );
      $update->push( update => rr_add( $param->{rr_add} ) );

    } elsif ( $self->syncstate == LDAP_SYNC_DELETE ) {

      $update->push( update => rr_del(  $param->{fqdn}) );

    } else {
      $self->log->cc( pr => 'debug', fm => "%s: nothing to update", ls => [ __PACKAGE__ ] );
      next;
    }

    $update->sign_tsig($self->cf->get('service', $self->service, 'ns_keyfile'))
      if $self->cf->is_set('service', $self->service, 'ns_keyfile');

    $self->log->cc( pr => 'warning', fm => "%s: update->string:\n%s\n",
		    ls => [ __PACKAGE__, $update->string ] ) if $self->v > 2;

    $reply = $self->resolver->send($update);

    if ($reply) {
      if ( $reply->header->rcode eq 'NOERROR' ) {
    	$self->log->cc( pr => 'debug', fm => "%s: update successful", ls => [ __PACKAGE__ ] );
      } else {
    	$self->log->cc( pr => 'err', fm => "%s: update failed: %s",
    			ls => [ __PACKAGE__, $reply->header->rcode ] );
      }
    } else {
      $self->log->cc( pr => 'err', fm => "%s: update failed: %s",
    		      ls => [ __PACKAGE__, $self->resolver->errorstring ] );
    }

    undef @rr;
    undef $update;
    undef $param;
    undef $reply;
  }

}

=head2 ldap_sync_delete

alias to ldap_sync_add_modify

=cut

sub ldap_sync_delete { goto &ldap_sync_add_modify }

######################################################################

1;
