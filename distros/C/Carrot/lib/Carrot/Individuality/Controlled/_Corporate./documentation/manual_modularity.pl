package Carrot::Individuality::Controlled::_Corporate;
my ($meta_monad) =  @_;

use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_MONADS() { 0 }
sub ATR_MONAD_CLASS() { 1 }

$meta_monad->provide(
	my $ordered_attributes = '::Modularity::Constant::Parental::Ordered_Attributes');
$ordered_attributes->set_local_inheritable(
	0, 1,
	[qw(ATR_MONADS ATR_MONAD_CLASS)]);

return(1);
