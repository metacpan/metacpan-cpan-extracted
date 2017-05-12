package Chromosome::Map::Feature;

use strict;
use base qw( Chromosome::Map::Element );

use constant VALUE_TYPE		=> 'absolute';
use constant VALUE_DEFAULT 	=> 1;
use constant COLOR          => 'softblue';
use constant THRES_COLOR    => 'red';

our $VERSION = '0.01';

#-------------------------------------------------------------------------------
# public methods
#-------------------------------------------------------------------------------
# This object is designed to plot feature elements on chromosome (i.e gene,
# clusters, %GC, etc...)
#
# 	- absolute: to display, the value of all features in one pixel will be added
#	  i.e: number of gene, clusters location, etc...
#	- relative: to display, the mean of all the feature values will be computed
#	  i.e: %GC, PEARSON coeff - NOT IMPLEMENTED YET
# Note1: relative and absolute flag cannot be mixe within the same track
# Note2: name, group and type fields are not use in this object
#-------------------------------------------------------------------------------

sub new {
	my $class = shift;
	$class = ref($class) || $class;
	
	my %Options = @_;
	
	my $self = $class->SUPER::new (-name	=> $Options{-name},
								   -loc		=> $Options{-loc},
								   -color	=> $Options{-color},
								   );
	$self->{_color} = 'softblue' if (!defined $Options{-color});
	$self->{_thres_color} = $Options{-threscolor} || THRES_COLOR;
	$self->{_value}       = $Options{-value}      || VALUE_DEFAULT;
	$self->{_value_type}  = $Options{-valuetype}  || VALUE_TYPE;

	bless $self,$class;
	return $self;
}

sub get_feature_value {
	my ($self) = @_;
	return $self->{_value};
}

sub get_feature_value_type {
	my ($self) = @_;
	return $self->{_value_type};
}

sub get_feature_threshold_color {
	my ($self) = @_;
	return $self->{_thres_color};
}

1;