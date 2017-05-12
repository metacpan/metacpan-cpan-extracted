#!/usr/bin/perl
# TestApp.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

# fake catalyst app for testing

package TestApp;
use strict;
use warnings;
use Catalyst qw(LogWarnings);

__PACKAGE__->config(name => __PACKAGE__);
__PACKAGE__->setup;

1;
