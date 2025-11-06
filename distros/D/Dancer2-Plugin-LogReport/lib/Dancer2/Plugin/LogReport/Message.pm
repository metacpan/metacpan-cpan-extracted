# This code is part of Perl distribution Dancer2-Plugin-LogReport version 2.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2015-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Dancer2::Plugin::LogReport::Message;{
our $VERSION = '2.01';
}

use base 'Log::Report::Message';

use strict;
use warnings;

use Log::Report   'dancer2-plugin-logreport';

#--------------------

sub reason
{	my $self = shift;
	$self->{reason} = $_[0] if exists $_[0];
	$self->{reason};
}

my %reason2color = (
	TRACE   => 'info',
	ASSERT  => 'info',
	INFO    => 'info',
	NOTICE  => 'info',
	WARNING => 'warning',
	MISTAKE => 'warning',
);


sub bootstrap_color
{	my $self = shift;
	return 'success' if $self->inClass('success');
	$reason2color{$self->reason} || 'danger';
}

1;
