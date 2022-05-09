# -*- mode: cperl; eval: (follow-mode); -*-
#

package App::Regather::Plugin::generic;

=head1 NAME

generic - generic plugin example

=cut

=head1 DESCRIPTION

generic plugin example

writes LDAP entry dump to the file set in config option
service.servicename.out_file

configuration:

=over

[service generic]
  plugin      = generic
  ctrl_attr   = uid
  ctrl_srv_re = ^.*$
  out_path    = /path/to/regather-output

[service generic map s]
  uid = uid

=back

=cut

use strict;
use warnings;
use diagnostics;

use Net::LDAP;
use constant SYNST => [ qw( LDAP_SYNC_PRESENT LDAP_SYNC_ADD LDAP_SYNC_MODIFY LDAP_SYNC_DELETE ) ];

use POSIX;

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

  my $example_dn = $_{obj}->dn;
  my $example_out_file = $_{cf}->is_set('service', $_{s}, 'out_file') ?
    $_{cf}->get('service', $_{s}, 'out_file') :
    "regather-plugin-generic-example-output.txt";
  $_{log}->cc( pr => 'debug', fm => "%s:%s: service %s; out_file: %s",
	       ls => [ __FILE__,__LINE__, $_{s}, $example_out_file, ] ) if $_{v} > 2;

  bless {
	 cf       => delete $_{cf},
	 force    => delete $_{force},
	 log      => delete $_{log},
	 obj      => delete $_{obj},
	 service  => delete $_{s},
	 st       => delete $_{st},
	 v        => delete $_{v},

	 example_dn       => $example_dn,
	 example_out_file => $example_out_file,

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

sub example_dn {shift->{example_dn}}
sub example_out_file {shift->{example_out_file}}

=head2 ldap_sync_add_modify

writes LDAP entry dump to the file set in config option
service.servicename.out_file

=cut

sub ldap_sync_add_modify {
  my $self = shift;

  my $ts = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime());
  
  $self->log->cc( pr => 'debug', fm => "%s:%s: dn: %s; example: LDAP sync event: %s processing start",
		  ls => [ __FILE__,__LINE__, $self->example_dn, SYNST->[$self->syncstate] ]) if $self->v > 0;

  open(my $fh, ">>", '/tmp/' . $self->example_out_file) || do {
    print "Can't open > /tmp/" . $self->example_out_file . " for writing: $!"; exit 1; };

  print $fh "\n\n$ts: generic plugin example: LDAP sync event: " . SYNST->[$self->syncstate] . "\n";
  $self->obj->dump($fh);

  close($fh) || do {
    print "close $self->example_out_file (opened for writing), failed: $!\n\n"; exit 1; };

  $self->log->cc( pr => 'debug', fm => "%s:%s: dn: %s; example: LDAP sync event: %s processing stop",
		  ls => [ __FILE__,__LINE__, $self->example_dn, SYNST->[$self->syncstate] ]) if $self->v > 0;

}

=head2 ldap_sync_delete

alias to ldap_sync_add_modify

=cut

sub ldap_sync_delete { goto &ldap_sync_add_modify }

######################################################################

1;
