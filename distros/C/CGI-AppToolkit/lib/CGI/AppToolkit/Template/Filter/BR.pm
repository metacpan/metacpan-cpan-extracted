package CGI::AppToolkit::Template::Filter::BR;

# Copyright 2002 Robert Giseburt. All rights reserved.
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# Email: rob@heavyhosting.net

$VERSION = '0.05';

require 5.004;
use Carp;
use base 'CGI::AppToolkit::Template::Filter';
use strict;

sub filter {
	my $self = shift;
	my $args = shift;
	my $text = shift;
	
	my $br = ref $args && @$args ? $args->[0] : '<br>';
	
	$text =~ s/(\r?\n)/$br\1/g;
	$text
}

1;