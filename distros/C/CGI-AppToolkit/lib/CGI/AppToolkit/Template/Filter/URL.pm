package CGI::AppToolkit::Template::Filter::URL;

# Copyright 2002 Robert Giseburt. All rights reserved.
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# Email: rob@heavyhosting.net

$VERSION = '0.05';

require 5.004;
use Carp;
use base 'CGI::AppToolkit::Template::Filter';
use strict;

use vars qw(%URLESCAPE_MAP);

sub filter {
	my $self = shift;
	my $args = shift;
	my $toencode = shift;

	my $plus = ref $args && @$args ? $args->[0] : 0;

	# code from HTML::Template
	# -*snip*-
	# Build a char->hex map if one isn't already available
	unless (exists($URLESCAPE_MAP{chr(1)})) {
	  for (0..255) { $URLESCAPE_MAP{chr($_)} = sprintf('%%%02X', $_); }
	}
	# -*snip*-

	# added support for spaces -> '+' translation
	$URLESCAPE_MAP{' '} = $plus ? '+' : '%20';

	# back to code from HTML::Template
	# -*snip*-
	# do the translation (RFC 2396 ^uric)
	$toencode =~ s!([^a-zA-Z0-9_.\-])!$URLESCAPE_MAP{$1}!g;
	# -*snip*-
	
	$toencode
}

1;