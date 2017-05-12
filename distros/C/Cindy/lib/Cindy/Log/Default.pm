# $Id: Default.pm 120 2013-01-31 11:34:41Z jo $
# Cindy::Log - Logging for Cindy
#
# Copyright (c) 2008 Joachim Zobel <jz-2008@heute-morgen.de>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#


package Cindy::Log::Default;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT= qw(DEBUG INFO WARN ERROR FATAL); 

use Carp;

sub ERROR 
{
  croak @_;
}

sub WARN 
{
  carp @_;
}

sub INFO {}

sub DEBUG {}

1;

