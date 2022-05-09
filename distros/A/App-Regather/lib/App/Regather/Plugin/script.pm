# -*- mode: cperl; eval: (follow-mode); -*-
#

package App::Regather::Plugin::script;

=head1 NAME

script - plugin to run a script against LDAP object on LDAP_SYNC event

=cut

=head1 DESCRIPTION

script - plugin to run script against LDAP object attributes, set as
environment variables on LDAP_SYNC event

environment variables provided to the script:

=over

    REGATHER_LDAP_OBJ_ATTR_<attributeX_name>
    REGATHER_LDAP_OBJ_DN
    REGATHER_LDAP_OBJ_LDIF
    REGATHER_LDAP_SYNC_CONTROL_CODE
    REGATHER_LDAP_SYNC_CONTROL_NAME

=back

configuration:

=over

[service name_of_my_script_service]
  plugin       = script
  all_attr     = 1
  ctrl_attr    = uid
  ctrl_srv_re  = ^.*$
  post_process = /path/to/scrip1
  post_process = /path/to/scrip2

=back

all attributes will be exposed if option B<all_attr> not null

=cut

use strict;
use warnings;
use diagnostics;

use IPC::Open2;

use Net::LDAP;
use constant SYNST => [ qw( LDAP_SYNC_PRESENT LDAP_SYNC_ADD LDAP_SYNC_MODIFY LDAP_SYNC_DELETE ) ];

=head1 METHODS

=head2 new

Creates an instance of the class and saves a reference to its
arguments for further use.

=cut

sub new {
  my $class = shift;
  local %_ = %{$_[0]};

  $_{log}->cc( pr => 'debug', fm => "%s:%s: service %s; called for dn: %s",
	       ls => [ __FILE__,__LINE__, $_{s}, $_{obj}->dn, ] ) if $_{v} > 2;

  bless {
	 cf       => delete $_{cf},
	 force    => delete $_{force},
	 log      => delete $_{log},
	 obj      => delete $_{obj},
	 service  => delete $_{s},
	 st       => delete $_{st},
	 v        => delete $_{v},
	 rest     => \%_,
	}, $class;

}

sub cf        { shift->{cf} }
sub force     { shift->{force} }
sub log       { shift->{log} }
sub obj       { shift->{obj} }
sub service   { shift->{service} }
sub syncstate { shift->{st} }
sub v         { shift->{v} }
sub rest { shift->{rest} };

=head2 ldap_sync_add_modify

set environmental variables according LDAP object attribute:value
pairs and runs a script

=cut

sub ldap_sync_add_modify {
  my $self = shift;

  $ENV{REGATHER_LDAP_OBJ_DN}             = $self->obj->dn;
  $ENV{REGATHER_LDAP_OBJ_LDIF}           = $self->obj->ldif;
  $ENV{REGATHER_LDAP_SYNC_CONTROL_CODE}  = $self->syncstate;
  $ENV{REGATHER_LDAP_SYNC_CONTROL_NAME}  = SYNST->[$self->syncstate];
  foreach my $k ($self->obj->attributes) {
    $ENV{"REGATHER_LDAP_OBJ_ATTR_" . $k} = $self->obj->get_value($k);
  }

  my ($pp, $chin, $chou, $chst, $cher);
  if ( $self->cf->is_set('service', $self->service, 'post_process') ) {
    foreach $pp ( @{$self->cf->get('service', $self->service, 'post_process')} ) {
      $self->log->cc( pr => 'debug', fm => "%s:%s: dn: %s; LDAP sync event %s processing script: %s",
		      ls => [ __FILE__,__LINE__, $self->obj->dn, SYNST->[$self->syncstate], $pp ]) if $self->v > 2;

      my $pid = open2( $chou, $chin, $pp );
      waitpid( $pid, 0 );
      $chst = $? >> 8;
      if ( $chst ) {
	$cher .= $_ while ( <$chou> );
	$self->log->cc( pr => 'err', ls => [ __FILE__,__LINE__, $self->service, $pp, $cher ],
			nt => 1, fm => "%s:%s: service %s post_process: %s, error: %s", );
      }

    }
  }

}

=head2 ldap_sync_delete

alias to ldap_sync_add_modify

=cut

sub ldap_sync_delete { goto &ldap_sync_add_modify }

######################################################################

1;
