package Aspect::Library::Listenable::Event;

use strict;

our $VERSION = '1.04';

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

sub AUTOLOAD {
	my ($self, $value) = @_;
	my $key  = our $AUTOLOAD;
	return if $key =~ /DESTROY$/;
	$key =~ s/^.*:://;
	return @_ == 1
		? $self->{$key}
		: ( $self->{$key} = $value );
}

sub clone { 
	my $self  = shift;
	my $class = ref $self;
	my $clone = $class->new;
	while ( my ($key, $value) = each %$self ) {
		$clone->{$key} = $value;
	}
	return $clone;
}

sub as_string {
	my $self = shift;
	local $_;
	return join ', ', map { "$_:$self->{$_}" } sort keys %$self;
}

1;
