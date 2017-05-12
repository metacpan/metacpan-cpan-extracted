package Aw::Log;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.2';
}


sub getMessage
{
my ( $self, $msgId ) = ( shift, shift );

	( ref( $_[0] ) eq "ARRAY" ) 
	  ? $self->_getMessage ( $msgId, $_[0] )
	  : $self->_getMessage ( $msgId, \@_ )
	;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::Log - ActiveWorks Log Module.

=head1 SYNOPSIS

require Aw::Log;

my $typeDef = new Aw::Log;


=head1 DESCRIPTION

Enhanced interface for the Aw.xs Log methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
