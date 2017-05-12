package Aw::Util;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.2';
}


sub getStringSeqInfo
{
	my $result = Aw::Util::getStringSeqInfoRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getUCStringSeqInfoAsA
{
	my $result = Aw::Util::getUCStringSeqInfoAsARef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getUCStringSeqInfoAsUTF8
{
	my $result = Aw::Util::getUCStringSeqInfoAsUTF8Ref ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getStructSeqInfo
{
	my $result = Aw::Util::getStructSeqInfoRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::Util - ActiveWorks Connection Descriptor Module.

=head1 SYNOPSIS

require Aw::Util;

my $cd = new Aw::Util;


=head1 DESCRIPTION

Enhanced interface for the Aw.xs Connection Descriptor methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
