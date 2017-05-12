#!/usr/bin/env perl
 
use Dancer;
use Catmandu;
use Dancer::Plugin::Catmandu::OAI;
 
Catmandu->load;
 
my $options = {};

# All records marked as deleted ...
$options->{deleted} = sub {
	my $item = shift;
	$item->{deleted};
};

# The setSpec of each record...
$options->{set_specs_for} = sub {
	my $item = shift;
	return $item->{setSpec} // [];
};

oai_provider '/oai' , %$options;
 
dance;
