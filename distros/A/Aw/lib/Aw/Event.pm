package Aw::Event;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.3';

	use Aw;
}


sub new
{
my $self = undef;

	if ( @_ == 3 && ( ref($_[2]) eq "HASH" ) ) {
		my ( $class, $client, $hash ) = @_;
		if ( defined($hash->{_name}) && ($hash->{_name} =~ /\w+/) ) {
			$self = Aw::Event::_new ( $class, $client, $hash->{_name}, $hash );
		}
		else {
			croak("Event name is undefined. Can not create anonymous event.");
		}
	}
	elsif ( @_ == 3 || ( @_ == 4 && ref($_[3]) eq "HASH" ) ) {
		$self = Aw::Event::_new ( @_ );
	}
	elsif ( @_ >= 4 ) {
		# we are passed at least 4 elements, the 4th is not a ref
		my ( $class, $client, $event_type_name ) = ( shift, shift, shift );
		my %hash = @_;
		$self = Aw::Event::_new ( $class, $client, $event_type_name, \%hash );
	}
	else {
		croak("Usage: Aw::Event::new(self, client, [event_type_name], [hash_data])");
	}


	$self;
}



sub getEnvelope
{
	my $result = $_[0]->getField ( "_env" );
	(wantarray) ? %{$result} : $result ;
}



sub toHash
{
	my $result = Aw::Event::toHashRef ( @_ );
	(wantarray) ? %{$result} : $result ;
}



sub getFIELD
{
	my $result = {};

	$result->{type}  = Aw::Event::getFieldType (@_);
	$result->{value} = Aw::Event::getField (@_);

	( wantarray ) ? %{ $result } : $result ;
}



sub getFieldAndType
{
	Aw::Event::getFIELD ( @_ );
}



sub getField
{

	my $result = Aw::Event::getFieldRef ( @_ );

	if ( wantarray ) {
		if ( ref($result) eq "HASH" ) {
			return ( %{ $result } );
		}
		return ( @{ $result } );
	}

	$result;
}



sub update
{
my $block = shift;
my $struct;

	$block =~ s/^\{\n(.*?)\n(\s+)\} //sm;
	$struct = "$1";
	$struct =~ s/(\w+) (\w+)/   $2 => "$1"/g;
	$block =~ s/(\w+)\[\] => \{/$1 => \[/mg;
	$block =~ s/(\s+\{\n)(.*?)(\n\s+\})/$1$struct$3/smg;

	$block;
}



sub getClientId
{

	$_[0]->getStringField ( "_env.pubId" );
}



sub getStructFieldAsHash
{
	my $sfEvent = Aw::Event::getStructFieldAsEvent ( @_ );
	$sfEvent->toHash;
}



sub getFieldNames
{
	my $result = Aw::Event::getFieldNamesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getSequenceField
{
	my $result = Aw::Event::getSequenceFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getBooleanSeqField
{
	my $result = Aw::Event::getBooleanSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getByteSeqField
{
	my $result = Aw::Event::getByteSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getCharSeqField
{
	my $result = Aw::Event::getCharSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getDateSeqField
{
	my $result = Aw::Event::getDateSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getDoubleSeqField
{
	my $result = Aw::Event::getDoubleSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getFloatSeqField
{
	my $result = Aw::Event::getFloatSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getIntegerSeqField
{
	my $result = Aw::Event::getIntegerSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getLongSeqField
{
	my $result = Aw::Event::getLongSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getShortSeqField
{
	my $result = Aw::Event::getShortSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getStringSeqField
{
	my $result = Aw::Event::getStringSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getUCCharSeqField
{
	my $result = Aw::Event::getUCCharSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getUCStringSeqField
{
	my $result = Aw::Event::getUCStringSeqFieldRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getStructSeqFieldAsEvents
{
	my $result = Aw::Event::getStructSeqFieldAsEventsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getSubscriptionIds
{
	my $result = Aw::Event::getSubscriptionIdsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub setField
{
my ($self, $fieldName) = (shift, shift);


	return ( $self->init ( $fieldName ) )
		if ( ref($fieldName) eq "HASH" );     #  $fieldName was actually a Hash.


	my $ref = ref ( $_[0] );
	return $self->_setField ( $fieldName, $_[0] ) unless ( $ref || @_ > 1 );

	if ( $ref eq "ARRAY" ) {
		return $self->setSequenceField ( $fieldName, $_[0] );
	}
	elsif ( @_ > 1 ) {
		return $self->setSequenceField ( $fieldName, \@_ );
	}
	elsif ( $ref eq "HASH" ) {
		return $self->_setField ( $fieldName, $_[0] );
	}

}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::Event - ActiveWorks Event Module.

=head1 SYNOPSIS

require Aw::Event;

my $event = new Aw::Event;


=head1 DESCRIPTION

Enhanced interface for the Aw.xs Event methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
