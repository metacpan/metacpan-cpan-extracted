package app_newstyle::V::a::view;

use strict;
use warnings;

use base("Apache::Voodoo::View");
use Data::Dumper;

sub init {
	my $self   = shift;
	my $config = shift;

	$self->content_type('text/plain');
	$self->{data} = {};
}

sub params {
	my $self = shift;

	if (defined($_[0])) {
		$self->{data} = shift;
	}
} 

sub exception {
	my $self = shift;
	my $e    = shift;

	$self->{data} = {
		"description" => ref($e),
		"message"     => "$e"
	};
}

sub output {
	my $self = shift;

	return Dumper $self->{data};
}

sub finish {
	my $self = shift;

	$self->{data} = {};
}

1;
