package Aw::Admin::Client;
use base qw(Aw::Client);


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.2';

	require Aw::Admin;
	require Aw::Client;
}


sub getBrokersInTerritory
{
	my $result = Aw::Admin::Client::getBrokersInTerritoryRef ( @_ );
	( wantarray ) ? ( $result ) ? @{ $result } : () : $result ;
}



sub getClientSubscriptionsById
{
	my $result = Aw::Admin::Client::getClientSubscriptionsByIdRef ( @_ );
	( wantarray ) ? ( $result ) ? @{ $result } : ()  : $result ;
}



sub getEventAdminTypeDef
{
	return Aw::Admin::Client::_getEventAdminTypeDef ( @_ ) unless ( ref($_[0]) eq "ARRAY" );

	my $result = Aw::Admin::Client::getEventAdminTypeDefsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getEventAdminTypeDefs
{
	my $result = Aw::Admin::Client::getEventAdminTypeDefsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getEventAdminTypeDefsByScope
{
	my $result = Aw::Admin::Client::getEventAdminTypeDefsByScopeRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getTerrioryGatewaySharedEventTypes
{
	my $result = Aw::Admin::Client::getTerrioryGatewaySharedEventTypesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getClientInfoById
{
	return Aw::Admin::Client::_getClientInfoById ( @_ )
		unless ( ref($_[1]) eq "ARRAY" );

	my $result = Aw::Admin::Client::getClientInfosByIdRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getClientGroupInfoById
{
	return Aw::Admin::Client::_getClientGroupInfoById ( @_ )
		unless ( ref($_[1]) eq "ARRAY" );

	my $result = Aw::Admin::Client::getClientGroupInfosByIdRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getClientGroupInfosById
{
	my $result = Aw::Admin::Client::getClientInfosByIdRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getTerritroyGatewaySharedEventTypes
{
	my $result = Aw::Admin::Client::getTerritroyGatewaySharedEventTypesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getAllTerritoryGateways
{
	my $result = Aw::Admin::Client::getAllTerritoryGatewaysRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getLogOutputs
{
	my $result = Aw::Admin::Client::getLogOutputsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getClientGroupNames
{
	my $result = Aw::Admin::Client::getClientGroupNamesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getClientGroupCanPublishList
{
	my $result = Aw::Admin::Client::getClientGroupCanPublishList ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getClientGroupCanSubscribeList
{
	my $result = Aw::Admin::Client::getClientGroupCanSubscribeListRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getClientGroupsWhichCanPublish
{
	my $result = Aw::Admin::Client::getClientGroupsWhichCanPublishRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getClientGroupsWhichCanSubscribe
{
	my $result = Aw::Admin::Client::getClientGroupsWhichCanSubscribeRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getClientIdsByClientGroup
{
	my $result = Aw::Admin::Client::getClientIdsByClientGroupRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getClientIdsWhichAreSubscribed
{
	my $result = Aw::Admin::Client::getClientIdsWhichAreSubscribedRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getClientIds
{
	my $result = Aw::Admin::Client::getClientIdsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::Admin::Client - ActiveWorks Admin::Client Module.

=head1 SYNOPSIS

require Aw::Admin::Client;

my $admin = new Aw::Admin::Client ( @args );


=head1 DESCRIPTION

Enhanced interface for the Aw/Admin.xs Client methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
