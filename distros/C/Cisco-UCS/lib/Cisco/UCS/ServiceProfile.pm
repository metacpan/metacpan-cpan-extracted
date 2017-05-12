package Cisco::UCS::ServiceProfile;

use warnings;
use strict;

use Carp 		qw(croak);
use Scalar::Util 	qw(weaken);

our $VERSION = '0.51';

our @ATTRIBUTES	= qw(dn name owner pnDn type uuid);

our %ATTRIBUTES = (
	 agent_policy_name              => 'agentPolicyName',
	 assign_state                   => 'assignState',
	 assoc_state                    => 'assocState',
	 bios_profile_name              => 'biosProfileName',
	 boot_policy_name               => 'bootPolicyName',
	 config_state                   => 'configState',
	 desc                           => 'descr',
	 dynamic_conn_policy_name       => 'dynamicConPolicyName',
	 ext_ip_state                   => 'extIPState',
	 fsm_remote_inv_err_code        => 'fsmRmtInvErrCode',
	 fsm_timestamp                  => 'fsmStamp',
	 fsm_desc                       => 'fsmDescr',
	 fsm_flags                      => 'fsmFlags',
	 fsm_previous_state             => 'fsmPrev',
	 fsm_progress                   => 'fsmProgr',
	 fsm_remote_inv_err_desc	=> 'fsmRmtInvErrDescr',
	 fsm_stage_desc                 => 'fsmStageDescr',
	 fsm_status                     => 'fsmStatus',
	 fsm_try                        => 'fsmTry',
	 host_fw_policy_name            => 'hostFwPolicyName',
	 ident_pool_name                => 'identPoolName',
	 local_disk_policy_name         => 'localDiskPolicyName',
	 maint_policy_name              => 'maintPolicyName',
	 mgmt_access_policy_name        => 'mgmtAccessPolicyName',
	 mgmt_firmware_policy_name      => 'mgmtFwPolicyName',
	 oper_bios_profile_name         => 'operBiosProfileName',
	 oper_boot_policy_name          => 'operBootPolicyName',
	 oper_dynamic_conn_policy_name  => 'operDynamicConPolicyName',
	 oper_host_fw_policy_name       => 'operHostFwPolicyName',
	 oper_ident_pool_name           => 'operIdentPoolName',
	 oper_local_disk_policy_name    => 'operLocalDiskPolicyName',
	 oper_maint_policy_name         => 'operMaintPolicyName',
	 oper_mgmt_access_policy_name   => 'operMgmtAccessPolicyName',
	 oper_mgmt_fw_policy_name       => 'operMgmtFwPolicyName',
	 oper_power_policy_name         => 'operPowerPolicyName',
	 oper_scrub_policy_name         => 'operScrubPolicyName',
	 oper_sol_policy_name           => 'operSolPolicyName',
	 oper_src_template_name         => 'operSrcTemplName',
	 oper_state                     => 'operState',
	 oper_stats_policy_name         => 'operStatsPolicyName',
	 oper_vcon_profile_name         => 'operVconProfileName',
	 power_policy_name              => 'powerPolicyName',
	 scrub_policy_name              => 'scrubPolicyName',
	 sol_policy_name                => 'solPolicyName',
	 source_template_name           => 'srcTemplName',
	 stats_policy_name              => 'statsPolicyName',
	 user_label                     => 'usrLbl',
	 uuid_suffix                    => 'uuidSuffix',
	 vcon_profile_name              => 'vconProfileName'
);

sub new {
	my ( $class, %args ) = @_;

	my $self = {};
	bless $self, $class;

	defined $args{dn}
		? $self->{dn} = $args{dn}
		: croak 'dn not defined';

	defined $args{ucs}
		? weaken( $self->{ucs} = $args{ucs} )
		: croak 'dn not defined';

	my %attr = %{ $self->{ucs}->resolve_dn(
				dn => $self->{dn}
			)->{outConfig}->{lsServer} };
	
	while ( my ($k, $v) = each %attr ) { $self->{$k} = $v }

	return $self
}

{
        no strict 'refs';

        while ( my ( $pseudo, $attribute ) = each %ATTRIBUTES ) { 
                *{ __PACKAGE__ . '::' . $pseudo } = sub {
                        my $self = shift;
                        return $self->{$attribute}
                }   
        }   

        foreach my $attribute ( @ATTRIBUTES ) {
                *{ __PACKAGE__ . '::' . $attribute } = sub {
                        my $self = shift;
                        return $self->{$attribute}
                }   
        }   
}

1;

__END__

=head1 NAME

Cisco::UCS::ServiceProfile - Class for operations with a Cisco UCS Service 
Profile.

=head1 SYNOPSIS

	my $profile = $ucs->service_profile('profile-1');
	print "Profile " . $profile->name 
		. " is bound to physical DN " . $profile->pnDn . "\n";

	print $ucs->service_profile('profile-2')->uuid;

=head1 DECRIPTION

