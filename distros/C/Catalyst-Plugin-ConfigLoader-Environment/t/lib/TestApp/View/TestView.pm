#!/usr/bin/perl
# TestView.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package TestApp::View::TestView;
use base 'Catalyst::View';

sub AUTOLOAD {
    our $AUTOLOAD =~ s{.*::}{};
    return $_[0]->{$AUTOLOAD};
}

1;
