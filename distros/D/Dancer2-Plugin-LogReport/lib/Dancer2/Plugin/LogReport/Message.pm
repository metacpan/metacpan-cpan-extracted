# This code is part of Perl distribution Dancer2-Plugin-LogReport version 2.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2015-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


BEGIN { require Log::Report; }  # require very early, compilation order issue

package Dancer2::Plugin::LogReport::Message;{
our $VERSION = '2.03';
}

use base 'Log::Report::Message';

use strict;
use warnings;

use Log::Report   'dancer2-plugin-logreport';

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);
	$self->{reason} = $args->{reason};
	$self;
}

#----------------

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

sub bootstrapColor()
{	my $self = shift;
	$self->taggedWith('success') ? 'success' : ($reason2color{$self->reason} || 'danger');
}


{ no warnings;
  *bootstrap_color = \&bootstrapColor;
}

#-----------------

sub FREEZE($)
{	my ($self, $ser) = @_;
	$self->freeze(serializer => $ser);
}


sub THAW($@)
{	my ($class, $ser, $msg) = @_;
	$class->thaw($msg, serializer => $ser);
}

1;
