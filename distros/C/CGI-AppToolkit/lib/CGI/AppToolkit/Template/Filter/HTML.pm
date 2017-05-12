package CGI::AppToolkit::Template::Filter::HTML;

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
	
	# from CGI.pm
    $text=~s/&/&amp;/g;
    $text=~s/\"/&quot;/g;
    $text=~s/>/&gt;/g;
    $text=~s/</&lt;/g;
    return $text;
}

1;