Cisco::UCS::ServiceProfile is a class providing operations with a Cisco UCS 
Service Profile.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::ServiceProfile object is created automatically by method calls via 
methods in Cisco::UCS.

=head1 METHODS

=head3 agent_policy_name

Returns the agent policy name.

=head3 assign_state

Returns the assignment state of the service profile.

=head3 assoc_state

Returns the association state of the service profile.

=head3 bios_profile_name

Returns the BIOS profile name of the service profile.

=head3 boot_policy_name

Returns the boot policy name of the service profile.

=head3 config_state

Returns the configuration state of the service profile.

=head3 desc

Returns the user-specified description of the service profile.

=head3 dn

Returns the distinguished name of the service profile in the UCS management 
information heirarchy.

=head3 dynamic_conn_policy_name

Returns the dynamic connection policy name of the service profile.

=head3 ext_ip_state

Returns the external IP state of the service profile.

=head3 fsm_timestamp

Returns the timestamp of the most recent FSM transition.

=head3 fsm_desc

Returns a description of the FSM current state.

=head3 fsm_flags

Returns the FSM flags.

=head3 fsm_previous_state

Returns the previous state of the FSM prior to the last transition.

=head3 fsm_progress

Returns the current progress (given as a percentage) of the current progress
of the FSM through the current state.

=head3 fsm_remote_inv_err_code

Returns the FSM (finite state machine) remote invocation error code.

=head3 fsm_remote_inv_err_desc

Returns a description of the FSM remote invocation error state.

=head3 fsm_stage_desc

Returns a description of the current FSM stage.

=head3 fsm_status

Returns the current FSM status.

=head3 fsm_try

Returns the number of attempts for the current FSM stage transition.

=head3 host_fw_policy_name

Returns the host firmware policy name for the service profile.

=head3 ident_pool_name

Returns the pool name from which the UUID for the service profile is derived.

=head3 local_disk_policy_name

Returns the local disk policy name for the service profile.

=head3 maint_policy_name

Returns the maintenance policy name for the service profile.

=head3 mgmt_access_policy_name

Returns the management access policy name for the service profile.

=head3 mgmt_firmware_policy_name

Returns the management firmware policy name for the service profile.

=head3 name

Returns the user defined name of the service profile.

=head3 oper_bios_profile_name

Returns the operational BIOS profile name for the service profile.

=head3 oper_boot_policy_name

Returns the operational boot policy name for the service profile.

=head3 oper_dynamic_conn_policy_name

Returns the operational dynamic connection policy name for the service profile.

=head3 oper_host_fw_policy_name

Returns the operational firmware policy name for the service profile.

=head3 oper_ident_pool_name

Returns the operational identifier pool name for the service profile.

=head3 oper_local_disk_policy_name

Returns the operational local disk policy name for the service profile.

=head3 oper_maint_policy_name

Returns the operational maintenance policy name for the service profile.

=head3 oper_mgmt_access_policy_name

Returns the operational management access policy name for the service profile.

=head3 oper_mgmt_fw_policy_name

Returns the operational management firmware policy name for the service 
profile.

=head3 oper_power_policy_name

Returns the operational power policy name for the service profile.

=head3 oper_scrub_policy_name

Returns the operational scrub policy name for the service profile.

=head3 oper_sol_policy_name

Returns the operational SOL policy name for the service profile.

=head3 oper_src_template_name

Returns the operational source template name for the service profile.

=head3 oper_state

Returns the operational state of the service profile.

=head3 oper_stats_policy_name

Returns the operational statictics policy name for the service profile.

=head3 oper_vcon_profile_name

Returns the operational virtual connection profile name for the service 
profile.

=head3 owner

Returns the user-defined owner of the service profile.

=head3 pnDn

Returns the peer DN (distinguished name) of the blade to which this
service profile is associated.

=head3 power_policy_name

returns the operational power policy name for the service profile.

=head3 scrub_policy_name

Returns the scrub policy name for the service profile.

=head3 sol_policy_name

Returns the SOL policy name for the service profile.

=head3 source_template_name

Returns the source service profile template name for the service profile.

=head3 stats_policy_name

Returns the statistics policy name for the service profile.

=head3 type

Returns the type of the service profile - for service profiles this will 
return the string of 'instance', for service profile templates this will 
return the string 'template'.

=head3 user_label

Returns the user defined label for the service profile.

=head3 uuid

Returns the UUID (Universally Unique Identifier) of the service profile.

=head3 uuid_suffix

Returns the UUID suffix for the service profile.

=head3 vcon_profile_name

Returns the virtual connection policy name for the service profile.


=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-cisco-ucs-serviceprofile at rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-ServiceProfile>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 TO DO

This module barely scratches the surface in terms of available service profile 
information. Future versions will provide access to virtual interface 
configuration and statistics and environmental statictics.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::ServiceProfile


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-ServiceProfile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-ServiceProfile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-ServiceProfile>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-ServiceProfile/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
