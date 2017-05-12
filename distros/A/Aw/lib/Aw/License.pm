package Aw::License;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.2';
}


sub getFlags
{
	my $result = Aw::License::getFlagsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::License - ActiveWorks License Module.

=head1 SYNOPSIS

require Aw::License;

my $typeDef = new Aw::License;


=head1 DESCRIPTION

Enhanced interface for the Aw.xs License methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
