#!/usr/local/bin/perl -wc

=head1 NAME

Datasource - Abstract base class for all the Reporter source data types

=head1 SYNOPSIS

use Data::Reporter::Datasource;

=head1 DESCRIPTION

This class helps to maintain control of the source data types in Data::Reporter.
The method 'getdata', should be defined in each source data type.

=cut

package Data::Reporter::Datasource;
use strict;
use Carp;

sub new(%) {
	my $class = shift;
	my $self={};
	bless $self, $class;
	$self;
}

sub getdata($) {
	my $self = shift;
	croak "Function getdata should be defined!!!";
}

sub close($) {
	my $self = shift;
	croak "Function close should be defined!!!";
}
1;
