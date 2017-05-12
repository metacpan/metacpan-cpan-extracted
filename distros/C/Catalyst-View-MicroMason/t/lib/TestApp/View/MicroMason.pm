#!/usr/bin/perl
# MicroMason.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package TestApp::View::MicroMason;
use strict;
use base 'Catalyst::View::MicroMason';

__PACKAGE__->config(
    # -Filters      : to use |h and |u
    # -ExecuteCache : to cache template output
    # -CompileCache : to cache the templates
    Mixins => [qw( -Filters -CompileCache )], 
);
    
1;
