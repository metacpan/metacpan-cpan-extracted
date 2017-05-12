# Copyright (c) 2012, Broadcom Corporation. All rights reserved.
#
# This file is part of the DMTF::CIM module.

package DMTF::CIM::_valued;

use warnings;
use strict;

require DMTF::CIM::_model;

use version;
our $VERSION = qv('0.04');

our @ISA=qw(DMTF::CIM::_model);
use Carp;

# Module implementation here
sub new
{
	my $class=shift;
	my %args=@_;
	my $self=DMTF::CIM::_model::new($class,$args{parent},$args{data});
	$self->{VALUE}=$args{value} || {};
	return($self);
}

sub value
{
	my $self=shift;
	my @newvals=@_;
	if($#newvals > -1) {
		if($self->is_array) {
			my $new=[];
			foreach my $nv (@newvals) {
				push @$new, $self->unmap_value($nv);
			}
			${$self->{VALUE}}=$new;
		}
		else {
			if($#newvals > 0) {
				carp("Array specified for non-array value");
			}
			else {
				${$self->{VALUE}}=$self->unmap_value($newvals[0]);
			}
		}
	}
	return($self->_value(1));
}

sub raw_value
{
	my $self=shift;
	my @newvals=@_;
	if($#newvals > -1) {
		if($self->is_array) {
			${$self->{VALUE}}=\@newvals;
		}
		else {
			if($#newvals > 0) {
				carp("Array specified for non-array value");
			}
			else {
				${$self->{VALUE}}=$newvals[0];
			}
		}
	}
	return($self->_value(0));
}

#############
# "Private" #
#############

sub _value
{
	my $self=shift;
	my $map=shift;
	local $SIG{__WARN__}=sub {};
	my $val=${$self->{VALUE}};
	return $val unless defined $val;

	if(defined $map && $map) {
		if(ref($val) eq 'ARRAY') {
			$val=[@$val];
			foreach my $value (@{$val}) {
				my $newval=$self->map_value($value);
				$value=$newval;
			}
		}
		else {
			my $newval=$self->map_value($val);
			$val=$newval;
		}
	}

	if(ref($val) eq 'ARRAY') {
		return wantarray ? @{$val} : join(', ', @{$val});
	}
	return $val;
}

1;

