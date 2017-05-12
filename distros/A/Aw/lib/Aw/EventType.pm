package Aw::EventType;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.2';
}


sub getStringSeqInfo
{
	my $result = Aw::EventType::getStringSeqInfoRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getUCStringSeqInfoAsA
{
	my $result = Aw::EventType::getUCStringSeqInfoAsARef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getUCStringSeqInfoAsUTF8
{
	my $result = Aw::EventType::getUCStringSeqInfoAsUTF8Ref ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getStructSeqInfo
{
	my $result = Aw::EventType::getStructSeqInfoRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::EventType - ActiveWorks EventType Module.

=head1 SYNOPSIS

require Aw::EventType;

my $eventType = new Aw::EventType;


=head1 DESCRIPTION

Enhanced interface for the Aw.xs EventType methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
