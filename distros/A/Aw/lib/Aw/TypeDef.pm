package Aw::TypeDef;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.2';
}


sub getFieldNames
{
	my $result = Aw::TypeDef::getFieldNamesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}


sub toHash
{
	my $result = Aw::TypeDef::toHashRef ( @_ );
	( wantarray ) ? %{ $result } : $result ;
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::TypeDef - ActiveWorks TypeDef Module.

=head1 SYNOPSIS

require Aw::TypeDef;

my $typeDef = new Aw::TypeDef;


=head1 DESCRIPTION

Enhanced interface for the Aw.xs TypeDef methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
