package Aw::Admin::LogConfig;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.2';

	require Aw::Admin;
}


sub getOutput
{
	return Aw::Admin::LogConfig::getOutput ( @_ ) if ( scalar @_ == 2 );

	my $result = Aw::Admin::LogConfig::getOutputsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}


sub getTopic
{
	return Aw::Admin::LogConfig::getTopic ( @_ ) if ( scalar @_ == 2 );

	my $result = Aw::Admin::LogConfig::getTopicsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::Admin::LogConfig - ActiveWorks Admin::LogConfig Module.

=head1 SYNOPSIS

require Aw::Admin::LogConfig;

my $log = new Aw::Admin::LogConfig;


=head1 DESCRIPTION

Enhanced interface for the Aw/Client.xs LogConfig methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
