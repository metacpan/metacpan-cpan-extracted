#!/usr/bin/env perl
# Copyright (c) 2016 by Weigang Qui Lab

package Bio::BPWrapper;

our $VERSION = '1.04';
use strict; use warnings;

use constant PROGRAM => 'Bio::BPWrapper';

sub show_version() {
    PROGRAM . ", version $Bio::BPWrapper::VERSION";
}

unless (caller) {
    print show_version, "\n";
    print "Pssst... this is a module. Invoke via bioaln, bioseq, biopop, or biotree.\n"
}
1;
