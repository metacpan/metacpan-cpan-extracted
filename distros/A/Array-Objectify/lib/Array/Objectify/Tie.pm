package Array::Objectify::Tie;

use strict;
use warnings;
use Anonymous::Object;

our ($ANON, %OBJECTIFY);
BEGIN {
	$ANON = Anonymous::Object->new({
  	      object_name => 'Array::Objectify::Anonymous'
	});
	%OBJECTIFY = (
		HASH => 'hash_to_nested_object',
		ARRAY => 'array_to_nested_object',
	);
}

sub TIEARRAY {
	my ($class, @params) = @_;
	my $self = {
		array => [
			$class->_OBJECTIFY(@params)
		],
	};
	bless $self, $class;
}

sub CLEAR { 
	my $self = shift;
	$self->{array} = [];
}

sub STORESIZE {
	my $self = shift;
	return scalar @{$self->{array}};
}

sub STORE {
    	my ($self, $index, $value) = @_;
	($self->{array}->[$index]) = $self->_OBJECTIFY($value);
}

 
sub FETCHSIZE { 
	my $self = shift;
	return scalar @{$self->{array}};
}

sub FETCH { 
	my ($self, $index) = @_;
	$self->{array}->[$index];
}

sub PUSH {
	my $self = shift;
	push @{$self->{array}}, $self->_OBJECTIFY(@_);
}
 
sub POP {
	my $self = shift;
	pop @{$self->{array}};
}
 
sub SHIFT {
	my $self = shift;
	shift @{$self->{array}};
}
 
sub UNSHIFT {
	my $self = shift;
	unshift @{$self->{array}}, $self->_OBJECTIFY(@_);
}

sub _OBJECTIFY {
	my ($self, @params) = @_;
	map {
		my $method = $OBJECTIFY{ref($_)};
		$method ? $ANON->$method($_) : $_;
	} @params;
}

1;
