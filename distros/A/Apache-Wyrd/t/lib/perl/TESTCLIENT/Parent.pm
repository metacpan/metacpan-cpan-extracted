#!/usr/bin/perl -w


package TESTCLIENT::Parent;
use strict;
use base qw(Apache::Wyrd);


sub _format_output {
	my ($self) = @_;
	$self->{variable_name} ||= 'template';
	$self->_data("variable: " . $self->{$self->{variable_name}});
}

sub set_var {
	my ($self, $var) = @_;
	$self->{variable_name} = $var->name;
	$self->{$var->name} = $var->value;
}

1;