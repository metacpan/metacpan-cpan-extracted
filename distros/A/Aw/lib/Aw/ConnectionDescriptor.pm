package Aw::ConnectionDescriptor;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.2';
}


sub getSSLCertificate
{
	my $result = Aw::ConnectionDescriptor::getSSLCertificateRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getSSLCertificateDns
{
	my $result = Aw::ConnectionDescriptor::getSSLCertificateDnsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getSSLRootDns
{
	my $result = Aw::ConnectionDescriptor::getSSLRootDnsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::ConnectionDescriptor - ActiveWorks Connection Descriptor Module.

=head1 SYNOPSIS

require Aw::ConnectionDescriptor;

my $cd = new Aw::ConnectionDescriptor;


=head1 DESCRIPTION

Enhanced interface for the Aw.xs Connection Descriptor methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
