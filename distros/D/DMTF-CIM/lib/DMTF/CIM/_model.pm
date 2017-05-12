# Copyright (c) 2012, Broadcom Corporation. All rights reserved.
#
# This file is part of the DMTF::CIM module.

package DMTF::CIM::_model;

use warnings;
use strict;

use version;
our $VERSION = qv('0.04');
use Carp;

# Module implementation here
sub new
{
	my $self={};
	$self->{CLASS}=shift;
	$self->{PARENT}=shift;
	$self->{DATA}=shift || {};
	bless($self, $self->{CLASS});
	return($self);
}

sub parent
{
	my $self=shift;
	return $self->{PARENT};
}

# Read-only
sub name
{
	my $self=shift;
	return $self->{DATA}{name};
}

# Read-only
sub qualifier
{
	my $self=shift;
	my $name=shift;

	if(!defined $name) {
		carp("No qualifier name specified");
		return;
	}

	return unless defined $self->{DATA}{qualifiers};
	return unless defined $self->{DATA}{qualifiers}{lc($name)};
	return $self->{DATA}{qualifiers}{lc($name)}{value};
}

# Read-only
sub is_array
{
	my $self=shift;

	if(defined $self->{DATA}{array}
			|| ref(${$self->{VALUE}}) eq 'ARRAY') {
		# Anything in here is true...
		return '0 but true' unless defined $self->{VALUE};
		return 1 unless ref(${$self->{VALUE}}) eq 'ARRAY';
		my $len=$#{${$self->{VALUE}}}+1;
		return '0 but true' unless $len > 0;
		return $len;
	}
	return 0;
}

# Read-only
sub is_ref
{
	my $self=shift;
	my $prop=shift;

	return 1 if defined $self->{DATA}{is_ref} && $self->{DATA}{is_ref} eq 'true';
	return 0;
}

# Read-only
sub type
{
	my $self=shift;
	my $ret;

	$ret=$self->{DATA}{type} if defined $self->{DATA}{type};
	$ret='string' unless defined $ret;
	$ret .= '[]' if $self->is_array;
	return $ret;
}

sub map_value
{
	my $self=shift;
	my $mapval=shift;

	if(!defined $mapval) {
		return;
	}
	if(ref($mapval) ne '') {
		carp("Reference $mapval passed where value expected");
		return;
	}

	if(defined $self->{DATA}{qualifiers}
			&& defined $self->{DATA}{qualifiers}{valuemap}
			&& defined $self->{DATA}{qualifiers}{valuemap}{value}
			&& $#{$self->{DATA}{qualifiers}{valuemap}{value}} > -1
			&& defined $self->{DATA}{qualifiers}{values}
			&& defined $self->{DATA}{qualifiers}{values}{value}
			&& $#{$self->{DATA}{qualifiers}{values}{value}} > -1) {
		my $default;
		my $valarr=$self->{DATA}{qualifiers}{valuemap}{value};
		my $value=$mapval;

		$value += 0;

		for(my $i=0; $i<=$#{$valarr}; $i++) {
			my $val=$valarr->[$i];

			if($val eq '..') {
				$default=\$self->{DATA}{qualifiers}{values}{value}[$i];
				next;
			}
			if($val =~ /([0-9]*)\.\.([0-9]*)/) {
				if((!defined $1 || $1 <= $value) && (!defined $2 || $2 >= $value)) {
					return $self->{DATA}{qualifiers}{values}{value}[$i];
				}
			}
			elsif($val == $value) {
				return $self->{DATA}{qualifiers}{values}{value}[$i];
			}
		}
		return $default;
	}
	else {
		return $mapval;
	}
}

sub unmap_value
{
	my $self=shift;
	my $value=shift;
	my $match=$value;
	my $i;
	return $value unless defined $self->{DATA}{qualifiers}{valuemap} && defined $self->{DATA}{qualifiers}{valuemap}{value};
	my $valarr=$self->{DATA}{qualifiers}{valuemap}{value};

	for($i=0; $i<=$#{$valarr}; $i++) {
		my $val=$valarr->[$i];

		if($val =~ /\.\./) {
			next;
		}
		elsif($self->{DATA}{qualifiers}{values}{value}[$i] eq $value) {
			return $valarr->[$i];
		}
		elsif(lc($self->{DATA}{qualifiers}{values}{value}[$i]) eq lc($value)) {
			$match=$valarr->[$i];
		}
	}
	return $match;
}

1; # Magic true value required at end of module
