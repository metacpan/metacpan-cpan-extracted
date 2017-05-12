package Aw::Admin::ServerClient;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.2';

	require Aw::Admin;
}


sub getBrokers
{
	my $result = Aw::Admin::ServerClient::getBrokersRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getServerLogEntries
{
	my $result = Aw::Admin::ServerClient::getServerLogEntriesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getDNsFromCertFile
{
	my $result = Aw::Admin::ServerClient::getDNsFromCertFileRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::Admin::ServerClient - ActiveWorks Admin::ServerClient Module.

=head1 SYNOPSIS

require Aw::Admin::ServerClient;

my $client = new Aw::Admin::ServerClient ( @args );


=head1 DESCRIPTION

Enhanced interface for the Aw/Admin.xs ServerClient methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
