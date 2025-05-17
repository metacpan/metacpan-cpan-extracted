package Crop::Object::Simple;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Object::Simple
	Base class for objects have 'id' key only.
=cut

use v5.14;
use warnings;

use Crop::Error;
use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class attributes:

	id - single unique identificator
=cut
our %Attributes = (
	id => {key => 'ordinal'},
# 	id => {mode => 'read', key => 'ordinal'},
);

=begin nd
Method: _Create ( )
	Create new object.
	
	Generate, then set the 'id' attribute.
	
Returns:
	$self - if created
	undef - in case of error
=cut
sub _Create ( ) {
	my $self = shift;
	
	$self->{id} = $self->WH->create_auto_id($self);
	
	$self;
}

=begin nd
Method: Genkey ( )
	Generate primary key.
	
	Regeneration is prohibited.

	Use this method to get the exemplar ID before it stored.

Returns:
	id    - ok
	undef - error
=cut
sub Genkey {
	my $self = shift;
	my $class = ref $self;
	
	not defined $self->{id} or return warn "OBJECT|CRIT: Re-generation of existing key on '$class' exemplar";
	
	$self->WH->get_id($self);
}

=begin nd
Method: Get (@filter)
	Get an exemplar from warehouse that satisfy to clause described by @filter.
	
	Only one element there is in the @filter means 'id'.

Parameters:
	@filter - select clase

Returns:
	an exemplar - if ok
	false       - if an error has acquired
=cut
sub Get {
	my $either = shift;	

	my $self;
	
	if (@_ == 1 and ref $_[0] ne 'HASH') {
		return unless $_[0] =~ /^\d+$/;
		$self = $either->SUPER::Get(id => $_[0]);
	} else {
		$self = $either->SUPER::Get(@_);
	}

	$self;
}

=begin nd
Method: id ( )
	Get exemplar ID.

	The warehouse generates id if the exemplar does not exist.

Returns:
	id - an integer
=cut
sub id {
	my $self = shift;

	return $self->{id} // $self->Genkey;
}

=begin nd
Method: _Is_key_defined ( )
	If defined id?
	
Returns:
	true  - defined
	false - not defined
=cut
sub _Is_key_defined { defined +shift->{id} }

=begin nd
Method: Max ($attr)
	Get maximum of $attr value in all the class.

	If no $attr provided then 'id' is assumed.

	Method of class either method of exemplar.

Attributes:
	$attr - attribute name

Returns:
	Maximum value of $attr across all the class exemplars.
=cut
sub Max {
	my ($either, $attr) = @_;

	$attr //= 'id';

	$either::SUPER->Max($attr);
}

=begin nd
Method: _Prepare_key ( )
	Do nothing.

	Redefines <Crop::Object::_Prepare_key>.

	Always true. Database will generate Id for a Simple object.
=cut
sub _Prepare_key { 1 }

1;
